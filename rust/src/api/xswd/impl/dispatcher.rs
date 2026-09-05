use std::{
    collections::VecDeque,
    sync::{Arc, Weak},
};

use anyhow::{anyhow, Error, Result};
use indexmap::IndexMap;
use log::{debug, info};
use xelis_common::tokio::select;

use super::{
    handle_permission_outcome, handle_prefetch_permissions_outcome, prepare_xswd_event,
    prepare_xswd_lifecycle_notification, record_abandoned_xswd_notification,
    record_xswd_notification_outcome, xswd_event_name, AppState, DartFnFuture,
    NativeXswdProjectionLimits, Permission, PermissionResult, Sender, UnboundedReceiver, XSWDEvent,
    XSWDPrefetchPermissions, XswdDecisionCallbackOutcome, XswdNotificationCallbackOutcome,
    XswdRequestSummary, XswdSessionRegistry, MAX_DEFERRED_XSWD_EVENTS, MAX_XSWD_RECEIVE_BURST,
    XSWD_HANDLER_CLOSED, XSWD_HANDLER_OVERLOADED, XSWD_REQUEST_CANCELLED, XSWD_REQUEST_QUEUE_FULL,
};

#[flutter_rust_bridge::frb(ignore)]
pub(super) async fn run(
    mut receiver: UnboundedReceiver<XSWDEvent>,
    xswd_sessions: Arc<xelis_common::tokio::sync::Mutex<XswdSessionRegistry>>,
    projection_limits: NativeXswdProjectionLimits,
    cancel_request_dart_callback: impl Fn(
        XswdRequestSummary,
        bool,
    ) -> DartFnFuture<XswdNotificationCallbackOutcome>,
    request_application_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    request_permission_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    request_prefetch_permissions_dart_callback: impl Fn(
        XswdRequestSummary,
    )
        -> DartFnFuture<XswdDecisionCallbackOutcome>,
    app_disconnect_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<XswdNotificationCallbackOutcome>,
) {
    info!("XSWD Server has been enabled");
    let mut deferred = VecDeque::new();
    let mut active = None;
    let mut receive_burst = 0;
    let mut observed_states = Vec::new();

    loop {
        if active.is_none() {
            let event = if let Some(event) = deferred.pop_front() {
                event
            } else {
                match receiver.recv().await {
                    Some(event) => {
                        info!("Received XSWD event: {}", xswd_event_name(&event));
                        track_xswd_state(&mut observed_states, xswd_event_state(&event));
                        DeferredXswdEvent::Raw(event)
                    }
                    None => {
                        invalidate_observed_xswd_states(&xswd_sessions, &observed_states).await;
                        break;
                    }
                }
            };

            match event {
                DeferredXswdEvent::Raw(event) => match prepare_xswd_event(
                    event,
                    &xswd_sessions,
                    projection_limits,
                    &request_application_dart_callback,
                    &request_permission_dart_callback,
                    &request_prefetch_permissions_dart_callback,
                )
                .await
                {
                    PreparedXswdEvent::Decision(decision) => {
                        active = Some(decision.into_active());
                        receive_burst = 0;
                    }
                    PreparedXswdEvent::Lifecycle(event) => {
                        let (state, kind) = event.acknowledge();
                        if matches!(kind, XswdNotificationKind::AppDisconnect) {
                            xswd_sessions.lock().await.invalidate_state(&state);
                        }
                        if let Some(notification) =
                            prepare_xswd_lifecycle_notification(state, kind, false, &xswd_sessions)
                                .await
                        {
                            active = Some(notification.start(
                                &cancel_request_dart_callback,
                                &app_disconnect_dart_callback,
                            ));
                            receive_burst = 0;
                        }
                    }
                    PreparedXswdEvent::Handled => {}
                },
                DeferredXswdEvent::Notification(notification) => {
                    active = Some(
                        notification
                            .start(&cancel_request_dart_callback, &app_disconnect_dart_callback),
                    );
                    receive_burst = 0;
                }
            }
            continue;
        }

        let input = {
            let Some(callback) = active.as_mut() else {
                continue;
            };
            if receive_burst >= MAX_XSWD_RECEIVE_BURST {
                receive_burst = 0;
                select! {
                    biased;
                    outcome = callback.future.as_mut() => XswdHandlerInput::Callback(outcome),
                    event = receiver.recv() => XswdHandlerInput::Event(event),
                }
            } else {
                select! {
                    biased;
                    event = receiver.recv() => XswdHandlerInput::Event(event),
                    outcome = callback.future.as_mut() => XswdHandlerInput::Callback(outcome),
                }
            }
        };

        match input {
            XswdHandlerInput::Callback(outcome) => {
                receive_burst = 0;
                if let Some(callback) = active.take() {
                    callback.complete(outcome);
                }
            }
            XswdHandlerInput::Event(None) => {
                invalidate_observed_xswd_states(&xswd_sessions, &observed_states).await;
                if let Some(callback) = active.take() {
                    callback.fail(XSWD_HANDLER_CLOSED);
                }
                fail_deferred_xswd_events(&mut deferred, XSWD_HANDLER_CLOSED);
                break;
            }
            XswdHandlerInput::Event(Some(event)) => {
                receive_burst += 1;
                info!("Received XSWD event: {}", xswd_event_name(&event));
                track_xswd_state(&mut observed_states, xswd_event_state(&event));
                match event {
                    XSWDEvent::CancelRequest(state, callback) => {
                        let cancelled_deferred_admission =
                            cancel_deferred_xswd_decisions(&mut deferred, &state);
                        let cancels_active = active
                            .as_ref()
                            .is_some_and(|active| active.is_decision_for(&state));
                        let cancelled_admission = cancelled_deferred_admission
                            || (cancels_active
                                && active
                                    .as_ref()
                                    .is_some_and(ActiveXswdCallback::is_application_admission));
                        if cancelled_admission {
                            xswd_sessions.lock().await.invalidate_state(&state);
                        }
                        if cancels_active {
                            if let Some(active) = active.take() {
                                active.cancel();
                            }
                        }
                        acknowledge_cancelled_request(callback);
                        let notification = prepare_xswd_lifecycle_notification(
                            state,
                            XswdNotificationKind::CancelRequest,
                            cancelled_admission,
                            &xswd_sessions,
                        )
                        .await;
                        if let Some(notification) = notification {
                            if cancels_active {
                                active = Some(notification.start(
                                    &cancel_request_dart_callback,
                                    &app_disconnect_dart_callback,
                                ));
                                receive_burst = 0;
                            } else if deferred.len() < MAX_DEFERRED_XSWD_EVENTS {
                                deferred.push_back(DeferredXswdEvent::Notification(notification));
                            } else {
                                record_abandoned_xswd_notification(
                                    notification.kind,
                                    XSWD_REQUEST_QUEUE_FULL,
                                );
                            }
                        }
                    }
                    XSWDEvent::AppDisconnect(state) => {
                        cancel_deferred_xswd_decisions(&mut deferred, &state);
                        let disconnects_active = active
                            .as_ref()
                            .is_some_and(|active| active.is_decision_for(&state));
                        xswd_sessions.lock().await.invalidate_state(&state);
                        if disconnects_active {
                            if let Some(active) = active.take() {
                                active.cancel();
                            }
                        }
                        let notification = prepare_xswd_lifecycle_notification(
                            state,
                            XswdNotificationKind::AppDisconnect,
                            false,
                            &xswd_sessions,
                        )
                        .await;
                        if disconnects_active {
                            if let Some(notification) = notification {
                                active = Some(notification.start(
                                    &cancel_request_dart_callback,
                                    &app_disconnect_dart_callback,
                                ));
                                receive_burst = 0;
                            }
                        } else if let Some(notification) = notification {
                            if let Some(next) =
                                defer_xswd_disconnect(&mut deferred, active.as_ref(), notification)
                            {
                                if let Some(active_admission) = active
                                    .as_ref()
                                    .filter(|active| active.is_application_admission())
                                {
                                    let state = Arc::clone(&active_admission.state);
                                    xswd_sessions.lock().await.invalidate_state(&state);
                                }
                                if let Some(callback) = active.take() {
                                    callback.fail(XSWD_HANDLER_OVERLOADED);
                                }
                                active = Some(next.start(
                                    &cancel_request_dart_callback,
                                    &app_disconnect_dart_callback,
                                ));
                                receive_burst = 0;
                            }
                        }
                    }
                    event => defer_xswd_decision(&mut deferred, event),
                }
            }
        }
    }
}

