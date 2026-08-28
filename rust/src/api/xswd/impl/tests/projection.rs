use std::sync::atomic::{AtomicUsize, Ordering};

use crate::api::models::xswd_dtos::NativeXswdPayloadTokenKind;
use serde_json::Value;

use super::*;

#[tokio::test]
async fn permission_projection_preserves_large_integers_and_explicit_signers() {
    let captured = Arc::new(Mutex::new(None::<XswdRequestSummary>));
    let captured_request = Arc::clone(&captured);
    let permission = move |summary| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        let captured = Arc::clone(&captured_request);
        Box::pin(async move {
            captured.lock().unwrap().replace(summary);
            XswdDecisionCallbackOutcome::Reject
        })
    };
    let cancel = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let signer = "sentinel-private-key";
    let (response, receiver) = oneshot::channel();

    handle_xswd_event(
        XSWDEvent::RequestPermission(
            app_state(),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "build_transaction".to_owned(),
                params: Some(json!({
                    "transfers": [{"amount": 9_007_199_254_740_993_u64}],
                    "fee_limit": u64::MAX,
                    "nonce": 9_007_199_254_740_992_u64,
                    "max_gas": 9_007_199_254_740_991_u64,
                    "signers": [{"id": 7, "private_key": signer}]
                })),
            },
            response,
        ),
        NativeXswdProjectionLimits::default(),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;

    assert!(matches!(
        receiver.await.unwrap().unwrap(),
        PermissionResult::Reject
    ));
    let summary = captured.lock().unwrap().take().unwrap();
    let XswdRequestType::Permission(payload) = &summary.event_type else {
        panic!("expected permission payload");
    };
    for expected in [
        "9007199254740993",
        "18446744073709551615",
        "9007199254740992",
        "9007199254740991",
    ] {
        assert!(payload.tokens.iter().any(|token| {
            matches!(token.kind, NativeXswdPayloadTokenKind::Integer)
                && token.text_value.as_deref() == Some(expected)
        }));
    }
    assert!(payload.tokens.iter().any(|token| {
        matches!(token.kind, NativeXswdPayloadTokenKind::StringValue)
            && token.text_value.as_deref() == Some(signer)
    }));

    let debug = format!("{summary:?}");
    assert!(!debug.contains(signer));
    assert!(!debug.contains("private_key"));
    assert!(!debug.contains("signers"));
}

#[tokio::test]
async fn projection_limit_failures_return_errors_without_invoking_dart_callbacks() {
    let permission_calls = Arc::new(AtomicUsize::new(0));
    let permission_counter = Arc::clone(&permission_calls);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        permission_counter.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let prefetch_calls = Arc::new(AtomicUsize::new(0));
    let prefetch_counter = Arc::clone(&prefetch_calls);
    let prefetch = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        prefetch_counter.fetch_add(1, Ordering::SeqCst);
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let cancel = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let (permission_response, permission_receiver) = oneshot::channel();
    handle_xswd_event(
        XSWDEvent::RequestPermission(
            app_state(),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "build_transaction".to_owned(),
                params: Some(Value::Array(vec![Value::Null; 4_097])),
            },
            permission_response,
        ),
        NativeXswdProjectionLimits::default(),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;
    assert_eq!(
        permission_receiver.await.unwrap().unwrap_err().to_string(),
        "XSWD_PAYLOAD_PROJECTION_FAILED"
    );
    assert_eq!(permission_calls.load(Ordering::SeqCst), 0);

    let oversized_prefetch = XSWDPrefetchPermissions {
        reason: None,
        permissions: (0..4_097).map(|index| format!("method_{index}")).collect(),
    };
    let (prefetch_response, prefetch_receiver) = oneshot::channel();
    handle_xswd_event(
        XSWDEvent::PrefetchPermissions(app_state(), oversized_prefetch, prefetch_response),
        NativeXswdProjectionLimits::default(),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;
    assert_eq!(
        prefetch_receiver.await.unwrap().unwrap_err().to_string(),
        "XSWD_PAYLOAD_PROJECTION_FAILED"
    );
    assert_eq!(prefetch_calls.load(Ordering::SeqCst), 0);
}

#[tokio::test]
async fn each_permission_decision_uses_its_own_event_sender() {
    let calls = Arc::new(AtomicUsize::new(0));
    let callback_calls = Arc::clone(&calls);
    let permission = move |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        let call = callback_calls.fetch_add(1, Ordering::SeqCst);
        Box::pin(async move {
            if call == 0 {
                XswdDecisionCallbackOutcome::Accept
            } else {
                XswdDecisionCallbackOutcome::Reject
            }
        })
    };
    let cancel = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };

    let mut receivers = Vec::new();
    for method in ["get_balance", "build_transaction"] {
        let (response, receiver) = oneshot::channel();
        handle_xswd_event(
            XSWDEvent::RequestPermission(
                app_state(),
                RpcRequest {
                    jsonrpc: "2.0".to_owned(),
                    id: None,
                    method: method.to_owned(),
                    params: None,
                },
                response,
            ),
            NativeXswdProjectionLimits::default(),
            &cancel,
            &application,
            &permission,
            &prefetch,
            &disconnect,
        )
        .await;
        receivers.push(receiver);
    }

    assert!(matches!(
        receivers.remove(0).await.unwrap().unwrap(),
        PermissionResult::Accept
    ));
    assert!(matches!(
        receivers.remove(0).await.unwrap().unwrap(),
        PermissionResult::Reject
    ));
}
