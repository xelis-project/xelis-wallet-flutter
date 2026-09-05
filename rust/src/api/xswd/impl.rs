use indexmap::IndexMap;
use std::{
    collections::{HashMap, VecDeque},
    sync::{
        atomic::{AtomicU64, Ordering},
        Arc, Weak,
    },
};

use anyhow::{anyhow, bail, Error, Result};
pub use flutter_rust_bridge::DartFnFuture;
use log::{debug, error, info};
pub use xelis_common::api::wallet::XSWDPrefetchPermissions;
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
pub use xelis_common::tokio::sync::oneshot::Sender;
use xelis_common::tokio::{select, spawn_task};
#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
use xelis_wallet::api::APIServer;
pub use xelis_wallet::api::AppState;
use xelis_wallet::api::{Permission, PermissionResult};
pub use xelis_wallet::wallet::XSWDEvent;

use crate::api::{
    error::{NativeXelisError, NativeXelisErrorCode},
    models::xswd_dtos::{
        AppInfo, ApplicationDataRelayer, EncryptionMode, NativeXswdPayload,
        NativeXswdProjectionLimits, PermissionPolicy, UserPermissionDecision,
        XswdDecisionCallbackOutcome, XswdNotificationCallbackOutcome, XswdPayloadProjectionError,
        XswdRequestSummary, XswdRequestType,
    },
    wallet::XelisWallet,
};
use xelis_wallet::api::{
    ApplicationData, ApplicationDataRelayer as CoreApplicationDataRelayer,
    EncryptionMode as CoreEncryptionMode,
};

const MAX_DEFERRED_XSWD_EVENTS: usize = 64;
const MAX_XSWD_RECEIVE_BURST: usize = 16;
const XSWD_HANDLER_CLOSED: &str = "XSWD_HANDLER_CLOSED";
const XSWD_HANDLER_OVERLOADED: &str = "XSWD_HANDLER_OVERLOADED";
const XSWD_REQUEST_CANCELLED: &str = "XSWD_REQUEST_CANCELLED";
const XSWD_REQUEST_QUEUE_FULL: &str = "XSWD_REQUEST_QUEUE_FULL";
const XSWD_SESSION_REFERENCE_EXHAUSTED: &str = "XSWD_SESSION_REFERENCE_EXHAUSTED";
const XSWD_SESSION_REFERENCE_INVALID: &str = "XSWD_SESSION_REFERENCE_INVALID";
static NEXT_XSWD_SESSION_REFERENCE: AtomicU64 = AtomicU64::new(1);

#[derive(Default)]
#[flutter_rust_bridge::frb(ignore)]
pub(crate) struct XswdSessionRegistry {
    sessions: HashMap<u64, Weak<AppState>>,
}

impl XswdSessionRegistry {
    fn register(&mut self, state: &Arc<AppState>) -> Result<u64> {
        self.remove_dead();
        let state_ref = Arc::downgrade(state);
        if let Some((session_ref, _)) = self
            .sessions
            .iter()
            .find(|(_, registered)| Weak::ptr_eq(registered, &state_ref))
        {
            return Ok(*session_ref);
        }

        let session_ref = NEXT_XSWD_SESSION_REFERENCE
            .fetch_update(Ordering::Relaxed, Ordering::Relaxed, |current| {
                current.checked_add(1)
            })
            .map_err(|_| anyhow!(XSWD_SESSION_REFERENCE_EXHAUSTED))?;
        self.sessions.insert(session_ref, state_ref);
        Ok(session_ref)
    }

    fn resolve(&mut self, session_ref: u64) -> Option<Arc<AppState>> {
        self.remove_dead();
        self.sessions.get(&session_ref).and_then(Weak::upgrade)
    }

    fn invalidate_state(&mut self, state: &Arc<AppState>) {
        let state_ref = Arc::downgrade(state);
        self.sessions
            .retain(|_, registered| !Weak::ptr_eq(registered, &state_ref));
    }

    fn clear(&mut self) {
        self.sessions.clear();
    }