enum XswdHandlerInput {
    Callback(XswdActiveCallbackOutcome),
    Event(Option<XSWDEvent>),
}

pub(super) enum DeferredXswdEvent {
    Raw(XSWDEvent),
    Notification(PreparedXswdNotification),
}

pub(super) enum PreparedXswdEvent {
    Decision(PendingXswdDecision),
    Lifecycle(XswdLifecycleEvent),
    Handled,
}

pub(super) enum XswdLifecycleEvent {
    CancelRequest(Arc<AppState>, Sender<Result<(), Error>>),
    AppDisconnect(Arc<AppState>),
}

impl XswdLifecycleEvent {
    pub(super) fn acknowledge(self) -> (Arc<AppState>, XswdNotificationKind) {
        match self {
            Self::CancelRequest(state, callback) => {
                acknowledge_cancelled_request(callback);
                (state, XswdNotificationKind::CancelRequest)
            }
            Self::AppDisconnect(state) => (state, XswdNotificationKind::AppDisconnect),
        }
    }
}

pub(super) struct PendingXswdDecision {
    pub(super) state: Arc<AppState>,
    pub(super) future: DartFnFuture<XswdDecisionCallbackOutcome>,
    pub(super) response: PendingXswdResponse,
    pub(super) is_application_admission: bool,
}

