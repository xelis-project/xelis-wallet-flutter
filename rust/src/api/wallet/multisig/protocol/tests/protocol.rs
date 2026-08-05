use super::*;

#[test]
fn multisig_v1_protocol_constants_are_stable() {
    assert_eq!(MULTISIG_SIGNING_REQUEST_VERSION, 1);
    assert_eq!(MULTISIG_SIGNATURE_SHARE_VERSION, 1);
    assert_eq!(
        MULTISIG_SIGNING_REQUEST_DOMAIN,
        b"xelis:wallet:multisig-signing-request:v1\0"
    );
}

#[test]
fn multisig_v1_signing_bytes_are_stable() {
    let payload = MultisigSigningRequestPayload {
        version: MULTISIG_SIGNING_REQUEST_VERSION,
        network: Network::Testnet,
        unsigned_transaction: "00".to_owned(),
        transaction: MultisigSigningRequestTransaction::DeleteMultisig,
    };

    let signing_bytes = multisig_request_signing_bytes(&payload).unwrap();

    assert_eq!(
        signing_bytes,
        b"xelis:wallet:multisig-signing-request:v1\0{\"version\":1,\"network\":\"testnet\",\"unsigned_transaction\":\"00\",\"transaction\":{\"type\":\"delete_multisig\"}}"
    );
}

#[test]
fn multisig_setup_rejects_invalid_threshold_and_participant_count() {
    assert!(validate_multisig_setup(0, 1).is_err());
    assert!(validate_multisig_setup(2, 1).is_err());
    assert!(validate_multisig_setup(1, 0).is_err());
    assert!(validate_multisig_setup(1, 256).is_err());
    assert!(validate_multisig_setup(2, 3).is_ok());
}

#[test]
fn verified_multisig_accepts_exact_valid_threshold() {
    let first = KeyPair::new();
    let second = KeyPair::new();
    let hash = Hash::new([7; 32]);
    let configuration = configuration(&[&first, &second], 2);
    let signatures = vec![signature(0, &first, &hash), signature(1, &second, &hash)];

    let multisig = build_verified_multisig(&hash, &configuration, &signatures).unwrap();

    assert_eq!(multisig.len(), 2);
}

#[test]
fn verified_multisig_rejects_duplicate_participant() {
    let first = KeyPair::new();
    let second = KeyPair::new();
    let hash = Hash::new([7; 32]);
    let configuration = configuration(&[&first, &second], 2);
    let signatures = vec![signature(0, &first, &hash), signature(0, &first, &hash)];

    assert!(build_verified_multisig(&hash, &configuration, &signatures).is_err());
}

#[test]
fn verified_multisig_rejects_wrong_participant_key() {
    let expected = KeyPair::new();
    let wrong = KeyPair::new();
    let hash = Hash::new([7; 32]);
    let configuration = configuration(&[&expected], 1);
    let signatures = vec![signature(0, &wrong, &hash)];

    assert!(build_verified_multisig(&hash, &configuration, &signatures).is_err());
}

#[test]
fn verified_multisig_rejects_invalid_participant_id() {
    let signer = KeyPair::new();
    let hash = Hash::new([7; 32]);
    let configuration = configuration(&[&signer], 1);
    let signatures = vec![signature(1, &signer, &hash)];
    assert!(build_verified_multisig(&hash, &configuration, &signatures).is_err());
}

#[test]
fn individual_signature_validation_rejects_claimed_wrong_participant() {
    let expected = KeyPair::new();
    let actual = KeyPair::new();
    let hash = Hash::new([7; 32]);
    let configuration = configuration(&[&expected, &actual], 2);
    let signature = signature(0, &actual, &hash);

    let error = verify_multisig_signature(&hash, &configuration, &signature).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signature is invalid for this transaction"
    );
}
