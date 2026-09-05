use super::*;
use std::{
    collections::VecDeque,
    sync::{
        atomic::{AtomicUsize, Ordering},
        RwLock,
    },
    time::Duration,
};

#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
use futures::{SinkExt, StreamExt};
#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
use tokio_tungstenite::{
    accept_async, connect_async,
    tungstenite::{client::IntoClientRequest, Message},
    MaybeTlsStream, WebSocketStream,
};
#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
use xelis_common::{
    crypto::ecdlp::ECDLPTables,
    network::Network,
    tokio::net::{TcpListener, TcpStream},
};
#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
use xelis_wallet::{precomputed_tables::PrecomputedTablesShared, wallet::RecoverOption};

#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
async fn connect_local_xswd() -> WebSocketStream<MaybeTlsStream<TcpStream>> {
    let request = "ws://127.0.0.1:44325/xswd".into_client_request().unwrap();
    for _ in 0..50 {
        if let Ok((socket, _)) = connect_async(request.clone()).await {
            return socket;
        }
        xelis_common::tokio::time::sleep(Duration::from_millis(20)).await;
    }
    panic!("local XSWD server did not become reachable");
}

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

    let registry = xelis_common::tokio::sync::Mutex::new(XswdSessionRegistry::default());
    let info = create_app_info(&registry, &app, false).await.unwrap();

    assert_eq!(info.id, "app-id");
    assert_eq!(info.name, "Test app");
    assert_eq!(info.description, "Test description");
    assert_eq!(info.url.as_deref(), Some("https://example.com"));
    assert!(!info.is_relayer);
    assert_ne!(info.session_ref, 0);
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
async fn session_references_are_stable_exact_and_process_unique() {
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

#[tokio::test]
async fn closing_one_handler_does_not_invalidate_another_handlers_session() {
    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let first_app = app_state_with_id("first-handler");
    let second_app = app_state_with_id("second-handler");
    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let (second_sender, second_receiver) = mpsc::unbounded_channel();
    let second_handler = tokio::spawn(xswd_handler_with_registry(
        second_receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let (second_response_sender, second_response_receiver) = oneshot::channel();
    second_sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&second_app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            second_response_sender,
        ))
        .unwrap();
    assert!(matches!(
        second_response_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    let second_ref = registry.lock().await.register(&second_app).unwrap();

    let (first_started_sender, first_started_receiver) = oneshot::channel();
    let first_started_sender = Arc::new(Mutex::new(Some(first_started_sender)));
    let callback_started = Arc::clone(&first_started_sender);
    let (first_sender, first_receiver) = mpsc::unbounded_channel();
    let first_handler = tokio::spawn(xswd_handler_with_registry(
        first_receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        |_, _| Box::pin(async { XswdNotificationCallbackOutcome::Completed }),
        |_| Box::pin(async { XswdDecisionCallbackOutcome::Accept }),
        move |_| {
            callback_started
                .lock()
                .unwrap()
                .take()
                .unwrap()
                .send(())
                .unwrap();
            Box::pin(std::future::pending())
        },
        |_| Box::pin(async { XswdDecisionCallbackOutcome::Reject }),
        |_| Box::pin(async { XswdNotificationCallbackOutcome::Completed }),
    ));
    let (first_response_sender, first_response_receiver) = oneshot::channel();
    first_sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&first_app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            first_response_sender,
        ))
        .unwrap();
    first_started_receiver.await.unwrap();
    let first_ref = registry.lock().await.register(&first_app).unwrap();

    drop(first_sender);
    first_handler.await.unwrap();
    assert_eq!(
        first_response_receiver
            .await
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_HANDLER_CLOSED
    );
    {
        let mut registry = registry.lock().await;
        assert!(registry.resolve(first_ref).is_none());
        assert!(Arc::ptr_eq(
            &registry.resolve(second_ref).unwrap(),
            &second_app
        ));
    }

    drop(second_sender);
    second_handler.await.unwrap();
    assert!(registry.lock().await.resolve(second_ref).is_none());
}

#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
#[tokio::test]
#[ignore = "uses production Argon2 parameters and a fixed local XSWD port"]
async fn real_local_close_emits_cancel_and_disconnect_before_cleanup() {
    let directory = tempfile::tempdir().unwrap();
    let wallet_path = directory.path().join("wallet");
    let tables: PrecomputedTablesShared = Arc::new(RwLock::new(ECDLPTables::empty(1)));
    let wallet = xelis_wallet::wallet::Wallet::create(
        wallet_path.to_string_lossy().as_ref(),
        "xswd-close-test-password",
        RecoverOption::None,
        Network::Devnet,
        tables,
        1,
        1,
    )
    .await
    .unwrap();
    let wrapper = XelisWallet::from_test_wallet(wallet);

    let cancel_calls = Arc::new(AtomicUsize::new(0));
    let recorded_cancel_calls = Arc::clone(&cancel_calls);
    let (application_sender, application_receiver) = oneshot::channel();
    let application_sender = Arc::new(Mutex::new(Some(application_sender)));
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (disconnect_sender, disconnect_receiver) = oneshot::channel();
    let disconnect_sender = Arc::new(Mutex::new(Some(disconnect_sender)));

    let cancel = move |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_cancel_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let projected_application = Arc::clone(&application_sender);
    let application = move |summary| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        projected_application
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(summary)
            .unwrap();
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission_started = Arc::clone(&permission_started_sender);
    let pending_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        permission_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = pending_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let projected_disconnect = Arc::clone(&disconnect_sender);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        projected_disconnect
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    wrapper
        .start_xswd(
            NativeXswdProjectionLimits::default(),
            cancel,
            application,
            permission,
            prefetch,
            disconnect,
        )
        .await
        .unwrap();
    let mut socket = connect_local_xswd().await;
    socket
        .send(Message::Text(
            json!({
                "id": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "name": "Local close test",
                "description": "",
                "permissions": ["get_balance"]
            })
            .to_string()
            .into(),
        ))
        .await
        .unwrap();
    let application_summary =
        xelis_common::tokio::time::timeout(Duration::from_secs(2), application_receiver)
            .await
            .unwrap()
            .unwrap();
    let _ = socket.next().await.unwrap().unwrap();

    socket
        .send(Message::Text(
            json!({
                "jsonrpc": "2.0",
                "id": 1,
                "method": "get_balance",
                "params": {"asset": null}
            })
            .to_string()
            .into(),
        ))
        .await
        .unwrap();
    permission_started_receiver.await.unwrap();

    wrapper
        .close_application_session(application_summary.application_info.session_ref)
        .await
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(2), disconnect_receiver)
        .await
        .unwrap()
        .unwrap();
    assert_eq!(cancel_calls.load(Ordering::SeqCst), 1);
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::AlwaysAccept)
        .is_err());
    assert!(wrapper.xswd_sessions().lock().await.sessions.is_empty());

    wrapper.stop_xswd().await.unwrap();
}

