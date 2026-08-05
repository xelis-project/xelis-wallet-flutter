use super::*;

#[test]
fn signature_share_is_bound_to_signing_hash_and_signer_id() {
    let signer = KeyPair::new();
    let hash = Hash::new([9; 32]);
    let signature = signer.sign(hash.as_bytes());

    let share = create_multisig_signature_share(&hash, 3, signature).unwrap();
    let parsed = parse_multisig_signature_share(&share.encoded, &hash).unwrap();

    assert_eq!(share.signing_hash, hash.to_hex());
    assert_eq!(share.signer_id, 3);
    assert!(share.encoded.contains(&hash.to_hex()));
    assert_eq!(parsed.id, 3);
    assert_eq!(parsed.signature, share.signature);
}

#[test]
fn signature_share_v1_wire_fields_are_stable() {
    let signer = KeyPair::new();
    let signing_hash = Hash::new([9; 32]);
    let share =
        create_multisig_signature_share(&signing_hash, 3, signer.sign(signing_hash.as_bytes()))
            .unwrap();
    let encoded: serde_json::Value = serde_json::from_str(&share.encoded).unwrap();

    assert_eq!(encoded["version"], MULTISIG_SIGNATURE_SHARE_VERSION);
    assert_eq!(encoded["signing_hash"], signing_hash.to_hex());
    assert_eq!(encoded["signer_id"], 3);
    assert_eq!(encoded["signature"], share.signature);
    assert!(encoded.get("request_hash").is_none());
}

#[test]
fn signature_share_rejects_unknown_version() {
    let signer = KeyPair::new();
    let signing_hash = Hash::new([9; 32]);
    let share =
        create_multisig_signature_share(&signing_hash, 3, signer.sign(signing_hash.as_bytes()))
            .unwrap();
    let mut envelope: MultisigSignatureShareEnvelope =
        serde_json::from_str(&share.encoded).unwrap();
    envelope.version += 1;
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signature_share(&encoded, &signing_hash).unwrap_err();

    assert_eq!(
        error.to_string(),
        "Unsupported multisig signature share version"
    );
}

#[test]
fn request_to_signature_share_interoperates_on_the_signing_hash() {
    let (source, unsigned, transaction_type, _) = burn_request_fixture();
    let participant = KeyPair::new();
    let configuration = configuration(&[&participant], 1);
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let parsed_request =
        parse_multisig_signing_request(&request.encoded, Network::Testnet).unwrap();
    let share = create_multisig_signature_share(
        &parsed_request.signing_hash,
        0,
        participant.sign(parsed_request.signing_hash.as_bytes()),
    )
    .unwrap();
    let parsed_share =
        parse_multisig_signature_share(&share.encoded, &parsed_request.signing_hash).unwrap();

    let verified =
        verify_multisig_signature(&parsed_request.signing_hash, &configuration, &parsed_share)
            .unwrap();

    assert_eq!(verified.id, 0);
}

#[test]
fn signature_share_rejects_another_signing_hash() {
    let signer = KeyPair::new();
    let hash = Hash::new([9; 32]);
    let share = create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();

    let error = parse_multisig_signature_share(&share.encoded, &Hash::new([8; 32])).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The signature share belongs to another multisig request"
    );
}

#[test]
fn signature_share_rejects_oversized_input_before_parsing() {
    let encoded = "x".repeat(MAX_MULTISIG_SIGNATURE_SHARE_SIZE + 1);

    let error = parse_multisig_signature_share(&encoded, &Hash::new([9; 32])).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signature share is too large"
    );
}

#[test]
fn signature_share_rejects_non_canonical_encoding() {
    let signer = KeyPair::new();
    let hash = Hash::new([9; 32]);
    let share = create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();
    let encoded = share.encoded.replace(",\"", ", \"");

    let error = parse_multisig_signature_share(&encoded, &hash).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signature share encoding is not canonical"
    );
}

#[test]
fn signature_share_rejects_non_canonical_signature_encoding() {
    let signer = KeyPair::new();
    let hash = Hash::new([9; 32]);
    let share = create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();
    let mut envelope: MultisigSignatureShareEnvelope =
        serde_json::from_str(&share.encoded).unwrap();
    envelope.signature.push_str("00");
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signature_share(&encoded, &hash).unwrap_err();
    assert_eq!(
        error.to_string(),
        "The signature share encoding is not canonical"
    );
}