    fn remove_dead(&mut self) {
        self.sessions.retain(|_, state| state.strong_count() > 0);
    }
}
#[allow(async_fn_in_trait)]
pub trait XSWD {
    async fn start_xswd(
        &self,
        projection_limits: NativeXswdProjectionLimits,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()>;

    async fn stop_xswd(&self) -> Result<()>;

    async fn is_xswd_running(&self) -> bool;

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>>;

    async fn modify_application_permissions(
        &self,
        session_ref: u64,
        permissions: HashMap<String, PermissionPolicy>,
    ) -> std::result::Result<(), NativeXelisError>;

    async fn close_application_session(
        &self,
        session_ref: u64,
    ) -> std::result::Result<(), NativeXelisError>;

    async fn add_xswd_relayer(
        &self,
        app_data: ApplicationDataRelayer,
        projection_limits: NativeXswdProjectionLimits,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()>;
}

impl XSWD for XelisWallet {
    async fn start_xswd(
        &self,
        projection_limits: NativeXswdProjectionLimits,
        _cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()> {
        let projection_limits = projection_limits
            .validate()
            .map_err(|error| anyhow!(error.code()))?;
        #[cfg(target_arch = "wasm32")]
        {
            let _ = (
                projection_limits,
                _cancel_request_dart_callback,
                _request_application_dart_callback,
                _request_permission_dart_callback,
                _request_prefetch_permissions_dart_callback,
                _app_disconnect_dart_callback,
            );
            bail!("Local XSWD server not supported on web. Use relay mode instead.");
        }

        #[cfg(all(not(target_arch = "wasm32"), not(feature = "api_server")))]
        {
            let _ = (
                projection_limits,
                _cancel_request_dart_callback,
                _request_application_dart_callback,
                _request_permission_dart_callback,
                _request_prefetch_permissions_dart_callback,
                _app_disconnect_dart_callback,
            );
            bail!("Local XSWD server not enabled in this build. Use relay mode instead.");
        }

        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            match self.get_wallet().enable_xswd().await {
                Ok(Some(receiver)) => {
                    let xswd_sessions = Arc::clone(self.xswd_sessions());
                    spawn_task("xswd_handler", async move {
                        xswd_handler_with_registry(
                            receiver,
                            xswd_sessions,
                            projection_limits,
                            _cancel_request_dart_callback,
                            _request_application_dart_callback,
                            _request_permission_dart_callback,
                            _request_prefetch_permissions_dart_callback,
                            _app_disconnect_dart_callback,
                        )
                        .await;
                    });
                }
                Ok(None) => {
                    // XSWD server is already running, this is not an error
                }
                Err(e) => bail!("Error while enabling XSWD Server: {}", e),
            };
            Ok(())
        }
    }

    async fn stop_xswd(&self) -> Result<()> {
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let api_server = {
                let mut api_server = self.get_wallet().get_api_server().lock().await;
                api_server.take()
            };
            if let Some(api_server) = api_server {
                api_server.stop().await;
            }
        }

        let relayer = {
            let mut relayer = self.get_wallet().xswd_relayer().lock().await;
            relayer.take()
        };
        if let Some(relayer) = relayer {
            relayer.close().await;
        }
        self.xswd_sessions().lock().await.clear();
        Ok(())
    }

    async fn is_xswd_running(&self) -> bool {
        // Check if local XSWD server is running (native only)
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let lock = self.get_wallet().get_api_server().lock().await;
            if lock.is_some() {
                return true;
            }
            drop(lock);
        }

        // Check if there are any relayer connections (works on both native and web)
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let apps = relayer.applications().read().await;
            return !apps.is_empty();
        }

