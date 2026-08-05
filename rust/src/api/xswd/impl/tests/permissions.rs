use super::*;

#[test]
fn permission_decisions_map_to_the_exact_core_result() {
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::Accept),
        PermissionResult::Accept
    ));
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::Reject),
        PermissionResult::Reject
    ));
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::AlwaysAccept),
        PermissionResult::AlwaysAccept
    ));
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::AlwaysReject),
        PermissionResult::AlwaysReject
    ));
}

#[test]
fn prefetch_acceptance_allows_every_requested_permission_in_order() {
    for decision in [
        UserPermissionDecision::Accept,
        UserPermissionDecision::AlwaysAccept,
    ] {
        let result = prefetch_permissions_from_decision(decision, prefetch_permissions());
        let entries = result
            .iter()
            .map(|(permission, policy)| (permission.as_str(), policy.to_string()))
            .collect::<Vec<_>>();

        assert_eq!(
            entries,
            vec![
                ("get_balance", "allow".to_owned()),
                ("get_assets", "allow".to_owned()),
            ]
        );
    }
}

#[test]
fn prefetch_rejection_returns_no_permission() {
    for decision in [
        UserPermissionDecision::Reject,
        UserPermissionDecision::AlwaysReject,
    ] {
        assert!(prefetch_permissions_from_decision(decision, prefetch_permissions()).is_empty());
    }
}

#[test]
fn encryption_keys_require_exactly_32_bytes_without_truncation() {
    for length in [0, 31, 33] {
        let error = encryption_key(vec![7; length]).unwrap_err();
        assert_eq!(
            error.to_string(),
            format!("Invalid XSWD relayer encryption key length: expected 32 bytes, got {length}")
        );
    }

    assert_eq!(encryption_key(vec![7; 32]).unwrap(), [7; 32]);
}

#[test]
fn encryption_modes_preserve_the_exact_valid_key() {
    assert!(convert_encryption_mode(None).unwrap().is_none());

    let aes = convert_encryption_mode(Some(EncryptionMode::Aes { key: vec![1; 32] }))
        .unwrap()
        .unwrap();
    assert!(matches!(aes, CoreEncryptionMode::AES { key } if key == [1; 32]));

    let chacha =
        convert_encryption_mode(Some(EncryptionMode::Chacha20Poly1305 { key: vec![2; 32] }))
            .unwrap()
            .unwrap();
    assert!(matches!(chacha, CoreEncryptionMode::Chacha20Poly1305 { key } if key == [2; 32]));
}

#[test]
fn permission_updates_are_atomic_when_any_permission_is_unknown() {
    let mut current = IndexMap::from([
        ("get_balance".to_owned(), Permission::Ask),
        ("build_transaction".to_owned(), Permission::Reject),
    ]);
    let updates = HashMap::from([
        ("get_balance".to_owned(), PermissionPolicy::Accept),
        ("unknown".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = apply_permission_updates(&mut current, &updates).unwrap_err();

    assert_eq!(error.to_string(), "XSWD permission not found");
    assert!(matches!(current["get_balance"], Permission::Ask));
    assert!(matches!(current["build_transaction"], Permission::Reject));
}

#[test]
fn permission_updates_apply_every_supported_policy() {
    let mut current = IndexMap::from([
        ("allow".to_owned(), Permission::Ask),
        ("reject".to_owned(), Permission::Ask),
        ("ask".to_owned(), Permission::Allow),
    ]);
    let updates = HashMap::from([
        ("allow".to_owned(), PermissionPolicy::Accept),
        ("reject".to_owned(), PermissionPolicy::Reject),
        ("ask".to_owned(), PermissionPolicy::Ask),
    ]);

    apply_permission_updates(&mut current, &updates).unwrap();

    assert!(matches!(current["allow"], Permission::Allow));
    assert!(matches!(current["reject"], Permission::Reject));
    assert!(matches!(current["ask"], Permission::Ask));
}
