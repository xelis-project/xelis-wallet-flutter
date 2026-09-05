use super::*;
use std::{
    collections::VecDeque,
    sync::atomic::{AtomicUsize, Ordering},
    time::Duration,
};

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