        false
    }

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>> {
        let mut apps = Vec::new();

        // Get applications from XSWD server (local connections - native only)
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let lock = self.get_wallet().get_api_server().lock().await;
            if let Some(api_server) = lock.as_ref() {
                match api_server {
                    APIServer::XSWD(xswd) => {
                        let applications = xswd.get_handler().get_applications().read().await;
                        for (_, app) in applications.iter() {
                            let app_info =
                                create_app_info(self.xswd_sessions(), app, false).await?;
                            apps.push(app_info);
                        }
                    }
                    _ => {}
                }
            }
        }

        // Get applications from XSWD relayer (remote connections - works on both native and web)
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let relayer_apps = relayer.applications().read().await;
            for (app, _) in relayer_apps.iter() {
                let app_info = create_app_info(self.xswd_sessions(), app, true).await?;
                apps.push(app_info);
            }
        }

        Ok(apps)
    }

    async fn modify_application_permissions(
        &self,
        session_ref: u64,
        permissions: HashMap<String, PermissionPolicy>,
    ) -> std::result::Result<(), NativeXelisError> {
        let target = self
            .xswd_sessions()
            .lock()
            .await
            .resolve(session_ref)
            .ok_or_else(invalid_xswd_session_reference)?;

        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let lock = self.get_wallet().get_api_server().lock().await;
            if let Some(APIServer::XSWD(xswd)) = lock.as_ref() {
                let applications = xswd.get_handler().get_applications().read().await;
                if let Some((_, app)) = applications
                    .iter()
                    .find(|(_, app)| Arc::ptr_eq(app, &target))
                {
                    return modify_app_permissions(app, &permissions)
                        .await
                        .map_err(xswd_permission_update_failed);
                }
            }
        }

        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let relayer_apps = relayer.applications().read().await;
            if let Some((app, _)) = relayer_apps
                .iter()
                .find(|(app, _)| Arc::ptr_eq(app, &target))
            {
                return modify_app_permissions(app, &permissions)
                    .await
                    .map_err(xswd_permission_update_failed);
            }
        }

        Err(invalid_xswd_session_reference())
    }

    async fn close_application_session(
        &self,
        session_ref: u64,
    ) -> std::result::Result<(), NativeXelisError> {
        let target = self
            .xswd_sessions()
            .lock()
            .await
            .resolve(session_ref)
            .ok_or_else(invalid_xswd_session_reference)?;

        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let lock = self.get_wallet().get_api_server().lock().await;
            if let Some(APIServer::XSWD(xswd)) = lock.as_ref() {
                let session = {
                    let applications = xswd.get_handler().get_applications().read().await;
                    applications
                        .iter()
                        .find(|(_, app)| Arc::ptr_eq(app, &target))
                        .map(|(session, _)| session.clone())
                };
                if let Some(session) = session {
                    // The server loop owns removal and XSWD::on_close. Removing
                    // this entry here would make that callback observe no app,
                    // losing CancelRequest/AppDisconnect and registry cleanup.
                    session
                        .close(None)
                        .await
                        .map_err(|error| xswd_session_close_failed(error.into()))?;
                    return Ok(());
                }
            }
        }

        let relayer = { self.get_wallet().xswd_relayer().lock().await.clone() };
        if let Some(relayer) = relayer {
            let target_connection = {
                let relayer_apps = relayer.applications().read().await;
                relayer_apps
                    .iter()
                    .find(|(app, _)| Arc::ptr_eq(app, &target))
                    .map(|(app, client)| (app.clone(), client.clone()))
            };
            if let Some((app, client)) = target_connection {
                // Poll transport shutdown before lifecycle cleanup, then drive
                // both concurrently. This lets on_close cancel an active Dart
                // decision immediately while client.close stops the socket
                // even when the disconnect notification is still pending.
                // The client task's second on_close is idempotent because the
                // exact map entry has already been removed by the first one.
                // Keep the wallet-level relayer mutex unlocked: callbacks may
                // read the live application list.
                futures::join!(client.close(), relayer.on_close(app));
                return Ok(());
            }
        }

        Err(invalid_xswd_session_reference())
    }

    async fn add_xswd_relayer(
        &self,
        app_data: ApplicationDataRelayer,
        projection_limits: NativeXswdProjectionLimits,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()> {
        let projection_limits = projection_limits
            .validate()
            .map_err(|error| anyhow!(error.code()))?;
        let encryption_mode = convert_encryption_mode(app_data.encryption_mode)?;

        // Use serde to construct ApplicationData since fields are private
        let app_data_json = serde_json::json!({
            "id": app_data.id,
            "name": app_data.name,
            "description": app_data.description,
            "url": app_data.url,
            "permissions": app_data.permissions,
        });
        let core_app_info: ApplicationData = serde_json::from_value(app_data_json)?;

        let core_app_data = CoreApplicationDataRelayer {
            app_data: core_app_info,
            relayer: app_data.relayer,
            encryption_mode,
        };

        // Initialize relayer infrastructure (without adding application yet)
        match self.get_wallet().init_xswd_relayer().await? {
            Some(receiver) => {
                info!("XSWD relayer created new channel - spawning event handler");
                let xswd_sessions = Arc::clone(self.xswd_sessions());
                // Spawn handler BEFORE adding application so it can respond to events
                spawn_task(
                    "xswd-relayer-handler",
                    xswd_handler_with_registry(
                        receiver,
                        xswd_sessions,
                        projection_limits,
                        cancel_request_dart_callback,
                        request_application_dart_callback,
                        request_permission_dart_callback,
                        request_prefetch_permissions_dart_callback,
                        app_disconnect_dart_callback,
                    ),
                );

                // Now add application - handler is ready to process RequestApplication event
                self.get_wallet()
                    .add_xswd_relayer_application(core_app_data)
                    .await?;
            }
            None => {
                info!("XSWD relayer using existing event handler from startXSWD");
                // Handler already running, safe to add application
                self.get_wallet()
                    .add_xswd_relayer_application(core_app_data)
                    .await?;
            }
        }
        Ok(())
    }
}

fn permission_from_policy(policy: &PermissionPolicy) -> Permission {
    match policy {
        PermissionPolicy::Accept => Permission::Allow,
        PermissionPolicy::Reject => Permission::Reject,
        PermissionPolicy::Ask => Permission::Ask,
    }
}

fn invalid_xswd_session_reference() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::Conflict,
        XSWD_SESSION_REFERENCE_INVALID,
        "The XSWD session reference is stale, detached, or belongs to another wallet",
    )
}

fn xswd_permission_update_failed(error: Error) -> NativeXelisError {
    NativeXelisError::xelis_wallet(
        NativeXelisErrorCode::OperationFailed,
        "XSWD_PERMISSION_UPDATE_FAILED",
        format!("{error:#}"),
    )
}

#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
fn xswd_session_close_failed(error: Error) -> NativeXelisError {
    NativeXelisError::xelis_wallet(
        NativeXelisErrorCode::OperationFailed,
        "XSWD_SESSION_CLOSE_FAILED",
        format!("{error:#}"),
    )
}

fn apply_permission_updates(
    current: &mut IndexMap<String, Permission>,
    updates: &HashMap<String, PermissionPolicy>,
) -> Result<()> {
    if updates.keys().any(|key| key.starts_with("wallet.")) {
        bail!("Prefixed XSWD permission names are unsupported");
    }
    if updates.keys().any(|key| !current.contains_key(key)) {
        bail!("XSWD permission not found");
    }

    for (key, policy) in updates {
        let permission = current
            .get_mut(key)
            .expect("XSWD permission was validated before applying updates");
        *permission = permission_from_policy(policy);
    }

    Ok(())
}

