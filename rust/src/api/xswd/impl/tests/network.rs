use super::*;
use std::{
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

#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
async fn assert_closed_session(wrapper: &XelisWallet, session_ref: u64) {
    // A weak tombstone may outlive transport cleanup. Check the public native
    // authority and upstream membership, not the registry's storage strategy.
    assert!(wrapper
        .xswd_sessions()
        .lock()
        .await
        .resolve(session_ref)
        .is_none());
    let error = wrapper
        .modify_application_permissions(session_ref, HashMap::new())
        .await
        .unwrap_err();
    assert_eq!(error.code, NativeXelisErrorCode::Conflict);
    assert_eq!(
        error.native_kind.as_deref(),
        Some(XSWD_SESSION_REFERENCE_INVALID)
    );
    xelis_common::tokio::time::timeout(Duration::from_secs(2), async {
        loop {
            let applications = wrapper.get_application_permissions().await.unwrap();
            if applications
                .iter()
                .all(|app| app.session_ref != session_ref)
            {
                break;
            }
            xelis_common::tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();
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
    assert_closed_session(&wrapper, application_summary.application_info.session_ref).await;

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

    let session_ref = application.session_ref;
    let closing_wallet = Arc::clone(&wrapper);
    let close = spawn_task("xswd-test-close-relayer", async move {
        closing_wallet.close_application_session(session_ref).await
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

    assert_closed_session(&wrapper, session_ref).await;
    disconnect_release_sender.send(()).unwrap();
    wrapper.stop_xswd().await.unwrap();
}