#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
#[tokio::test]
#[ignore = "uses production Argon2 parameters"]
async fn real_relayer_close_stops_transport_while_disconnect_callback_is_pending() {
    let directory = tempfile::tempdir().unwrap();
    let wallet_path = directory.path().join("wallet");
    let tables: PrecomputedTablesShared = Arc::new(RwLock::new(ECDLPTables::empty(1)));
    let wallet = xelis_wallet::wallet::Wallet::create(
        wallet_path.to_string_lossy().as_ref(),
        "xswd-relayer-close-test-password",
        RecoverOption::None,
        Network::Devnet,
        tables,
        1,
        1,
    )
    .await
    .unwrap();
    let wrapper = Arc::new(XelisWallet::from_test_wallet(wallet));

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let relayer_address = format!("ws://{}", listener.local_addr().unwrap());
    let (socket_sender, socket_receiver) = oneshot::channel();
    spawn_task("xswd-test-relayer", async move {
        let (stream, _) = listener.accept().await.unwrap();
        socket_sender
            .send(accept_async(stream).await.unwrap())
            .unwrap();
    });

    let cancel_calls = Arc::new(AtomicUsize::new(0));
    let recorded_cancel_calls = Arc::clone(&cancel_calls);
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (disconnect_started_sender, disconnect_started_receiver) = oneshot::channel();
    let disconnect_started_sender = Arc::new(Mutex::new(Some(disconnect_started_sender)));
    let (disconnect_release_sender, disconnect_release_receiver) = oneshot::channel();
    let disconnect_release_receiver = Arc::new(Mutex::new(Some(disconnect_release_receiver)));

    let cancel = move |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_cancel_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission_started = Arc::clone(&permission_started_sender);
    let pending_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        permission_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = pending_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect_started = Arc::clone(&disconnect_started_sender);
    let disconnect_release = Arc::clone(&disconnect_release_receiver);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        disconnect_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let release = disconnect_release.lock().unwrap().take().unwrap();
        Box::pin(async move {
            release.await.unwrap();
            XswdNotificationCallbackOutcome::Completed
        })
    };

    wrapper
        .add_xswd_relayer(
            ApplicationDataRelayer {
                id: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb".to_owned(),
                name: "Relayer close test".to_owned(),
                description: String::new(),
                url: None,
                permissions: vec!["get_balance".to_owned()],
                relayer: relayer_address,
                encryption_mode: None,
            },
            NativeXswdProjectionLimits::default(),
            cancel,
            application,
            permission,
            prefetch,
            disconnect,
        )
        .await
        .unwrap();
    let mut socket = socket_receiver.await.unwrap();
    let _registration = socket.next().await.unwrap().unwrap();
    let application = wrapper
        .get_application_permissions()
        .await
        .unwrap()
        .into_iter()
        .find(|application| application.is_relayer)
        .unwrap();

    socket
        .send(Message::Text(
            json!({
                "jsonrpc": "2.0",
                "id": 1,
                "method": "get_balance",
                "params": {"asset": null}
            })
            .to_string()
            .into(),
        ))
        .await
        .unwrap();
    permission_started_receiver.await.unwrap();

    let closing_wallet = Arc::clone(&wrapper);
    let close = spawn_task("xswd-test-close-relayer", async move {
        closing_wallet
            .close_application_session(application.session_ref)
            .await
    });
    disconnect_started_receiver.await.unwrap();

    socket
        .send(Message::Text(
            json!({"jsonrpc": "2.0", "id": 2, "method": "node.get_info"})
                .to_string()
                .into(),
        ))
        .await
        .ok();
    xelis_common::tokio::time::timeout(Duration::from_secs(2), async {
        while let Some(message) = socket.next().await {
            match message {
                Ok(Message::Close(_)) | Err(_) => break,
                Ok(_) => {}
            }
        }
    })
    .await
    .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(2), close)
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    assert_eq!(cancel_calls.load(Ordering::SeqCst), 1);
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::AlwaysAccept)
        .is_err());

    disconnect_release_sender.send(()).unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(2), async {
        loop {
            if wrapper.xswd_sessions().lock().await.sessions.is_empty() {
                break;
            }
            xelis_common::tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();
    wrapper.stop_xswd().await.unwrap();
}

#[tokio::test]
async fn handler_routes_every_event_once_and_returns_matching_responses() {
    let calls = Arc::new(Mutex::new(Vec::<(&'static str, XswdRequestSummary)>::new()));
    let (disconnect_seen_sender, disconnect_seen_receiver) = oneshot::channel();
    let disconnect_seen_sender = Arc::new(Mutex::new(Some(disconnect_seen_sender)));

    let cancel_calls = Arc::clone(&calls);
    let cancel = move |summary, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        let calls = Arc::clone(&cancel_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("cancel", summary));
            XswdNotificationCallbackOutcome::Completed
        })
    };

    let application_calls = Arc::clone(&calls);
    let application = move |summary| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        let calls = Arc::clone(&application_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("application", summary));
            XswdDecisionCallbackOutcome::AlwaysAccept
        })
    };

    let permission_calls = Arc::clone(&calls);
    let permission = move |summary| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        let calls = Arc::clone(&permission_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("permission", summary));
            XswdDecisionCallbackOutcome::Reject
        })
    };

    let prefetch_calls = Arc::clone(&calls);
    let prefetch = move |summary| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        let calls = Arc::clone(&prefetch_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("prefetch", summary));
            XswdDecisionCallbackOutcome::Accept
        })
    };

    let disconnect_calls = Arc::clone(&calls);
    let disconnect_seen = Arc::clone(&disconnect_seen_sender);
    let disconnect = move |summary| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        let calls = Arc::clone(&disconnect_calls);
        let disconnect_seen = Arc::clone(&disconnect_seen);
        Box::pin(async move {
            calls.lock().unwrap().push(("disconnect", summary));
            if let Some(sender) = disconnect_seen.lock().unwrap().take() {
                let _ = sender.send(());
            }
            XswdNotificationCallbackOutcome::Completed
        })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
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
    xelis_common::tokio::time::timeout(Duration::from_secs(1), disconnect_seen_receiver)
        .await
        .unwrap()
        .unwrap();
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
    let XswdRequestType::Permission(permission_payload) = &permission_summary.event_type else {
        panic!("expected permission payload");
    };
    assert!(permission_payload.tokens.iter().any(|token| {
        matches!(
            token.kind,
            crate::api::models::xswd_dtos::NativeXswdPayloadTokenKind::StringValue
        ) && token.text_value.as_deref() == Some("get_balance")
    }));

    let prefetch_summary = &calls[2].1;
    let XswdRequestType::PrefetchPermissions(prefetch_payload) = &prefetch_summary.event_type
    else {
        panic!("expected prefetch payload");
    };
    for permission in ["get_balance", "get_assets"] {
        assert!(prefetch_payload.tokens.iter().any(|token| {
            matches!(
                token.kind,
                crate::api::models::xswd_dtos::NativeXswdPayloadTokenKind::StringValue
            ) && token.text_value.as_deref() == Some(permission)
        }));
    }
}