async fn modify_app_permissions(
    app: &AppState,
    permissions: &HashMap<String, PermissionPolicy>,
) -> Result<()> {
    info!("Modifying XSWD application permissions");
    debug!("Updating {} XSWD permission policies", permissions.len());

    let mut current = app.get_permissions().lock().await;
    apply_permission_updates(&mut current, permissions)
}

fn encryption_key(key: Vec<u8>) -> Result<[u8; 32]> {
    let length = key.len();
    key.try_into().map_err(|_| {
        anyhow!("Invalid XSWD relayer encryption key length: expected 32 bytes, got {length}")
    })
}

fn convert_encryption_mode(mode: Option<EncryptionMode>) -> Result<Option<CoreEncryptionMode>> {
    mode.map(|mode| match mode {
        EncryptionMode::Aes { key } => Ok(CoreEncryptionMode::AES {
            key: encryption_key(key)?,
        }),
        EncryptionMode::Chacha20Poly1305 { key } => Ok(CoreEncryptionMode::Chacha20Poly1305 {
            key: encryption_key(key)?,
        }),
    })
    .transpose()
}

#[flutter_rust_bridge::frb(ignore)]
pub async fn xswd_handler(
    receiver: UnboundedReceiver<XSWDEvent>,
    projection_limits: NativeXswdProjectionLimits,
    cancel_request_dart_callback: impl Fn(
        XswdRequestSummary,
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
    xswd_handler_with_registry(
        receiver,
        Arc::new(xelis_common::tokio::sync::Mutex::new(
            XswdSessionRegistry::default(),
        )),
        projection_limits,
        cancel_request_dart_callback,
        request_application_dart_callback,
        request_permission_dart_callback,
        request_prefetch_permissions_dart_callback,
        app_disconnect_dart_callback,
    )
    .await;
}

async fn xswd_handler_with_registry(
    mut receiver: UnboundedReceiver<XSWDEvent>,
    xswd_sessions: Arc<xelis_common::tokio::sync::Mutex<XswdSessionRegistry>>,
    projection_limits: NativeXswdProjectionLimits,
    cancel_request_dart_callback: impl Fn(
        XswdRequestSummary,
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
    let mut pending = None;
    let mut receive_burst = 0;

    loop {
        if pending.is_none() {
            let event = if let Some(event) = deferred.pop_front() {
                event
            } else {
                match receiver.recv().await {
                    Some(event) => {
                        info!("Received XSWD event: {}", xswd_event_name(&event));
                        event
                    }
                    None => break,
                }
            };

            match prepare_xswd_event(
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
                    pending = Some(decision);
                    receive_burst = 0;
                }
                PreparedXswdEvent::Lifecycle(event) => {
                    handle_xswd_lifecycle_event(
                        event,
                        &xswd_sessions,
                        &cancel_request_dart_callback,
                        &app_disconnect_dart_callback,
                    )
                    .await;
                }
                PreparedXswdEvent::Handled => {}
            }
            continue;
        }

        let input = {
            let Some(decision) = pending.as_mut() else {
                continue;
            };
            if receive_burst >= MAX_XSWD_RECEIVE_BURST {
                receive_burst = 0;
                select! {
                    biased;
                    outcome = decision.future.as_mut() => XswdHandlerInput::Decision(outcome),
                    event = receiver.recv() => XswdHandlerInput::Event(event),
                }
            } else {
                select! {
                    biased;
                    event = receiver.recv() => XswdHandlerInput::Event(event),
                    outcome = decision.future.as_mut() => XswdHandlerInput::Decision(outcome),
                }
            }
        };

        match input {
            XswdHandlerInput::Decision(outcome) => {
                receive_burst = 0;
                if let Some(decision) = pending.take() {
                    decision.complete_with(outcome);
                }
            }
            XswdHandlerInput::Event(None) => {
                if let Some(decision) = pending.take() {
                    decision.fail(XSWD_HANDLER_CLOSED);
                }
                fail_deferred_xswd_decisions(&mut deferred, XSWD_HANDLER_CLOSED);
                break;
            }
            XswdHandlerInput::Event(Some(event)) => {
                receive_burst += 1;
                info!("Received XSWD event: {}", xswd_event_name(&event));
                match event {
                    XSWDEvent::CancelRequest(state, callback) => {
                        cancel_deferred_xswd_decisions(&mut deferred, &state);
                        let cancels_active = pending
                            .as_ref()
                            .is_some_and(|decision| Arc::ptr_eq(&decision.state, &state));
                        if cancels_active {
                            if let Some(decision) = pending.take() {
                                decision.cancel();
                            }
                            handle_xswd_lifecycle_event(
                                XswdLifecycleEvent::CancelRequest(state, callback),
                                &xswd_sessions,
                                &cancel_request_dart_callback,
                                &app_disconnect_dart_callback,
                            )
                            .await;
                        } else {
                            acknowledge_cancelled_request(callback);
                        }
                    }
                    XSWDEvent::AppDisconnect(state) => {
                        cancel_deferred_xswd_decisions(&mut deferred, &state);
                        let disconnects_active = pending
                            .as_ref()
                            .is_some_and(|decision| Arc::ptr_eq(&decision.state, &state));
                        if disconnects_active {
                            if let Some(decision) = pending.take() {
                                decision.cancel();
                            }
                            handle_xswd_lifecycle_event(
                                XswdLifecycleEvent::AppDisconnect(state),
                                &xswd_sessions,
                                &cancel_request_dart_callback,
                                &app_disconnect_dart_callback,
                            )
                            .await;
                        } else if let Some(state) = defer_xswd_disconnect(&mut deferred, state) {
                            if let Some(decision) = pending.take() {
                                decision.fail(XSWD_HANDLER_OVERLOADED);
                            }
                            handle_xswd_lifecycle_event(
                                XswdLifecycleEvent::AppDisconnect(state),
                                &xswd_sessions,
                                &cancel_request_dart_callback,
                                &app_disconnect_dart_callback,
                            )
                            .await;
                        }
                    }
                    event => defer_xswd_decision(&mut deferred, event),
                }
            }
        }
    }
}

enum XswdHandlerInput {
    Decision(XswdDecisionCallbackOutcome),
    Event(Option<XSWDEvent>),
}

enum PreparedXswdEvent {
    Decision(PendingXswdDecision),
    Lifecycle(XswdLifecycleEvent),
    Handled,
}

enum XswdLifecycleEvent {
    CancelRequest(Arc<AppState>, Sender<Result<(), Error>>),
    AppDisconnect(Arc<AppState>),
}

struct PendingXswdDecision {
    state: Arc<AppState>,
    future: DartFnFuture<XswdDecisionCallbackOutcome>,
    response: PendingXswdResponse,
}

enum PendingXswdResponse {
    Permission(Sender<Result<PermissionResult, Error>>),
    Prefetch {
        permissions: XSWDPrefetchPermissions,
        callback: Sender<Result<IndexMap<String, Permission>, Error>>,
    },
}

impl PendingXswdDecision {
    #[cfg(test)]
    async fn complete(self) {
        let PendingXswdDecision {
            future, response, ..
        } = self;
        response.complete(future.await);
    }

    fn complete_with(self, outcome: XswdDecisionCallbackOutcome) {
        self.response.complete(outcome);
    }

    fn cancel(self) {
        self.fail(XSWD_REQUEST_CANCELLED);
    }

    fn fail(self, code: &'static str) {
        self.response.fail(code);
    }
}

impl PendingXswdResponse {
    fn complete(self, outcome: XswdDecisionCallbackOutcome) {
        match self {
            Self::Permission(callback) => handle_permission_outcome(outcome, callback),
            Self::Prefetch {
                permissions,
                callback,
            } => handle_prefetch_permissions_outcome(outcome, permissions, callback),
        }
    }

    fn fail(self, code: &'static str) {
        match self {
            Self::Permission(callback) => send_permission_failure(callback, code),
            Self::Prefetch { callback, .. } => send_prefetch_failure(callback, code),
        }
    }
}

async fn prepare_xswd_event<Application, Request, Prefetch>(
    event: XSWDEvent,
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    projection_limits: NativeXswdProjectionLimits,
    request_application_dart_callback: &Application,
    request_permission_dart_callback: &Request,
    request_prefetch_permissions_dart_callback: &Prefetch,
) -> PreparedXswdEvent
where
    Application: Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    Request: Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    Prefetch: Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>,
{
    match event {
        XSWDEvent::RequestApplication(state, callback) => {
            let event_summary =
                match create_event_summary(xswd_sessions, &state, XswdRequestType::Application)
                    .await
                {
                    Ok(summary) => summary,
                    Err(_) => {
                        send_permission_failure(callback, XSWD_SESSION_REFERENCE_EXHAUSTED);
                        return PreparedXswdEvent::Handled;
                    }
                };
            PreparedXswdEvent::Decision(PendingXswdDecision {
                state,
                future: request_application_dart_callback(event_summary),
                response: PendingXswdResponse::Permission(callback),
            })
        }
        XSWDEvent::RequestPermission(state, request, callback) => {
            let payload = match NativeXswdPayload::project(&request, projection_limits) {
                Ok(payload) => payload,
                Err(error) => {
                    fail_permission_projection(error, callback);
                    return PreparedXswdEvent::Handled;
                }
            };
            let event_summary = match create_event_summary(
                xswd_sessions,
                &state,
                XswdRequestType::Permission(payload),
            )
            .await
            {
                Ok(summary) => summary,
                Err(_) => {
                    send_permission_failure(callback, XSWD_SESSION_REFERENCE_EXHAUSTED);
                    return PreparedXswdEvent::Handled;
                }
            };
            PreparedXswdEvent::Decision(PendingXswdDecision {
                state,
                future: request_permission_dart_callback(event_summary),
                response: PendingXswdResponse::Permission(callback),
            })
        }
        XSWDEvent::PrefetchPermissions(state, permissions, callback) => {
            let payload = match NativeXswdPayload::project(&permissions, projection_limits) {
                Ok(payload) => payload,
                Err(error) => {
                    fail_prefetch_projection(error, callback);
                    return PreparedXswdEvent::Handled;
                }
            };
            let event_summary = match create_event_summary(
                xswd_sessions,
                &state,
                XswdRequestType::PrefetchPermissions(payload),
            )
            .await
            {
                Ok(summary) => summary,
                Err(_) => {
                    send_prefetch_failure(callback, XSWD_SESSION_REFERENCE_EXHAUSTED);
                    return PreparedXswdEvent::Handled;
                }
            };
            PreparedXswdEvent::Decision(PendingXswdDecision {
                state,
                future: request_prefetch_permissions_dart_callback(event_summary),
                response: PendingXswdResponse::Prefetch {
                    permissions,
                    callback,
                },
            })
        }
        XSWDEvent::CancelRequest(state, callback) => {
            PreparedXswdEvent::Lifecycle(XswdLifecycleEvent::CancelRequest(state, callback))
        }
        XSWDEvent::AppDisconnect(state) => {
            PreparedXswdEvent::Lifecycle(XswdLifecycleEvent::AppDisconnect(state))
        }
    }
}

async fn handle_xswd_lifecycle_event<Cancel, Disconnect>(
    event: XswdLifecycleEvent,
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    cancel_request_dart_callback: &Cancel,
    app_disconnect_dart_callback: &Disconnect,
) where
    Cancel: Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>,
    Disconnect: Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>,
{
    match event {
        XswdLifecycleEvent::CancelRequest(state, callback) => {
            let event_summary =
                match create_event_summary(xswd_sessions, &state, XswdRequestType::CancelRequest)
                    .await
                {
                    Ok(summary) => summary,
                    Err(code) => {
                        if callback.send(Err(anyhow!(code))).is_err() {
                            error!("Error while sending cancel response to XSWD");
                        }
                        return;
                    }
                };
            let result = match cancel_request_dart_callback(event_summary).await {
                XswdNotificationCallbackOutcome::Completed => Ok(()),
                failure => Err(notification_callback_failure(failure)),
            };
            if callback.send(result).is_err() {
                error!("Error while sending cancel response to XSWD");
            }
        }
        XswdLifecycleEvent::AppDisconnect(state) => {
            let event_summary =
                match create_event_summary(xswd_sessions, &state, XswdRequestType::AppDisconnect)
                    .await
                {
                    Ok(summary) => summary,
                    Err(code) => {
                        debug!("XSWD_APP_DISCONNECT_PROJECTION_FAILED:{code}");
                        xswd_sessions.lock().await.invalidate_state(&state);
                        return;
                    }
                };
            let outcome = app_disconnect_dart_callback(event_summary).await;
            if !matches!(outcome, XswdNotificationCallbackOutcome::Completed) {
                debug!(
                    "XSWD_APP_DISCONNECT_CALLBACK_FAILED:{}",
                    notification_failure_code(outcome)
                );
            }
            xswd_sessions.lock().await.invalidate_state(&state);
        }
    }
}

fn cancel_deferred_xswd_decisions(deferred: &mut VecDeque<XSWDEvent>, state: &Arc<AppState>) {
    let mut retained = VecDeque::with_capacity(deferred.len());
    while let Some(event) = deferred.pop_front() {
        match event {
            XSWDEvent::RequestApplication(event_state, callback)
                if Arc::ptr_eq(&event_state, state) =>
            {
                send_permission_failure(callback, XSWD_REQUEST_CANCELLED);
            }
            XSWDEvent::RequestPermission(event_state, _, callback)
                if Arc::ptr_eq(&event_state, state) =>
            {
                send_permission_failure(callback, XSWD_REQUEST_CANCELLED);
            }
            XSWDEvent::PrefetchPermissions(event_state, _, callback)
                if Arc::ptr_eq(&event_state, state) =>
            {
                send_prefetch_failure(callback, XSWD_REQUEST_CANCELLED);
            }
            event => retained.push_back(event),
        }
    }
    *deferred = retained;
}

fn defer_xswd_decision(deferred: &mut VecDeque<XSWDEvent>, event: XSWDEvent) {
    if deferred.len() < MAX_DEFERRED_XSWD_EVENTS {
        deferred.push_back(event);
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
        XSWDEvent::AppDisconnect(state) => {
            let _ = defer_xswd_disconnect(deferred, state);
        }
        XSWDEvent::CancelRequest(_, callback) => acknowledge_cancelled_request(callback),
    }
}

fn defer_xswd_disconnect(
    deferred: &mut VecDeque<XSWDEvent>,
    state: Arc<AppState>,
) -> Option<Arc<AppState>> {
    let already_deferred = deferred.iter().any(
        |event| matches!(event, XSWDEvent::AppDisconnect(event_state) if Arc::ptr_eq(event_state, &state)),
    );
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
            return Some(state);
        }
    }

    if deferred.len() < MAX_DEFERRED_XSWD_EVENTS {
        deferred.push_back(XSWDEvent::AppDisconnect(state));
    }
    None
}

