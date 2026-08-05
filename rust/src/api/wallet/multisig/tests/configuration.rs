use super::*;

#[test]
fn active_configuration_preserves_participant_ids_and_detects_opened_wallet() {
    let first = KeyPair::new();
    let opened_wallet = KeyPair::new();
    let third = KeyPair::new();
    let participants = vec![
        first.get_public_key().to_address(false),
        opened_wallet.get_public_key().to_address(false),
        third.get_public_key().to_address(false),
    ];

    let resolved = resolve_active_multisig_configuration(
        MultisigState::Active {
            participants: participants.clone(),
            threshold: 2,
        },
        &opened_wallet.get_public_key().compress(),
    )
    .unwrap();

    assert_eq!(resolved.threshold, 2);
    assert_eq!(resolved.signer_id, Some(1));
    assert_eq!(resolved.participants.len(), participants.len());
    for (id, (actual, expected)) in resolved
        .participants
        .iter()
        .zip(participants.iter())
        .enumerate()
    {
        assert_eq!(actual.id, id as u8);
        assert_eq!(actual.address, expected.to_string());
    }
}

#[test]
fn active_configuration_does_not_assign_signer_id_to_non_participant() {
    let opened_wallet = KeyPair::new();
    let participant = KeyPair::new();

    let resolved = resolve_active_multisig_configuration(
        MultisigState::Active {
            participants: vec![participant.get_public_key().to_address(false)],
            threshold: 1,
        },
        &opened_wallet.get_public_key().compress(),
    )
    .unwrap();

    assert_eq!(resolved.signer_id, None);
}

#[test]
fn active_configuration_rejects_deleted_state() {
    let opened_wallet = KeyPair::new();
    let wallet_public_key = opened_wallet.get_public_key().compress();

    let error = resolve_active_multisig_configuration(MultisigState::Deleted, &wallet_public_key)
        .unwrap_err();
    assert_eq!(
        error.to_string(),
        "The multisig configuration was not active for this request"
    );
}

#[test]
fn active_configuration_rejects_threshold_above_participant_count() {
    let opened_wallet = KeyPair::new();
    let wallet_public_key = opened_wallet.get_public_key().compress();

    let participant = KeyPair::new().get_public_key().to_address(false);
    let error = resolve_active_multisig_configuration(
        MultisigState::Active {
            participants: vec![participant],
            threshold: 2,
        },
        &wallet_public_key,
    )
    .unwrap_err();
    assert_eq!(error.to_string(), "Invalid multisig threshold");
}

#[test]
fn signing_configuration_fetches_daemon_state_for_request_source() {
    let source = KeyPair::new().get_public_key().to_address(false);
    let opened_wallet = KeyPair::new();
    let participant = opened_wallet.get_public_key().to_address(false);
    let fetch_called = Cell::new(false);

    let resolved = block_on(resolve_multisig_signing_configuration_with(
        &source.to_string(),
        &opened_wallet.get_public_key().compress(),
        |requested_source| {
            fetch_called.set(true);
            assert_eq!(requested_source, source);
            ready(Ok::<_, anyhow::Error>(MultisigState::Active {
                participants: vec![participant],
                threshold: 1,
            }))
        },
    ))
    .unwrap();

    assert!(fetch_called.get());
    assert_eq!(resolved.signer_id, Some(0));
}

#[test]
fn invalid_request_source_is_rejected_before_fetching_daemon_state() {
    let opened_wallet = KeyPair::new();
    let fetch_called = Cell::new(false);

    let error = block_on(resolve_multisig_signing_configuration_with(
        "invalid-address",
        &opened_wallet.get_public_key().compress(),
        |_| {
            fetch_called.set(true);
            ready(Ok::<_, anyhow::Error>(MultisigState::Deleted))
        },
    ))
    .unwrap_err();

    assert_eq!(error.to_string(), "Invalid multisig signing request source");
    assert!(!fetch_called.get());
}

#[test]
fn signing_configuration_propagates_daemon_fetch_error() {
    let source = KeyPair::new().get_public_key().to_address(false);
    let opened_wallet = KeyPair::new();

    let error = block_on(resolve_multisig_signing_configuration_with(
        &source.to_string(),
        &opened_wallet.get_public_key().compress(),
        |_| ready(Err(anyhow::anyhow!("daemon unavailable"))),
    ))
    .unwrap_err();

    assert_eq!(error.to_string(), "daemon unavailable");
}