#[tokio::test]
async fn handler_preempts_a_pending_permission_when_its_application_cancels() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission_started = Arc::clone(&permission_started_sender);
    let pending_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        permission_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = pending_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch_calls = Arc::new(AtomicUsize::new(0));
    let recorded_prefetch_calls = Arc::clone(&prefetch_calls);
    let prefetch = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        recorded_prefetch_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let (prefetch_sender, prefetch_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::PrefetchPermissions(
            Arc::clone(&app),
            prefetch_permissions(),
            prefetch_sender,
        ))
        .unwrap();

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(app, cancel_sender))
        .unwrap();

    let cancel_result =
        match xelis_common::tokio::time::timeout(Duration::from_secs(1), cancel_receiver).await {
            Ok(result) => result,
            Err(_) => {
                let _ = late_decision_sender.send(XswdDecisionCallbackOutcome::Accept);
                drop(sender);
                handler.await.unwrap();
                panic!("cancel must not wait for the pending Dart permission decision");
            }
        };
    cancel_result.unwrap().unwrap();

    let permission_error = permission_receiver.await.unwrap().unwrap_err();
    assert_eq!(permission_error.to_string(), "XSWD_REQUEST_CANCELLED");
    let prefetch_error = prefetch_receiver.await.unwrap().unwrap_err();
    assert_eq!(prefetch_error.to_string(), "XSWD_REQUEST_CANCELLED");
    assert_eq!(prefetch_calls.load(Ordering::SeqCst), 0);
    assert!(
        late_decision_sender
            .send(XswdDecisionCallbackOutcome::Accept)
            .is_err(),
        "a late Dart decision must not authorize a cancelled request"
    );

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn cancel_acknowledgement_and_followup_cancellation_do_not_wait_for_notification() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (notification_started_sender, notification_started_receiver) = oneshot::channel();
    let notification_started_sender = Arc::new(Mutex::new(Some(notification_started_sender)));
    let (notification_release_sender, notification_release_receiver) = oneshot::channel();
    let notification_release_receiver = Arc::new(Mutex::new(Some(notification_release_receiver)));
    let (cancelled_admission_sender, cancelled_admission_receiver) = oneshot::channel();
    let cancelled_admission_sender = Arc::new(Mutex::new(Some(cancelled_admission_sender)));

    let notification_started = Arc::clone(&notification_started_sender);
    let notification_release = Arc::clone(&notification_release_receiver);
    let recorded_cancelled_admission = Arc::clone(&cancelled_admission_sender);
    let cancel = move |_, cancelled_admission| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        if let Some(sender) = recorded_cancelled_admission.lock().unwrap().take() {
            sender.send(cancelled_admission).unwrap();
        }
        if let Some(sender) = notification_started.lock().unwrap().take() {
            sender.send(()).unwrap();
        }
        let release = notification_release.lock().unwrap().take().unwrap();
        Box::pin(async move {
            release.await.unwrap();
            XswdNotificationCallbackOutcome::Completed
        })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let first_app = app_state_with_id("first-app");
    let second_app = app_state_with_id("second-app");
    let request = RpcRequest {
        jsonrpc: "2.0".to_owned(),
        id: None,
        method: "get_balance".to_owned(),
        params: None,
    };

    let (first_response_sender, first_response_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&first_app),
            request.clone(),
            first_response_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let (first_cancel_sender, first_cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(first_app, first_cancel_sender))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), first_cancel_receiver)
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    notification_started_receiver.await.unwrap();
    assert!(!cancelled_admission_receiver.await.unwrap());

    let (second_response_sender, second_response_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&second_app),
            request,
            second_response_sender,
        ))
        .unwrap();
    let (second_cancel_sender, second_cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(second_app, second_cancel_sender))
        .unwrap();

    xelis_common::tokio::time::timeout(Duration::from_secs(1), second_cancel_receiver)
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    assert_eq!(
        second_response_receiver
            .await
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_REQUEST_CANCELLED
    );
    assert_eq!(
        first_response_receiver
            .await
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_REQUEST_CANCELLED
    );
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .is_err());

    notification_release_sender.send(()).unwrap();
    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn cancelling_a_deferred_admission_preserves_the_unrelated_active_decision() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (permission_release_sender, permission_release_receiver) = oneshot::channel();
    let permission_release_receiver = Arc::new(Mutex::new(Some(permission_release_receiver)));
    let (cancel_flag_sender, cancel_flag_receiver) = oneshot::channel();
    let cancel_flag_sender = Arc::new(Mutex::new(Some(cancel_flag_sender)));
    let application_calls = Arc::new(AtomicUsize::new(0));

    let recorded_flag = Arc::clone(&cancel_flag_sender);
    let cancel = move |_, cancelled_admission| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_flag
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(cancelled_admission)
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let recorded_application_calls = Arc::clone(&application_calls);
    let application = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        recorded_application_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let started = Arc::clone(&permission_started_sender);
    let release = Arc::clone(&permission_release_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        started.lock().unwrap().take().unwrap().send(()).unwrap();
        let release = release.lock().unwrap().take().unwrap();
        Box::pin(async move {
            release.await.unwrap();
            XswdDecisionCallbackOutcome::Accept
        })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let active_app = app_state_with_id("active-permission");
    let deferred_app = app_state_with_id("deferred-admission");
    let (active_sender, active_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            active_app,
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            active_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let (deferred_sender, deferred_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&deferred_app),
            deferred_sender,
        ))
        .unwrap();
    let (ack_sender, ack_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(
            Arc::clone(&deferred_app),
            ack_sender,
        ))
        .unwrap();
    ack_receiver.await.unwrap().unwrap();
    assert_eq!(
        deferred_receiver.await.unwrap().unwrap_err().to_string(),
        XSWD_REQUEST_CANCELLED
    );
    assert_eq!(
        registry
            .lock()
            .await
            .register(&deferred_app)
            .unwrap_err()
            .to_string(),
        XSWD_SESSION_REFERENCE_INVALID
    );
    assert_eq!(application_calls.load(Ordering::SeqCst), 0);

    permission_release_sender.send(()).unwrap();
    assert!(matches!(
        active_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    assert!(cancel_flag_receiver.await.unwrap());

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn cancel_notification_failures_remain_diagnostic_after_upstream_acknowledgement() {
    let outcomes = Arc::new(Mutex::new(VecDeque::from([
        XswdNotificationCallbackOutcome::Exception,
        XswdNotificationCallbackOutcome::Timeout,
    ])));
    let callback_outcomes = Arc::clone(&outcomes);
    let cancel = move |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        let outcome = callback_outcomes.lock().unwrap().pop_front().unwrap();
        Box::pin(async move { outcome })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    for _ in 0..2 {
        let (response, receiver) = oneshot::channel();
        handle_xswd_event(
            XSWDEvent::CancelRequest(app_state(), response),
            NativeXswdProjectionLimits::default(),
            &cancel,
            &application,
            &permission,
            &prefetch,
            &disconnect,
        )
        .await;
        receiver.await.unwrap().unwrap();
    }
    assert!(outcomes.lock().unwrap().is_empty());
}

#[tokio::test]
async fn cancellation_after_admission_completion_reports_false_and_keeps_session_active() {
    let (cancel_flag_sender, cancel_flag_receiver) = oneshot::channel();
    let cancel_flag_sender = Arc::new(Mutex::new(Some(cancel_flag_sender)));
    let recorded_flag = Arc::clone(&cancel_flag_sender);
    let cancel = move |_, cancelled_admission| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_flag
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(cancelled_admission)
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();
    let (response_sender, response_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&app),
            response_sender,
        ))
        .unwrap();
    assert!(matches!(
        response_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    let session_ref = *registry.lock().await.sessions.keys().next().unwrap();

    let (ack_sender, ack_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(Arc::clone(&app), ack_sender))
        .unwrap();
    ack_receiver.await.unwrap().unwrap();
    assert!(!cancel_flag_receiver.await.unwrap());
    assert!(Arc::ptr_eq(
        &registry.lock().await.resolve(session_ref).unwrap(),
        &app
    ));

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn foreign_cancellation_does_not_tombstone_an_active_admission_or_same_id_session() {
    let (application_release_sender, application_release_receiver) = oneshot::channel();
    let application_release_receiver = Arc::new(Mutex::new(Some(application_release_receiver)));
    let (cancel_flag_sender, cancel_flag_receiver) = oneshot::channel();
    let cancel_flag_sender = Arc::new(Mutex::new(Some(cancel_flag_sender)));
    let recorded_flag = Arc::clone(&cancel_flag_sender);
    let cancel = move |_, cancelled_admission| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_flag
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(cancelled_admission)
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let release = Arc::clone(&application_release_receiver);
    let application = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        let release = release.lock().unwrap().take().unwrap();
        Box::pin(async move {
            release.await.unwrap();
            XswdDecisionCallbackOutcome::Accept
        })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let active_app = app_state_with_id("shared-id");
    let other_app = app_state_with_id("shared-id");
    let other_ref = registry.lock().await.register(&other_app).unwrap();
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let (active_sender, mut active_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(active_app, active_sender))
        .unwrap();
    xelis_common::tokio::task::yield_now().await;

    let (ack_sender, ack_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(Arc::clone(&other_app), ack_sender))
        .unwrap();
    ack_receiver.await.unwrap().unwrap();
    assert!(matches!(
        active_receiver.try_recv(),
        Err(oneshot::error::TryRecvError::Empty)
    ));
    assert!(Arc::ptr_eq(
        &registry.lock().await.resolve(other_ref).unwrap(),
        &other_app
    ));

    application_release_sender.send(()).unwrap();
    assert!(matches!(
        active_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    assert!(!cancel_flag_receiver.await.unwrap());

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn handler_keeps_decision_callbacks_serial() {
    let (first_started_sender, first_started_receiver) = oneshot::channel();
    let (second_started_sender, mut second_started_receiver) = oneshot::channel();
    let starts = Arc::new(Mutex::new(VecDeque::from([
        first_started_sender,
        second_started_sender,
    ])));
    let (first_decision_sender, first_decision_receiver) = oneshot::channel();
    let (second_decision_sender, second_decision_receiver) = oneshot::channel();
    let decisions = Arc::new(Mutex::new(VecDeque::from([
        first_decision_receiver,
        second_decision_receiver,
    ])));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_starts = Arc::clone(&starts);
    let callback_decisions = Arc::clone(&decisions);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_starts
            .lock()
            .unwrap()
            .pop_front()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decisions.lock().unwrap().pop_front().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();
    let request = RpcRequest {
        jsonrpc: "2.0".to_owned(),
        id: None,
        method: "get_balance".to_owned(),
        params: None,
    };

    let (first_response_sender, first_response_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            request.clone(),
            first_response_sender,
        ))
        .unwrap();
    first_started_receiver.await.unwrap();

    let (second_response_sender, second_response_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            app,
            request,
            second_response_sender,
        ))
        .unwrap();
    assert!(
        xelis_common::tokio::time::timeout(
            Duration::from_millis(100),
            &mut second_started_receiver,
        )
        .await
        .is_err(),
        "a second decision callback must wait for the active review"
    );

    first_decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .unwrap();
    assert!(matches!(
        first_response_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    xelis_common::tokio::time::timeout(Duration::from_secs(1), second_started_receiver)
        .await
        .unwrap()
        .unwrap();

    second_decision_sender
        .send(XswdDecisionCallbackOutcome::Reject)
        .unwrap();
    assert!(matches!(
        second_response_receiver.await.unwrap().unwrap(),
        PermissionResult::Reject
    ));

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn handler_bounds_deferred_decisions_and_rejects_overflow_statically() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let prefetch_calls = Arc::new(AtomicUsize::new(0));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let recorded_prefetch_calls = Arc::clone(&prefetch_calls);
    let prefetch = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        recorded_prefetch_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let mut queued_receivers = Vec::with_capacity(MAX_DEFERRED_XSWD_EVENTS);
    for _ in 0..MAX_DEFERRED_XSWD_EVENTS {
        let (response_sender, response_receiver) = oneshot::channel();
        sender
            .send(XSWDEvent::PrefetchPermissions(
                Arc::clone(&app),
                prefetch_permissions(),
                response_sender,
            ))
            .unwrap();
        queued_receivers.push(response_receiver);
    }
    let (overflow_sender, overflow_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::PrefetchPermissions(
            Arc::clone(&app),
            prefetch_permissions(),
            overflow_sender,
        ))
        .unwrap();

    let overflow_error =
        xelis_common::tokio::time::timeout(Duration::from_secs(1), overflow_receiver)
            .await
            .unwrap()
            .unwrap()
            .unwrap_err();
    assert_eq!(overflow_error.to_string(), XSWD_REQUEST_QUEUE_FULL);
    assert_eq!(prefetch_calls.load(Ordering::SeqCst), 0);

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(app, cancel_sender))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), cancel_receiver)
        .await
        .unwrap()
        .unwrap()
        .unwrap();

    assert_eq!(
        permission_receiver.await.unwrap().unwrap_err().to_string(),
        XSWD_REQUEST_CANCELLED
    );
    for response in queued_receivers {
        assert_eq!(
            response.await.unwrap().unwrap_err().to_string(),
            XSWD_REQUEST_CANCELLED
        );
    }
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .is_err());

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn ready_decision_progresses_during_a_sustained_receive_burst() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (decision_sender, decision_receiver) = oneshot::channel();
    let decision_receiver = Arc::new(Mutex::new(Some(decision_receiver)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch =
        |_| -> DartFnFuture<XswdDecisionCallbackOutcome> { Box::pin(std::future::pending()) };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let mut deferred_receivers = Vec::with_capacity(MAX_DEFERRED_XSWD_EVENTS);
    for _ in 0..MAX_DEFERRED_XSWD_EVENTS {
        let (response_sender, response_receiver) = oneshot::channel();
        sender
            .send(XSWDEvent::PrefetchPermissions(
                Arc::clone(&app),
                prefetch_permissions(),
                response_sender,
            ))
            .unwrap();
        deferred_receivers.push(response_receiver);
    }
    decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .unwrap();

    let permission_result =
        xelis_common::tokio::time::timeout(Duration::from_secs(1), permission_receiver)
            .await
            .unwrap()
            .unwrap()
            .unwrap();
    assert!(matches!(permission_result, PermissionResult::Accept));

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(app, cancel_sender))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), cancel_receiver)
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    for response in deferred_receivers {
        assert_eq!(
            response.await.unwrap().unwrap_err().to_string(),
            XSWD_REQUEST_CANCELLED
        );
    }

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn closed_event_channel_fails_pending_decisions_without_waiting_for_dart() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let (prefetch_sender, prefetch_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::PrefetchPermissions(
            app,
            prefetch_permissions(),
            prefetch_sender,
        ))
        .unwrap();
    drop(sender);

    let permission_error = permission_receiver.await.unwrap().unwrap_err();
    assert_eq!(permission_error.to_string(), XSWD_HANDLER_CLOSED);
    let prefetch_error = prefetch_receiver.await.unwrap().unwrap_err();
    assert_eq!(prefetch_error.to_string(), XSWD_HANDLER_CLOSED);
    xelis_common::tokio::time::timeout(Duration::from_secs(1), handler)
        .await
        .unwrap()
        .unwrap();
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::AlwaysAccept)
        .is_err());
}