fn is_xswd_decision_event(event: &XSWDEvent) -> bool {
    matches!(
        event,
        XSWDEvent::RequestApplication(_, _)
            | XSWDEvent::RequestPermission(_, _, _)
            | XSWDEvent::PrefetchPermissions(_, _, _)
    )
}

fn fail_deferred_xswd_decisions(deferred: &mut VecDeque<XSWDEvent>, code: &'static str) {
    while let Some(event) = deferred.pop_front() {
        fail_deferred_xswd_event(event, code);
    }
}

fn fail_deferred_xswd_event(event: XSWDEvent, code: &'static str) {
    match event {
        XSWDEvent::RequestApplication(_, callback)
        | XSWDEvent::RequestPermission(_, _, callback) => {
            send_permission_failure(callback, code);
        }
        XSWDEvent::PrefetchPermissions(_, _, callback) => {
            send_prefetch_failure(callback, code);
        }
        XSWDEvent::CancelRequest(_, callback) => acknowledge_cancelled_request(callback),
        XSWDEvent::AppDisconnect(_) => {}
    }
}

fn send_permission_failure(callback: Sender<Result<PermissionResult, Error>>, code: &'static str) {
    if callback.send(Err(anyhow!(code))).is_err() {
        debug!("XSWD_PERMISSION_FAILURE_RESPONSE_DROPPED:{code}");
    }
}