#[derive(Clone, Copy)]
pub(super) enum XswdNotificationKind {
    CancelRequest,
    AppDisconnect,
}

pub(super) struct PreparedXswdNotification {
    pub(super) state: Arc<AppState>,
    pub(super) summary: XswdRequestSummary,
    pub(super) kind: XswdNotificationKind,
    pub(super) cancelled_application_admission: bool,
}

pub(super) struct ActiveXswdCallback {
    pub(super) state: Arc<AppState>,
    pub(super) kind: ActiveXswdCallbackKind,
    pub(super) future: DartFnFuture<XswdActiveCallbackOutcome>,
}

pub(super) enum ActiveXswdCallbackKind {
    Decision {
        response: PendingXswdResponse,
        is_application_admission: bool,
    },
    Notification(XswdNotificationKind),
}

pub(super) enum XswdActiveCallbackOutcome {
    Decision(XswdDecisionCallbackOutcome),
    Notification(XswdNotificationCallbackOutcome),
}

pub(super) enum PendingXswdResponse {
    Permission(Sender<Result<PermissionResult, Error>>),
    Prefetch {
        permissions: XSWDPrefetchPermissions,
        callback: Sender<Result<IndexMap<String, Permission>, Error>>,
    },
}

impl PendingXswdDecision {
    #[cfg(test)]
    pub(super) async fn complete(self) {
        let PendingXswdDecision {
            future, response, ..
        } = self;
        response.complete(future.await);
    }

    pub(super) fn into_active(self) -> ActiveXswdCallback {
        let Self {
            state,
            future,
            response,
            is_application_admission,
        } = self;
        ActiveXswdCallback {
            state,
            kind: ActiveXswdCallbackKind::Decision {
                response,
                is_application_admission,
            },
            future: Box::pin(async move { XswdActiveCallbackOutcome::Decision(future.await) }),
        }
    }
}