#[tokio::test]
async fn repeated_disconnects_for_one_deferred_state_are_coalesced() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (decision_sender, decision_receiver) = oneshot::channel();
    let decision_receiver = Arc::new(Mutex::new(Some(decision_receiver)));
    let disconnect_calls = Arc::new(AtomicUsize::new(0));
    let (disconnect_seen_sender, disconnect_seen_receiver) = oneshot::channel();
    let disconnect_seen_sender = Arc::new(Mutex::new(Some(disconnect_seen_sender)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let recorded_disconnect_calls = Arc::clone(&disconnect_calls);
    let disconnect_seen = Arc::clone(&disconnect_seen_sender);
    let disconnect =
        move |summary: XswdRequestSummary| -> DartFnFuture<XswdNotificationCallbackOutcome> {
            assert_eq!(summary.application_info.id, "deferred-app");
            recorded_disconnect_calls.fetch_add(1, Ordering::SeqCst);
            if let Some(sender) = disconnect_seen.lock().unwrap().take() {
                sender.send(()).unwrap();
            }
            Box::pin(async { XswdNotificationCallbackOutcome::Completed })
        };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let active_app = app_state();
    let deferred_app = app_state_with_id("deferred-app");

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            active_app,
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    sender
        .send(XSWDEvent::AppDisconnect(Arc::clone(&deferred_app)))
        .unwrap();
    sender.send(XSWDEvent::AppDisconnect(deferred_app)).unwrap();
    decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .unwrap();
    assert!(matches!(
        permission_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    xelis_common::tokio::time::timeout(Duration::from_secs(1), disconnect_seen_receiver)
        .await
        .unwrap()
        .unwrap();

    drop(sender);
    handler.await.unwrap();
    assert_eq!(disconnect_calls.load(Ordering::SeqCst), 1);
}

#[test]
fn deferred_disconnect_storage_is_coalesced_and_bounded_in_total() {
    let mut deferred = VecDeque::new();
    let first = app_state_with_id("disconnect-0");

    assert!(
        defer_xswd_disconnect(&mut deferred, None, prepared_disconnect(Arc::clone(&first)),)
            .is_none()
    );
    assert!(defer_xswd_disconnect(&mut deferred, None, prepared_disconnect(first)).is_none());
    assert_eq!(deferred.len(), 1);

    for index in 1..MAX_DEFERRED_XSWD_EVENTS {
        assert!(defer_xswd_disconnect(
            &mut deferred,
            None,
            prepared_disconnect(app_state_with_id(&format!("disconnect-{index}"))),
        )
        .is_none());
    }
    assert_eq!(deferred.len(), MAX_DEFERRED_XSWD_EVENTS);

    let overflow = app_state_with_id("disconnect-overflow");
    let returned = defer_xswd_disconnect(
        &mut deferred,
        None,
        prepared_disconnect(Arc::clone(&overflow)),
    );
    assert!(returned.is_some());
    assert_eq!(deferred.len(), MAX_DEFERRED_XSWD_EVENTS);
}

#[tokio::test]
async fn deferred_disconnect_evicts_one_decision_and_preserves_the_bound() {
    let mut deferred = VecDeque::new();
    let mut receivers = Vec::with_capacity(MAX_DEFERRED_XSWD_EVENTS);
    for index in 0..MAX_DEFERRED_XSWD_EVENTS {
        let (sender, receiver) = oneshot::channel();
        deferred.push_back(DeferredXswdEvent::Raw(XSWDEvent::RequestApplication(
            app_state_with_id(&format!("decision-{index}")),
            sender,
        )));
        receivers.push(receiver);
    }

    assert!(defer_xswd_disconnect(
        &mut deferred,
        None,
        prepared_disconnect(app_state_with_id("disconnect-overflow")),
    )
    .is_none());
    assert_eq!(deferred.len(), MAX_DEFERRED_XSWD_EVENTS);
    assert_eq!(
        receivers.remove(0).await.unwrap().unwrap_err().to_string(),
        XSWD_REQUEST_QUEUE_FULL
    );
    assert!(matches!(
        deferred.back(),
        Some(DeferredXswdEvent::Notification(PreparedXswdNotification {
            kind: XswdNotificationKind::AppDisconnect,
            ..
        }))
    ));

    fail_deferred_xswd_events(&mut deferred, XSWD_HANDLER_CLOSED);
}

#[tokio::test]
async fn cancellation_uses_the_exact_application_state_identity() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (decision_sender, decision_receiver) = oneshot::channel();
    let decision_receiver = Arc::new(Mutex::new(Some(decision_receiver)));

    let cancel_calls = Arc::new(AtomicUsize::new(0));
    let recorded_cancel_calls = Arc::clone(&cancel_calls);
    let cancel = move |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_cancel_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let active_app = app_state();
    let replacement_with_same_id = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            active_app,
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(
            replacement_with_same_id,
            cancel_sender,
        ))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), cancel_receiver)
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    assert_eq!(
        cancel_calls.load(Ordering::SeqCst),
        0,
        "a stale cancellation must not clear the active review for another state instance"
    );

    decision_sender
        .send(XswdDecisionCallbackOutcome::Accept)
        .unwrap();
    assert!(matches!(
        permission_receiver.await.unwrap().unwrap(),
        PermissionResult::Accept
    ));

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn app_disconnect_preempts_the_exact_pending_permission() {
    let (permission_started_sender, permission_started_receiver) = oneshot::channel();
    let permission_started_sender = Arc::new(Mutex::new(Some(permission_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (disconnect_seen_sender, disconnect_seen_receiver) = oneshot::channel();
    let disconnect_seen_sender = Arc::new(Mutex::new(Some(disconnect_seen_sender)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let callback_started = Arc::clone(&permission_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect_seen = Arc::clone(&disconnect_seen_sender);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        disconnect_seen
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            permission_sender,
        ))
        .unwrap();
    permission_started_receiver.await.unwrap();

    sender.send(XSWDEvent::AppDisconnect(app)).unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), disconnect_seen_receiver)
        .await
        .unwrap()
        .unwrap();

    let permission_error = permission_receiver.await.unwrap().unwrap_err();
    assert_eq!(permission_error.to_string(), "XSWD_REQUEST_CANCELLED");
    assert!(
        late_decision_sender
            .send(XswdDecisionCallbackOutcome::AlwaysAccept)
            .is_err(),
        "a late Dart decision must not authorize a disconnected application"
    );

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn cancelled_application_admission_cannot_remint_its_session_or_complete_late() {
    let (application_started_sender, application_started_receiver) = oneshot::channel();
    let application_started_sender = Arc::new(Mutex::new(Some(application_started_sender)));
    let (late_decision_sender, late_decision_receiver) = oneshot::channel();
    let late_decision_receiver = Arc::new(Mutex::new(Some(late_decision_receiver)));
    let (cancelled_admission_sender, cancelled_admission_receiver) = oneshot::channel();
    let cancelled_admission_sender = Arc::new(Mutex::new(Some(cancelled_admission_sender)));

    let recorded_cancelled_admission = Arc::clone(&cancelled_admission_sender);
    let cancel = move |_, cancelled_admission| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_cancelled_admission
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(cancelled_admission)
            .unwrap();
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let callback_started = Arc::clone(&application_started_sender);
    let callback_decision = Arc::clone(&late_decision_receiver);
    let application = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        callback_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let decision = callback_decision.lock().unwrap().take().unwrap();
        Box::pin(async move { decision.await.unwrap() })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (application_sender, mut application_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&app),
            application_sender,
        ))
        .unwrap();
    application_started_receiver.await.unwrap();
    let registered_reference = *registry.lock().await.sessions.keys().next().unwrap();

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(Arc::clone(&app), cancel_sender))
        .unwrap();
    cancel_receiver.await.unwrap().unwrap();
    assert!(cancelled_admission_receiver.await.unwrap());
    assert_eq!(
        application_receiver
            .try_recv()
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_REQUEST_CANCELLED
    );
    {
        let mut registry = registry.lock().await;
        assert!(registry.resolve(registered_reference).is_none());
        assert_eq!(
            registry.register(&app).unwrap_err().to_string(),
            XSWD_SESSION_REFERENCE_INVALID
        );
    }
    assert!(late_decision_sender
        .send(XswdDecisionCallbackOutcome::AlwaysAccept)
        .is_err());

    drop(sender);
    handler.await.unwrap();
}