fn send_prefetch_failure(
    callback: Sender<Result<IndexMap<String, Permission>, Error>>,
    code: &'static str,
) {
    if callback.send(Err(anyhow!(code))).is_err() {
        debug!("XSWD_PREFETCH_FAILURE_RESPONSE_DROPPED:{code}");
    }
}

fn acknowledge_cancelled_request(callback: Sender<Result<(), Error>>) {
    if callback.send(Ok(())).is_err() {
        debug!("XSWD_CANCEL_RESPONSE_DROPPED");
    }
}

#[cfg(test)]
async fn handle_xswd_event<Cancel, Application, Request, Prefetch, Disconnect>(
    event: XSWDEvent,
    projection_limits: NativeXswdProjectionLimits,
    cancel_request_dart_callback: &Cancel,
    request_application_dart_callback: &Application,
    request_permission_dart_callback: &Request,
    request_prefetch_permissions_dart_callback: &Prefetch,
    app_disconnect_dart_callback: &Disconnect,
) where
    Cancel: Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>,
    Application: Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    Request: Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    Prefetch: Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    Disconnect: Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>,
{
    let xswd_sessions = xelis_common::tokio::sync::Mutex::new(XswdSessionRegistry::default());
    match prepare_xswd_event(
        event,
        &xswd_sessions,
        projection_limits,
        request_application_dart_callback,
        request_permission_dart_callback,
        request_prefetch_permissions_dart_callback,
    )
    .await
    {
        PreparedXswdEvent::Decision(decision) => decision.complete().await,
        PreparedXswdEvent::Lifecycle(event) => {
            handle_xswd_lifecycle_event(
                event,
                &xswd_sessions,
                cancel_request_dart_callback,
                app_disconnect_dart_callback,
            )
            .await;
        }
        PreparedXswdEvent::Handled => {}
    }
}

