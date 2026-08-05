use super::*;

#[test]
fn pending_store_rejects_overwrite() {
    let mut store = PendingMultisigStore::default();
    store.insert(Hash::new([1; 32]), "first").unwrap();

    let error = store.insert(Hash::new([2; 32]), "second").unwrap_err();

    assert_eq!(
        error.to_string(),
        "another multisig request is already pending"
    );
    assert_eq!(store.signing_hash(), Some(&Hash::new([1; 32])));
}

#[test]
fn pending_store_keeps_request_after_signing_hash_mismatch() {
    let mut store = PendingMultisigStore::default();
    let pending_hash = Hash::new([1; 32]);
    let request_id = store.insert(pending_hash.clone(), "request").unwrap();

    let error = store
        .take_validated(request_id, &Hash::new([2; 32]), |_| Ok(()))
        .unwrap_err();

    assert_eq!(
        error.to_string(),
        "the multisig request does not match the pending transaction"
    );
    assert_eq!(store.signing_hash(), Some(&pending_hash));
}

#[test]
fn pending_store_keeps_request_after_validation_failure() {
    let mut store = PendingMultisigStore::default();
    let pending_hash = Hash::new([1; 32]);
    let request_id = store.insert(pending_hash.clone(), "request").unwrap();

    let error = store
        .take_validated::<()>(request_id, &pending_hash, |_| {
            anyhow::bail!("invalid request")
        })
        .unwrap_err();

    assert_eq!(error.to_string(), "invalid request");
    assert_eq!(store.signing_hash(), Some(&pending_hash));
}

#[test]
fn pending_store_cancels_only_matching_request() {
    let mut store = PendingMultisigStore::default();
    let pending_hash = Hash::new([1; 32]);
    let request_id = store.insert(pending_hash.clone(), "request").unwrap();

    assert!(store.cancel(request_id, &Hash::new([2; 32])).is_err());
    assert_eq!(store.signing_hash(), Some(&pending_hash));

    store.cancel(request_id, &pending_hash).unwrap();
    assert_eq!(store.signing_hash(), None);
}

#[test]
fn pending_store_rejects_replayed_generation_after_replacement() {
    let mut store = PendingMultisigStore::default();
    let signing_hash = Hash::new([1; 32]);
    let first_request_id = store.insert(signing_hash.clone(), "first").unwrap();
    store.cancel(first_request_id, &signing_hash).unwrap();
    let second_request_id = store.insert(signing_hash.clone(), "second").unwrap();

    assert_ne!(first_request_id, second_request_id);
    assert!(store.cancel(first_request_id, &signing_hash).is_err());
    assert_eq!(store.signing_hash(), Some(&signing_hash));
    store.cancel(second_request_id, &signing_hash).unwrap();
}

#[test]
fn rejected_signing_hash_does_not_consume_pending_request() {
    let signer = KeyPair::new();
    let pending_hash = Hash::new([7; 32]);
    let signed_hash = Hash::new([8; 32]);
    let configuration = multisig_configuration(&[&signer], 1);
    let signatures = vec![multisig_signature(0, &signer, &signed_hash)];
    let mut store = PendingMultisigStore::default();
    let request_id = store.insert(pending_hash.clone(), configuration).unwrap();

    let result = store.take_validated(request_id, &pending_hash, |configuration| {
        build_verified_multisig(&pending_hash, configuration, &signatures)
    });

    assert!(result.is_err());
    assert_eq!(store.signing_hash(), Some(&pending_hash));
}

#[test]
fn signature_inspection_does_not_consume_pending_request() {
    let first = KeyPair::new();
    let second = KeyPair::new();
    let hash = Hash::new([7; 32]);
    let configuration = multisig_configuration(&[&first, &second], 2);
    let signature = multisig_signature(1, &second, &hash);
    let mut store = PendingMultisigStore::default();
    let request_id = store.insert(hash.clone(), configuration).unwrap();

    let verified = store
        .validate(request_id, &hash, |configuration| {
            verify_multisig_signature(&hash, configuration, &signature)
        })
        .unwrap();

    assert_eq!(verified.id, 1);
    assert_eq!(store.signing_hash(), Some(&hash));
}