impl PreparedXswdNotification {
    pub(super) fn start<Cancel, Disconnect>(
        self,
        cancel_request_dart_callback: &Cancel,
        app_disconnect_dart_callback: &Disconnect,
    ) -> ActiveXswdCallback
    where
        Cancel: Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>,
        Disconnect: Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>,
    {
        let future = match self.kind {
            XswdNotificationKind::CancelRequest => {
                cancel_request_dart_callback(self.summary, self.cancelled_application_admission)
            }
            XswdNotificationKind::AppDisconnect => app_disconnect_dart_callback(self.summary),
        };
        ActiveXswdCallback {
            state: self.state,
            kind: ActiveXswdCallbackKind::Notification(self.kind),
            future: Box::pin(async move { XswdActiveCallbackOutcome::Notification(future.await) }),
        }
    }

    #[cfg(test)]
    pub(super) async fn complete<Cancel, Disconnect>(
        self,
        cancel_request_dart_callback: &Cancel,
        app_disconnect_dart_callback: &Disconnect,
    ) where
        Cancel: Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>,
        Disconnect: Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>,
    {
        let active = self.start(cancel_request_dart_callback, app_disconnect_dart_callback);
        let ActiveXswdCallback { kind, future, .. } = active;
        ActiveXswdCallback::complete_kind(kind, future.await);
    }
}

impl ActiveXswdCallback {
    pub(super) fn is_decision_for(&self, state: &Arc<AppState>) -> bool {
        matches!(self.kind, ActiveXswdCallbackKind::Decision { .. })
            && Arc::ptr_eq(&self.state, state)
    }

    pub(super) fn is_application_admission(&self) -> bool {
        matches!(
            self.kind,
            ActiveXswdCallbackKind::Decision {
                is_application_admission: true,
                ..
            }
        )
    }

    pub(super) fn is_disconnect_for(&self, state: &Arc<AppState>) -> bool {
        matches!(
            self.kind,
            ActiveXswdCallbackKind::Notification(XswdNotificationKind::AppDisconnect)
        ) && Arc::ptr_eq(&self.state, state)
    }

    pub(super) fn complete(self, outcome: XswdActiveCallbackOutcome) {
        Self::complete_kind(self.kind, outcome);
    }

    pub(super) fn complete_kind(kind: ActiveXswdCallbackKind, outcome: XswdActiveCallbackOutcome) {
        match (kind, outcome) {
            (
                ActiveXswdCallbackKind::Decision { response, .. },
                XswdActiveCallbackOutcome::Decision(outcome),
            ) => response.complete(outcome),
            (
                ActiveXswdCallbackKind::Notification(kind),
                XswdActiveCallbackOutcome::Notification(outcome),
            ) => record_xswd_notification_outcome(kind, outcome),
            _ => debug!("XSWD_CALLBACK_OUTCOME_KIND_MISMATCH"),
        }
    }

    pub(super) fn cancel(self) {
        match self.kind {
            ActiveXswdCallbackKind::Decision { response, .. } => {
                response.fail(XSWD_REQUEST_CANCELLED)
            }
            ActiveXswdCallbackKind::Notification(kind) => {
                record_abandoned_xswd_notification(kind, XSWD_REQUEST_CANCELLED)
            }
        }
    }

    pub(super) fn fail(self, code: &'static str) {
        match self.kind {
            ActiveXswdCallbackKind::Decision { response, .. } => response.fail(code),
            ActiveXswdCallbackKind::Notification(kind) => {
                record_abandoned_xswd_notification(kind, code)
            }
        }
    }
}

impl PendingXswdResponse {
    pub(super) fn complete(self, outcome: XswdDecisionCallbackOutcome) {
        match self {
            Self::Permission(callback) => handle_permission_outcome(outcome, callback),
            Self::Prefetch {
                permissions,
                callback,
            } => handle_prefetch_permissions_outcome(outcome, permissions, callback),
        }
    }