async fn create_event_summary(
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    state: &Arc<AppState>,
    event_type: XswdRequestType,
) -> Result<XswdRequestSummary> {
    let application_info = create_app_info(xswd_sessions, state, false).await?;
    Ok(XswdRequestSummary::new(event_type, application_info))
}

#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn create_app_info(
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    state: &Arc<AppState>,
    is_relayer: bool,
) -> Result<AppInfo> {
    let session_ref = xswd_sessions.lock().await.register(state)?;
    let lock = state.get_permissions().lock().await;
    let permissions = lock
        .iter()
        .map(|(key, permission)| {
            let permission_policy = match permission {
                Permission::Ask => PermissionPolicy::Ask,
                Permission::Allow => PermissionPolicy::Accept,
                Permission::Reject => PermissionPolicy::Reject,
            };
            (key.clone(), permission_policy)
        })
        .collect();

    Ok(AppInfo {
        session_ref,
        id: state.get_id().to_string(),
        name: state.get_name().clone(),
        description: state.get_description().clone(),
        url: state.get_url().clone(),
        permissions,
        is_relayer,
    })
}

fn handle_permission_outcome(
    outcome: XswdDecisionCallbackOutcome,
    callback: Sender<Result<PermissionResult, Error>>,
) {
    let result = permission_result_from_outcome(outcome);

    if callback.send(result).is_err() {
        error!("Error while sending permission response to XSWD");
    }
}

