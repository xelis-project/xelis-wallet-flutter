use super::*;

#[tokio::test]
async fn app_permission_updates_remain_atomic_under_the_async_lock() {
    let app = app_state();
    let updates = HashMap::from([
        ("get_balance".to_owned(), PermissionPolicy::Accept),
        ("unknown".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = modify_app_permissions(&app, &updates).await.unwrap_err();
    let permissions = app.get_permissions().lock().await;

    assert_eq!(error.to_string(), "XSWD permission not found");
    assert!(matches!(permissions["get_balance"], Permission::Ask));
    assert!(matches!(permissions["build_transaction"], Permission::Ask));
}

#[tokio::test]
async fn app_permission_updates_accept_unprefixed_method_names() {
    let app = app_state();

    modify_app_permissions(
        &app,
        &HashMap::from([("get_balance".to_owned(), PermissionPolicy::Accept)]),
    )
    .await
    .unwrap();
    modify_app_permissions(
        &app,
        &HashMap::from([("build_transaction".to_owned(), PermissionPolicy::Reject)]),
    )
    .await
    .unwrap();

    let permissions = app.get_permissions().lock().await;
    assert!(matches!(permissions["get_balance"], Permission::Allow));
    assert!(matches!(
        permissions["build_transaction"],
        Permission::Reject
    ));
}

#[tokio::test]
async fn app_permission_updates_reject_prefixed_names_atomically() {
    let app = app_state();
    let updates = HashMap::from([
        ("wallet.get_balance".to_owned(), PermissionPolicy::Accept),
        ("build_transaction".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = modify_app_permissions(&app, &updates).await.unwrap_err();
    let permissions = app.get_permissions().lock().await;

    assert_eq!(
        error.to_string(),
        "Prefixed XSWD permission names are unsupported"
    );
    assert!(matches!(permissions["get_balance"], Permission::Ask));
    assert!(matches!(permissions["build_transaction"], Permission::Ask));
}

#[tokio::test]
async fn app_info_preserves_identity_metadata_and_permission_policies() {
    let app = app_state();
    {
        let mut permissions = app.get_permissions().lock().await;
        permissions.insert("get_balance".to_owned(), Permission::Allow);
        permissions.insert("build_transaction".to_owned(), Permission::Reject);
    }

    let info = create_app_info(&app).await;

    assert_eq!(info.id, "app-id");
    assert_eq!(info.name, "Test app");
    assert_eq!(info.description, "Test description");
    assert_eq!(info.url.as_deref(), Some("https://example.com"));
    assert!(!info.is_relayer);
    assert!(matches!(
        info.permissions["get_balance"],
        PermissionPolicy::Accept
    ));
    assert!(matches!(
        info.permissions["build_transaction"],
        PermissionPolicy::Reject
    ));
}

#[tokio::test]
async fn handler_routes_every_event_once_and_returns_matching_responses() {
    let calls = Arc::new(Mutex::new(Vec::<(&'static str, XswdRequestSummary)>::new()));

    let cancel_calls = Arc::clone(&calls);
    let cancel = move |summary| -> DartFnFuture<()> {
        let calls = Arc::clone(&cancel_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("cancel", summary));
        })
    };

    let application_calls = Arc::clone(&calls);
    let application = move |summary| -> DartFnFuture<UserPermissionDecision> {
        let calls = Arc::clone(&application_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("application", summary));
            UserPermissionDecision::AlwaysAccept
        })
    };

    let permission_calls = Arc::clone(&calls);
    let permission = move |summary| -> DartFnFuture<UserPermissionDecision> {
        let calls = Arc::clone(&permission_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("permission", summary));
            UserPermissionDecision::Reject
        })
    };

    let prefetch_calls = Arc::clone(&calls);
    let prefetch = move |summary| -> DartFnFuture<UserPermissionDecision> {
        let calls = Arc::clone(&prefetch_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("prefetch", summary));
            UserPermissionDecision::Accept
        })
    };

    let disconnect_calls = Arc::clone(&calls);
    let disconnect = move |summary| -> DartFnFuture<()> {
        let calls = Arc::clone(&disconnect_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("disconnect", summary));
        })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (application_sender, application_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&app),
            application_sender,
        ))
        .unwrap();
    assert!(matches!(
        application_receiver.await.unwrap().unwrap(),
        PermissionResult::AlwaysAccept
    ));

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: Some(json!({"asset": "00"})),
            },
            permission_sender,
        ))
        .unwrap();
    assert!(matches!(
        permission_receiver.await.unwrap().unwrap(),
        PermissionResult::Reject
    ));

    let (prefetch_sender, prefetch_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::PrefetchPermissions(
            Arc::clone(&app),
            prefetch_permissions(),
            prefetch_sender,
        ))
        .unwrap();
    let prefetch_result = prefetch_receiver.await.unwrap().unwrap();
    assert_eq!(prefetch_result.len(), 2);
    assert!(prefetch_result
        .values()
        .all(|value| matches!(value, Permission::Allow)));

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(Arc::clone(&app), cancel_sender))
        .unwrap();
    cancel_receiver.await.unwrap().unwrap();

    sender.send(XSWDEvent::AppDisconnect(app)).unwrap();
    drop(sender);
    handler.await.unwrap();

    let calls = calls.lock().unwrap();
    assert_eq!(
        calls.iter().map(|(name, _)| *name).collect::<Vec<_>>(),
        vec![
            "application",
            "permission",
            "prefetch",
            "cancel",
            "disconnect"
        ]
    );
    assert!(calls
        .iter()
        .all(|(_, summary)| summary.application_info.id == "app-id"));

    let permission_summary = &calls[1].1;
    let permission_json: serde_json::Value =
        serde_json::from_str(&permission_summary.permission_json().unwrap()).unwrap();
    assert_eq!(permission_json["method"], "get_balance");

    let prefetch_summary = &calls[2].1;
    let prefetch_json: serde_json::Value =
        serde_json::from_str(&prefetch_summary.prefetch_permissions_json().unwrap()).unwrap();
    assert_eq!(prefetch_json["permissions"][0], "get_balance");
    assert_eq!(prefetch_json["permissions"][1], "get_assets");
}
