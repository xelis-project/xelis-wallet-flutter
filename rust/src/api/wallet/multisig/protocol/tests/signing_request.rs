use super::*;

const FOREIGN_SIGNING_REQUEST_DOMAIN: &[u8] = b"foreign:multisig-signing-request:v1\0";

#[test]
fn signing_request_round_trip_recomputes_signing_hash_and_verified_burn_preview() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();

    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let parsed = parse_multisig_signing_request(&request.encoded, Network::Testnet).unwrap();

    assert_eq!(
        request.signing_hash,
        unsigned.get_hash_for_multisig().to_hex()
    );
    assert_eq!(parsed.signing_hash, unsigned.get_hash_for_multisig());
    assert_eq!(parsed.reference_topoheight, 42);
    assert!(matches!(
        request.transaction,
        NativeMultisigSigningTransaction::Burn {
            asset,
            amount
        } if asset == XELIS_ASSET.to_hex() && amount == 10 * COIN_VALUE
    ));
}

#[test]
fn signing_request_round_trip_verifies_confidential_transfer_amounts() {
    let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();

    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let parsed = parse_multisig_signing_request(&request.encoded, Network::Testnet).unwrap();

    assert_eq!(parsed.signing_hash, unsigned.get_hash_for_multisig());
    assert!(matches!(
        request.transaction,
        NativeMultisigSigningTransaction::Transfers { transfers }
            if transfers.len() == 2
                && transfers[0].amount == 10 * COIN_VALUE
                && transfers[1].amount == 20 * COIN_VALUE
    ));
}

#[test]
fn signing_request_rejects_transfer_amount_changed_after_proof() {
    let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let MultisigSigningRequestTransaction::Transfers { transfers } =
        &mut envelope.payload.transaction
    else {
        panic!("expected transfer request");
    };
    transfers[0].amount += 1;
    envelope.source_signature = source
        .keypair
        .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
        .to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
    assert_eq!(
        error.to_string(),
        "The transfer amount does not match its proof"
    );
}

#[test]
fn signing_request_rejects_reordered_transfer_amount_proofs() {
    let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let MultisigSigningRequestTransaction::Transfers { transfers } =
        &mut envelope.payload.transaction
    else {
        panic!("expected transfer request");
    };
    let first_proof = transfers[0].amount_proof.clone();
    transfers[0].amount_proof = transfers[1].amount_proof.clone();
    transfers[1].amount_proof = first_proof;
    envelope.source_signature = source
        .keypair
        .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
        .to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    assert!(parse_multisig_signing_request(&encoded, Network::Testnet).is_err());
}

#[test]
fn signing_request_rejects_proof_for_another_ciphertext() {
    let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let MultisigSigningRequestTransaction::Transfers { transfers } =
        &mut envelope.payload.transaction
    else {
        panic!("expected transfer request");
    };
    let amount = transfers[0].amount;
    let unrelated_ciphertext = source.keypair.get_public_key().encrypt(amount);
    transfers[0].amount_proof =
        BalanceProof::new(&source.keypair, amount, unrelated_ciphertext).to_hex();
    envelope.source_signature = source
        .keypair
        .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
        .to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
    assert!(error
        .to_string()
        .contains("does not match the unsigned transaction"));
}

#[test]
fn signing_request_rejects_non_canonical_amount_proof() {
    let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let MultisigSigningRequestTransaction::Transfers { transfers } =
        &mut envelope.payload.transaction
    else {
        panic!("expected transfer request");
    };
    transfers[0].amount_proof.push_str("00");
    envelope.source_signature = source
        .keypair
        .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
        .to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
    assert_eq!(
        error.to_string(),
        "The transfer amount proof encoding is not canonical"
    );
}

#[test]
fn signing_request_rejects_wrong_network() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();

    let error = parse_multisig_signing_request(&request.encoded, Network::Mainnet).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signing request belongs to another network"
    );
}

#[test]
fn signing_request_rejects_unknown_version() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    envelope.payload.version += 1;
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();

    assert_eq!(
        error.to_string(),
        "Unsupported multisig signing request version"
    );
}

#[test]
fn signing_request_rejects_a_foreign_domain() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let payload = serde_json::to_vec(&envelope.payload).unwrap();
    let mut foreign_signing_bytes =
        Vec::with_capacity(FOREIGN_SIGNING_REQUEST_DOMAIN.len() + payload.len());
    foreign_signing_bytes.extend_from_slice(FOREIGN_SIGNING_REQUEST_DOMAIN);
    foreign_signing_bytes.extend_from_slice(&payload);
    envelope.source_signature = source.keypair.sign(&foreign_signing_bytes).to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signing request attestation is invalid"
    );
}

#[test]
fn signing_request_rejects_oversized_input_before_parsing() {
    let encoded = "x".repeat(MAX_MULTISIG_SIGNING_REQUEST_SIZE + 1);

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signing request is too large"
    );
}

#[test]
fn signing_request_rejects_non_canonical_unsigned_bytes() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    envelope.payload.unsigned_transaction.push_str("00");
    envelope.source_signature = source
        .keypair
        .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
        .to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    assert!(parse_multisig_signing_request(&encoded, Network::Testnet).is_err());
}

#[test]
fn signing_request_rejects_source_attested_public_detail_mismatch() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let MultisigSigningRequestTransaction::Burn { amount, .. } = &mut envelope.payload.transaction
    else {
        panic!("expected burn request");
    };
    *amount += 1;
    envelope.source_signature = source
        .keypair
        .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
        .to_hex();
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
    assert_eq!(
        error.to_string(),
        "The burn details do not match the unsigned transaction"
    );
}

#[test]
fn signing_request_rejects_tampered_attestation() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    let MultisigSigningRequestTransaction::Burn { amount, .. } = &mut envelope.payload.transaction
    else {
        panic!("expected burn request");
    };
    *amount += 1;
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
    assert_eq!(
        error.to_string(),
        "The multisig signing request attestation is invalid"
    );
}

#[test]
fn signing_request_rejects_non_canonical_attestation_encoding() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let mut envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(&request.encoded).unwrap();
    envelope.source_signature.push_str("00");
    let encoded = serde_json::to_string(&envelope).unwrap();

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
    assert_eq!(
        error.to_string(),
        "The multisig signing request attestation encoding is not canonical"
    );
}

#[test]
fn signing_request_rejects_non_canonical_envelope_encoding() {
    let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
    let request = create_multisig_signing_request(
        &unsigned,
        &transaction_type,
        &configuration,
        Network::Testnet,
        &source.keypair,
    )
    .unwrap();
    let encoded = request.encoded.replace(",\"", ", \"");

    let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The multisig signing request encoding is not canonical"
    );
}