    pub(super) fn fail(self, code: &'static str) {
        match self {
            Self::Permission(callback) => send_permission_failure(callback, code),
            Self::Prefetch { callback, .. } => send_prefetch_failure(callback, code),
        }
    }
}

pub(super) fn cancel_deferred_xswd_decisions(
    deferred: &mut VecDeque<DeferredXswdEvent>,
    state: &Arc<AppState>,
) -> bool {
    let mut cancelled_application_admission = false;
    let mut retained = VecDeque::with_capacity(deferred.len());
    while let Some(event) = deferred.pop_front() {
        match event {
            DeferredXswdEvent::Raw(XSWDEvent::RequestApplication(event_state, callback))
                if Arc::ptr_eq(&event_state, state) =>
            {
                cancelled_application_admission = true;
                send_permission_failure(callback, XSWD_REQUEST_CANCELLED);
            }
            DeferredXswdEvent::Raw(XSWDEvent::RequestPermission(event_state, _, callback))
                if Arc::ptr_eq(&event_state, state) =>
            {
                send_permission_failure(callback, XSWD_REQUEST_CANCELLED);
            }
            DeferredXswdEvent::Raw(XSWDEvent::PrefetchPermissions(event_state, _, callback))
                if Arc::ptr_eq(&event_state, state) =>
            {
                send_prefetch_failure(callback, XSWD_REQUEST_CANCELLED);
            }
            event => retained.push_back(event),
        }
    }
    *deferred = retained;
    cancelled_application_admission
}

pub(super) fn defer_xswd_decision(deferred: &mut VecDeque<DeferredXswdEvent>, event: XSWDEvent) {
    if deferred.len() < MAX_DEFERRED_XSWD_EVENTS {
        deferred.push_back(DeferredXswdEvent::Raw(event));
        return;
    }

    match event {
        XSWDEvent::RequestApplication(_, callback)
        | XSWDEvent::RequestPermission(_, _, callback) => {
            send_permission_failure(callback, XSWD_REQUEST_QUEUE_FULL);
        }
        XSWDEvent::PrefetchPermissions(_, _, callback) => {
            send_prefetch_failure(callback, XSWD_REQUEST_QUEUE_FULL);
        }
        XSWDEvent::AppDisconnect(_) => debug!("XSWD_UNPREPARED_DISCONNECT_DROPPED"),
        XSWDEvent::CancelRequest(_, callback) => acknowledge_cancelled_request(callback),
    }
}

pub(super) fn defer_xswd_disconnect(
    deferred: &mut VecDeque<DeferredXswdEvent>,
    active: Option<&ActiveXswdCallback>,
    notification: PreparedXswdNotification,
) -> Option<PreparedXswdNotification> {
    let already_deferred = active
        .is_some_and(|active| active.is_disconnect_for(&notification.state))
        || deferred.iter().any(|event| {
            matches!(
                event,
                DeferredXswdEvent::Notification(PreparedXswdNotification {
                    state,
                    kind: XswdNotificationKind::AppDisconnect,
                    ..
                }) if Arc::ptr_eq(state, &notification.state)
            )
        });
    if already_deferred {
        return None;
    }

    if deferred.len() >= MAX_DEFERRED_XSWD_EVENTS {
        if let Some(index) = deferred.iter().position(is_xswd_decision_event) {
            if let Some(event) = deferred.remove(index) {
                fail_deferred_xswd_event(event, XSWD_REQUEST_QUEUE_FULL);
            }
        } else {
            debug!("XSWD_DISCONNECT_QUEUE_SATURATED");
            let next = deferred.pop_front().and_then(|event| match event {
                DeferredXswdEvent::Notification(notification) => Some(notification),
                DeferredXswdEvent::Raw(_) => None,
            });
            deferred.push_back(DeferredXswdEvent::Notification(notification));
            return next;
        }
    }

    if deferred.len() < MAX_DEFERRED_XSWD_EVENTS {
        deferred.push_back(DeferredXswdEvent::Notification(notification));
    }
    None
}

