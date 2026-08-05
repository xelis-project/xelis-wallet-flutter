use super::*;

#[test]
fn authorized_signing_binds_participant_id_and_signature_to_signing_hash() {
    let signer = KeyPair::new();
    let signing_hash = Hash::new([7; 32]);

    let share = create_authorized_multisig_signature_share(&signing_hash, Some(3), |data| {
        signer.sign(data)
    })
    .unwrap();

    assert_eq!(share.signing_hash, signing_hash.to_hex());
    assert_eq!(share.signer_id, 3);
    let signature = Signature::from_hex(&share.signature).unwrap();
    assert!(signature.verify(signing_hash.as_bytes(), signer.get_public_key()));
}

#[test]
fn unauthorized_wallet_is_rejected_before_any_signature_is_created() {
    let sign_called = Cell::new(false);

    let error = create_authorized_multisig_signature_share(&Hash::new([8; 32]), None, |_| {
        sign_called.set(true);
        KeyPair::new().sign(&[8; 32])
    })
    .unwrap_err();

    assert_eq!(
        error.to_string(),
        "The opened wallet is not an authorized participant for this multisig request"
    );
    assert!(!sign_called.get());
}
