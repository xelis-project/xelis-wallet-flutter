use super::*;

#[test]
fn session_references_are_stable_exact_and_process_unique() {
    let app = app_state_with_id("shared-id");
    let same_app = Arc::clone(&app);
    let colliding_app = app_state_with_id("shared-id");
    let mut first_wallet = XswdSessionRegistry::default();
    let mut second_wallet = XswdSessionRegistry::default();

    let first = first_wallet.register(&app).unwrap();
    let reread = first_wallet.register(&same_app).unwrap();
    let collision = first_wallet.register(&colliding_app).unwrap();
    let cross_wallet = second_wallet.register(&app).unwrap();

    assert_eq!(first, reread);
    assert_ne!(first, collision);
    assert_ne!(first, cross_wallet);
    assert!(Arc::ptr_eq(&first_wallet.resolve(first).unwrap(), &app));
    assert!(second_wallet.resolve(first).is_none());
}

#[test]
fn session_registry_purges_dead_entries_and_tombstones_invalidated_states() {
    let mut registry = XswdSessionRegistry::default();
    let session_ref = {
        let app = app_state();
        registry.register(&app).unwrap()
    };

    assert!(registry.resolve(session_ref).is_none());
    assert!(registry.sessions.is_empty());

    let app = app_state();
    let active_ref = registry.register(&app).unwrap();
    registry.invalidate_state(&app);
    assert!(registry.resolve(active_ref).is_none());
    assert_eq!(registry.project(&app).unwrap(), active_ref);
    assert_eq!(
        registry.register(&app).unwrap_err().to_string(),
        XSWD_SESSION_REFERENCE_INVALID
    );

    registry.clear();
    assert_eq!(
        registry.register(&app).unwrap_err().to_string(),
        XSWD_SESSION_REFERENCE_INVALID
    );
}

#[test]
fn invalidating_an_unseen_state_projects_only_an_informational_tombstone() {
    let app = app_state();
    let mut registry = XswdSessionRegistry::default();

    registry.invalidate_state(&app);
    let session_ref = registry.project(&app).unwrap();

    assert!(registry.resolve(session_ref).is_none());
    assert_eq!(
        registry.register(&app).unwrap_err().to_string(),
        XSWD_SESSION_REFERENCE_INVALID
    );
}