#[tokio::test]
async fn disconnect_invalidates_native_authority_before_a_slow_notification_settles() {
    let (disconnect_started_sender, disconnect_started_receiver) = oneshot::channel();
    let disconnect_started_sender = Arc::new(Mutex::new(Some(disconnect_started_sender)));
    let (disconnect_release_sender, disconnect_release_receiver) = oneshot::channel();
    let disconnect_release_receiver = Arc::new(Mutex::new(Some(disconnect_release_receiver)));

    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let notification_started = Arc::clone(&disconnect_started_sender);
    let notification_release = Arc::clone(&disconnect_release_receiver);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        notification_started
            .lock()
            .unwrap()
            .take()
            .unwrap()
            .send(())
            .unwrap();
        let release = notification_release.lock().unwrap().take().unwrap();
        Box::pin(async move {
            release.await.unwrap();
            XswdNotificationCallbackOutcome::Completed
        })
    };

    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let app = app_state();
    let session_ref = registry.lock().await.register(&app).unwrap();
    let permissions = app.get_permissions();
    let permissions_guard = permissions.lock().await;
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));

    sender
        .send(XSWDEvent::AppDisconnect(Arc::clone(&app)))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), async {
        loop {
            if registry.lock().await.resolve(session_ref).is_none() {
                break;
            }
            xelis_common::tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();
    assert_eq!(
        registry
            .lock()
            .await
            .register(&app)
            .unwrap_err()
            .to_string(),
        XSWD_SESSION_REFERENCE_INVALID
    );

    drop(permissions_guard);
    disconnect_started_receiver.await.unwrap();

    drop(sender);
    xelis_common::tokio::time::timeout(Duration::from_secs(1), handler)
        .await
        .unwrap()
        .unwrap();
    assert!(disconnect_release_sender.send(()).is_err());
}

#[tokio::test]
async fn saturated_disconnect_notifications_abandon_the_tracked_callback_and_advance() {
    let disconnect_calls = Arc::new(AtomicUsize::new(0));
    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let recorded_disconnect_calls = Arc::clone(&disconnect_calls);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        recorded_disconnect_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(std::future::pending())
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));

    sender
        .send(XSWDEvent::AppDisconnect(app_state_with_id("disconnect-0")))
        .unwrap();
    xelis_common::tokio::time::timeout(Duration::from_secs(1), async {
        while disconnect_calls.load(Ordering::SeqCst) < 1 {
            xelis_common::tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();

    for index in 1..=MAX_DEFERRED_XSWD_EVENTS + 1 {
        sender
            .send(XSWDEvent::AppDisconnect(app_state_with_id(&format!(
                "disconnect-{index}"
            ))))
            .unwrap();
    }
    xelis_common::tokio::time::timeout(Duration::from_secs(1), async {
        while disconnect_calls.load(Ordering::SeqCst) < 2 {
            xelis_common::tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();

    drop(sender);
    handler.await.unwrap();
    assert_eq!(disconnect_calls.load(Ordering::SeqCst), 2);
}

#[tokio::test]
async fn all_notification_saturation_fails_and_tombstones_an_active_admission() {
    let (application_started_sender, application_started_receiver) = oneshot::channel();
    let application_started_sender = Arc::new(Mutex::new(Some(application_started_sender)));
    let disconnect_calls = Arc::new(AtomicUsize::new(0));
    let cancel = |_, _| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let started = Arc::clone(&application_started_sender);
    let application = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        started.lock().unwrap().take().unwrap().send(()).unwrap();
        Box::pin(std::future::pending())
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let calls = Arc::clone(&disconnect_calls);
    let disconnect = move |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(std::future::pending())
    };

    let registry = Arc::new(xelis_common::tokio::sync::Mutex::new(
        XswdSessionRegistry::default(),
    ));
    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler_with_registry(
        receiver,
        Arc::clone(&registry),
        NativeXswdProjectionLimits::default(),
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state_with_id("active-admission");
    let (response_sender, response_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&app),
            response_sender,
        ))
        .unwrap();
    application_started_receiver.await.unwrap();
    let session_ref = *registry.lock().await.sessions.keys().next().unwrap();

    for index in 0..=MAX_DEFERRED_XSWD_EVENTS {
        sender
            .send(XSWDEvent::AppDisconnect(app_state_with_id(&format!(
                "queued-disconnect-{index}"
            ))))
            .unwrap();
    }

    assert_eq!(
        xelis_common::tokio::time::timeout(Duration::from_secs(1), response_receiver)
            .await
            .unwrap()
            .unwrap()
            .unwrap_err()
            .to_string(),
        XSWD_HANDLER_OVERLOADED
    );
    assert!(registry.lock().await.resolve(session_ref).is_none());
    assert_eq!(disconnect_calls.load(Ordering::SeqCst), 1);

    drop(sender);
    handler.await.unwrap();
}
