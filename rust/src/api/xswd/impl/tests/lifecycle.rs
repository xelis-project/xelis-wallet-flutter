use super::*;

#[test]
fn dropped_permission_receivers_do_not_panic() {
    let (sender, receiver) = oneshot::channel();
    drop(receiver);

    handle_permission_outcome(XswdDecisionCallbackOutcome::Accept, sender);
}

#[tokio::test]
async fn dropped_event_response_receivers_do_not_panic() {
    let cancel = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let application = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Accept })
    };
    let permission = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::Reject })
    };
    let prefetch = |_| -> DartFnFuture<XswdDecisionCallbackOutcome> {
        Box::pin(async { XswdDecisionCallbackOutcome::AlwaysAccept })
    };
    let disconnect = |_| -> DartFnFuture<XswdNotificationCallbackOutcome> {
        Box::pin(async { XswdNotificationCallbackOutcome::Completed })
    };
    let app = app_state();

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::RequestApplication(Arc::clone(&app), response),
        NativeXswdProjectionLimits::default(),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
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

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::PrefetchPermissions(Arc::clone(&app), prefetch_permissions(), response),
        NativeXswdProjectionLimits::default(),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::CancelRequest(app, response),
        NativeXswdProjectionLimits::default(),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;
}
