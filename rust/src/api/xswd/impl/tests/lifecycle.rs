use super::*;

#[test]
fn dropped_permission_receivers_do_not_panic() {
    let (sender, receiver) = oneshot::channel();
    drop(receiver);

    handle_permission_decision(UserPermissionDecision::Accept, sender);
}

#[tokio::test]
async fn dropped_event_response_receivers_do_not_panic() {
    let cancel = |_| -> DartFnFuture<()> { Box::pin(async {}) };
    let application = |_| -> DartFnFuture<UserPermissionDecision> {
        Box::pin(async { UserPermissionDecision::Accept })
    };
    let permission = |_| -> DartFnFuture<UserPermissionDecision> {
        Box::pin(async { UserPermissionDecision::Reject })
    };
    let prefetch = |_| -> DartFnFuture<UserPermissionDecision> {
        Box::pin(async { UserPermissionDecision::AlwaysAccept })
    };
    let disconnect = |_| -> DartFnFuture<()> { Box::pin(async {}) };
    let app = app_state();

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::RequestApplication(Arc::clone(&app), response),
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
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;
}