pub(super) fn is_xswd_decision_event(event: &DeferredXswdEvent) -> bool {
    matches!(
        event,
        DeferredXswdEvent::Raw(
            XSWDEvent::RequestApplication(_, _)
                | XSWDEvent::RequestPermission(_, _, _)
                | XSWDEvent::PrefetchPermissions(_, _, _)
        )
    )
}

pub(super) fn fail_deferred_xswd_events(
    deferred: &mut VecDeque<DeferredXswdEvent>,
    code: &'static str,
) {
    while let Some(event) = deferred.pop_front() {
        fail_deferred_xswd_event(event, code);
    }
}

pub(super) fn fail_deferred_xswd_event(event: DeferredXswdEvent, code: &'static str) {
    match event {
        DeferredXswdEvent::Raw(
            XSWDEvent::RequestApplication(_, callback)
            | XSWDEvent::RequestPermission(_, _, callback),
        ) => {
            send_permission_failure(callback, code);
        }
        DeferredXswdEvent::Raw(XSWDEvent::PrefetchPermissions(_, _, callback)) => {
            send_prefetch_failure(callback, code);
        }
        DeferredXswdEvent::Raw(XSWDEvent::CancelRequest(_, callback)) => {
            acknowledge_cancelled_request(callback)
        }
        DeferredXswdEvent::Raw(XSWDEvent::AppDisconnect(_)) => {
            debug!("XSWD_UNPREPARED_DISCONNECT_DROPPED")
        }
        DeferredXswdEvent::Notification(notification) => {
            record_abandoned_xswd_notification(notification.kind, code)
        }
    }
}

pub(super) fn send_permission_failure(
    callback: Sender<Result<PermissionResult, Error>>,
    code: &'static str,
) {
    if callback.send(Err(anyhow!(code))).is_err() {
        debug!("XSWD_PERMISSION_FAILURE_RESPONSE_DROPPED:{code}");
    }
}

pub(super) fn send_prefetch_failure(
    callback: Sender<Result<IndexMap<String, Permission>, Error>>,
    code: &'static str,
) {
    if callback.send(Err(anyhow!(code))).is_err() {
        debug!("XSWD_PREFETCH_FAILURE_RESPONSE_DROPPED:{code}");
    }
}

pub(super) fn acknowledge_cancelled_request(callback: Sender<Result<(), Error>>) {
    if callback.send(Ok(())).is_err() {
        debug!("XSWD_CANCEL_RESPONSE_DROPPED");
    }
}

pub(super) fn xswd_event_state(event: &XSWDEvent) -> &Arc<AppState> {
    match event {
        XSWDEvent::RequestApplication(state, _)
        | XSWDEvent::RequestPermission(state, _, _)
        | XSWDEvent::PrefetchPermissions(state, _, _)
        | XSWDEvent::CancelRequest(state, _)
        | XSWDEvent::AppDisconnect(state) => state,
    }
}

pub(super) fn track_xswd_state(observed: &mut Vec<Weak<AppState>>, state: &Arc<AppState>) {
    observed.retain(|registered| registered.strong_count() > 0);
    let state_ref = Arc::downgrade(state);
    if !observed
        .iter()
        .any(|registered| Weak::ptr_eq(registered, &state_ref))
    {
        observed.push(state_ref);
    }
}

pub(super) async fn invalidate_observed_xswd_states(
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    observed: &[Weak<AppState>],
) {
    let states = observed
        .iter()
        .filter_map(Weak::upgrade)
        .collect::<Vec<_>>();
    let mut registry = xswd_sessions.lock().await;
    for state in states {
        registry.invalidate_state(&state);
    }
}