fn fail_permission_projection(
    error: XswdPayloadProjectionError,
    callback: Sender<Result<PermissionResult, Error>>,
) {
    debug!("XSWD_PAYLOAD_PROJECTION_FAILED:{}", error.code());
    if callback
        .send(Err(anyhow!("XSWD_PAYLOAD_PROJECTION_FAILED")))
        .is_err()
    {
        error!("Error while sending permission projection failure to XSWD");
    }
}

fn fail_prefetch_projection(
    error: XswdPayloadProjectionError,
    callback: Sender<Result<IndexMap<String, Permission>, Error>>,
) {
    debug!("XSWD_PAYLOAD_PROJECTION_FAILED:{}", error.code());
    if callback
        .send(Err(anyhow!("XSWD_PAYLOAD_PROJECTION_FAILED")))
        .is_err()
    {
        error!("Error while sending prefetch projection failure to XSWD");
    }
}

fn permission_result_from_outcome(
    outcome: XswdDecisionCallbackOutcome,
) -> Result<PermissionResult> {
    match outcome {
        XswdDecisionCallbackOutcome::Accept => Ok(PermissionResult::Accept),
        XswdDecisionCallbackOutcome::Reject => Ok(PermissionResult::Reject),
        XswdDecisionCallbackOutcome::AlwaysAccept => Ok(PermissionResult::AlwaysAccept),
        XswdDecisionCallbackOutcome::AlwaysReject => Ok(PermissionResult::AlwaysReject),
        failure => Err(anyhow!(decision_failure_code(failure))),
    }
}

fn decision_failure_code(outcome: XswdDecisionCallbackOutcome) -> &'static str {
    match outcome {
        XswdDecisionCallbackOutcome::InvalidPayload => "XSWD_CALLBACK_PAYLOAD_INVALID",
        XswdDecisionCallbackOutcome::Timeout => "XSWD_CALLBACK_TIMEOUT",
        XswdDecisionCallbackOutcome::Exception => "XSWD_CALLBACK_EXCEPTION",
        _ => "XSWD_CALLBACK_OUTCOME_INVALID",
    }
}

fn notification_callback_failure(outcome: XswdNotificationCallbackOutcome) -> Error {
    anyhow!(notification_failure_code(outcome))
}

fn notification_failure_code(outcome: XswdNotificationCallbackOutcome) -> &'static str {
    match outcome {
        XswdNotificationCallbackOutcome::InvalidPayload => "XSWD_CALLBACK_PAYLOAD_INVALID",
        XswdNotificationCallbackOutcome::Timeout => "XSWD_CALLBACK_TIMEOUT",
        XswdNotificationCallbackOutcome::Exception => "XSWD_CALLBACK_EXCEPTION",
        XswdNotificationCallbackOutcome::Completed => "XSWD_CALLBACK_OUTCOME_INVALID",
    }
}

#[cfg(test)]
fn permission_result_from_decision(decision: UserPermissionDecision) -> PermissionResult {
    match decision {
        UserPermissionDecision::Accept => PermissionResult::Accept,
        UserPermissionDecision::Reject => PermissionResult::Reject,
        UserPermissionDecision::AlwaysAccept => PermissionResult::AlwaysAccept,
        UserPermissionDecision::AlwaysReject => PermissionResult::AlwaysReject,
    }
}

fn handle_prefetch_permissions_outcome(
    outcome: XswdDecisionCallbackOutcome,
    permissions: XSWDPrefetchPermissions,
    callback: Sender<Result<IndexMap<String, Permission>, Error>>,
) {
    let results = match outcome {
        XswdDecisionCallbackOutcome::Accept | XswdDecisionCallbackOutcome::AlwaysAccept => Ok(
            prefetch_permissions_from_decision(UserPermissionDecision::Accept, permissions),
        ),
        XswdDecisionCallbackOutcome::Reject | XswdDecisionCallbackOutcome::AlwaysReject => {
            Ok(IndexMap::new())
        }
        failure => Err(anyhow!(decision_failure_code(failure))),
    };

    if callback.send(results).is_err() {
        error!("Error while sending prefetch permissions response back to XSWD");
    }
}

fn prefetch_permissions_from_decision(
    decision: UserPermissionDecision,
    permissions: XSWDPrefetchPermissions,
) -> IndexMap<String, Permission> {
    let accepted = matches!(
        decision,
        UserPermissionDecision::Accept | UserPermissionDecision::AlwaysAccept
    );

    let mut results: IndexMap<String, Permission> = IndexMap::new();
    if accepted {
        for p in permissions.permissions {
            results.insert(p, Permission::Allow);
        }
    }

    results
}

fn xswd_event_name(event: &XSWDEvent) -> &'static str {
    match event {
        XSWDEvent::CancelRequest(_, _) => "CancelRequest",
        XSWDEvent::RequestApplication(_, _) => "RequestApplication",
        XSWDEvent::RequestPermission(_, _, _) => "RequestPermission",
        XSWDEvent::PrefetchPermissions(_, _, _) => "PrefetchPermissions",
        XSWDEvent::AppDisconnect(_) => "AppDisconnect",
    }
}

#[cfg(test)]
#[path = "impl/tests/mod.rs"]
mod tests;
