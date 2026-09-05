use indexmap::IndexMap;
use std::{
    collections::{HashMap, VecDeque},
    fmt,
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

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum XswdSessionReferenceError {
    Exhausted,
    Invalid,
}

impl XswdSessionReferenceError {
    fn code(self) -> &'static str {
        match self {
            Self::Exhausted => XSWD_SESSION_REFERENCE_EXHAUSTED,
            Self::Invalid => XSWD_SESSION_REFERENCE_INVALID,
        }
    }
}

impl fmt::Display for XswdSessionReferenceError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.code())
    }
}

impl std::error::Error for XswdSessionReferenceError {}

#[derive(Default)]
#[flutter_rust_bridge::frb(ignore)]
pub(crate) struct XswdSessionRegistry {
    sessions: HashMap<u64, XswdSessionEntry>,
}

struct XswdSessionEntry {
    state: Weak<AppState>,
    active: bool,
}

impl XswdSessionRegistry {
    fn register(
        &mut self,
        state: &Arc<AppState>,
    ) -> std::result::Result<u64, XswdSessionReferenceError> {
        let session_ref = self.project(state)?;
        self.sessions[&session_ref]
            .active
            .then_some(session_ref)
            .ok_or(XswdSessionReferenceError::Invalid)
    }

    fn project(
        &mut self,
        state: &Arc<AppState>,
    ) -> std::result::Result<u64, XswdSessionReferenceError> {
        self.remove_dead();
        let state_ref = Arc::downgrade(state);
        if let Some((session_ref, _)) = self
            .sessions
            .iter()
            .find(|(_, registered)| Weak::ptr_eq(&registered.state, &state_ref))
        {
            return Ok(*session_ref);
        }

        let session_ref = NEXT_XSWD_SESSION_REFERENCE
            .fetch_update(Ordering::Relaxed, Ordering::Relaxed, |current| {
                current.checked_add(1)
            })
            .map_err(|_| XswdSessionReferenceError::Exhausted)?;
        self.sessions.insert(
            session_ref,
            XswdSessionEntry {
                state: state_ref,
                active: true,
            },
        );
        Ok(session_ref)
    }

    fn resolve(&mut self, session_ref: u64) -> Option<Arc<AppState>> {
        self.remove_dead();
        self.sessions
            .get(&session_ref)
            .filter(|entry| entry.active)
            .and_then(|entry| Weak::upgrade(&entry.state))
    }

    fn invalidate_state(&mut self, state: &Arc<AppState>) {
        self.remove_dead();
        let state_ref = Arc::downgrade(state);
        let mut found = false;
        for entry in self.sessions.values_mut() {
            if Weak::ptr_eq(&entry.state, &state_ref) {
                entry.active = false;
                found = true;
            }
        }
        if found {
            return;
        }

        // A disconnect may be the first event observed for a state. Reserve its
        // opaque identity as an informational tombstone so projecting the
        // lifecycle notification cannot mint fresh native authority.
        if let Ok(session_ref) = NEXT_XSWD_SESSION_REFERENCE.fetch_update(
            Ordering::Relaxed,
            Ordering::Relaxed,
            |current| current.checked_add(1),
        ) {
            self.sessions.insert(
                session_ref,
                XswdSessionEntry {
                    state: state_ref,
                    active: false,
                },
            );
        }
    }

    fn clear(&mut self) {
        self.remove_dead();
        for entry in self.sessions.values_mut() {
            entry.active = false;
        }
    }

    fn remove_dead(&mut self) {
        self.sessions
            .retain(|_, entry| entry.state.strong_count() > 0);
    }
}
#[allow(async_fn_in_trait)]
pub trait XSWD {
    async fn start_xswd(
        &self,
        projection_limits: NativeXswdProjectionLimits,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
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
        cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
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
        _cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
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
        cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
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

enum DeferredXswdEvent {
    Raw(XSWDEvent),
    Notification(PreparedXswdNotification),
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

impl XswdLifecycleEvent {
    fn acknowledge(self) -> (Arc<AppState>, XswdNotificationKind) {
        match self {
            Self::CancelRequest(state, callback) => {
                acknowledge_cancelled_request(callback);
                (state, XswdNotificationKind::CancelRequest)
            }
            Self::AppDisconnect(state) => (state, XswdNotificationKind::AppDisconnect),
        }
    }
}

struct PendingXswdDecision {
    state: Arc<AppState>,
    future: DartFnFuture<XswdDecisionCallbackOutcome>,
    response: PendingXswdResponse,
    is_application_admission: bool,
}

#[derive(Clone, Copy)]
enum XswdNotificationKind {
    CancelRequest,
    AppDisconnect,
}

struct PreparedXswdNotification {
    state: Arc<AppState>,
    summary: XswdRequestSummary,
    kind: XswdNotificationKind,
    cancelled_application_admission: bool,
}

struct ActiveXswdCallback {
    state: Arc<AppState>,
    kind: ActiveXswdCallbackKind,
    future: DartFnFuture<XswdActiveCallbackOutcome>,
}

enum ActiveXswdCallbackKind {
    Decision {
        response: PendingXswdResponse,
        is_application_admission: bool,
    },
    Notification(XswdNotificationKind),
}

enum XswdActiveCallbackOutcome {
    Decision(XswdDecisionCallbackOutcome),
    Notification(XswdNotificationCallbackOutcome),
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

    fn into_active(self) -> ActiveXswdCallback {
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
    fn start<Cancel, Disconnect>(
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
    async fn complete<Cancel, Disconnect>(
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
    fn is_decision_for(&self, state: &Arc<AppState>) -> bool {
        matches!(self.kind, ActiveXswdCallbackKind::Decision { .. })
            && Arc::ptr_eq(&self.state, state)
    }

    fn is_application_admission(&self) -> bool {
        matches!(
            self.kind,
            ActiveXswdCallbackKind::Decision {
                is_application_admission: true,
                ..
            }
        )
    }

    fn is_disconnect_for(&self, state: &Arc<AppState>) -> bool {
        matches!(
            self.kind,
            ActiveXswdCallbackKind::Notification(XswdNotificationKind::AppDisconnect)
        ) && Arc::ptr_eq(&self.state, state)
    }

    fn complete(self, outcome: XswdActiveCallbackOutcome) {
        Self::complete_kind(self.kind, outcome);
    }

    fn complete_kind(kind: ActiveXswdCallbackKind, outcome: XswdActiveCallbackOutcome) {
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

    fn cancel(self) {
        match self.kind {
            ActiveXswdCallbackKind::Decision { response, .. } => {
                response.fail(XSWD_REQUEST_CANCELLED)
            }
            ActiveXswdCallbackKind::Notification(kind) => {
                record_abandoned_xswd_notification(kind, XSWD_REQUEST_CANCELLED)
            }
        }
    }

    fn fail(self, code: &'static str) {
        match self.kind {
            ActiveXswdCallbackKind::Decision { response, .. } => response.fail(code),
            ActiveXswdCallbackKind::Notification(kind) => {
                record_abandoned_xswd_notification(kind, code)
            }
        }
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
                    Err(error) => {
                        send_permission_failure(callback, error.code());
                        return PreparedXswdEvent::Handled;
                    }
                };
            PreparedXswdEvent::Decision(PendingXswdDecision {
                state,
                future: request_application_dart_callback(event_summary),
                response: PendingXswdResponse::Permission(callback),
                is_application_admission: true,
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
                Err(error) => {
                    send_permission_failure(callback, error.code());
                    return PreparedXswdEvent::Handled;
                }
            };
            PreparedXswdEvent::Decision(PendingXswdDecision {
                state,
                future: request_permission_dart_callback(event_summary),
                response: PendingXswdResponse::Permission(callback),
                is_application_admission: false,
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
                Err(error) => {
                    send_prefetch_failure(callback, error.code());
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
                is_application_admission: false,
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

async fn prepare_xswd_lifecycle_notification(
    state: Arc<AppState>,
    kind: XswdNotificationKind,
    cancelled_application_admission: bool,
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
) -> Option<PreparedXswdNotification> {
    match kind {
        XswdNotificationKind::CancelRequest => {
            let summary = match create_lifecycle_event_summary(
                xswd_sessions,
                &state,
                XswdRequestType::CancelRequest,
            )
            .await
            {
                Ok(summary) => summary,
                Err(code) => {
                    debug!("XSWD_CANCEL_NOTIFICATION_PROJECTION_FAILED:{code}");
                    return None;
                }
            };
            Some(PreparedXswdNotification {
                state,
                summary,
                kind: XswdNotificationKind::CancelRequest,
                cancelled_application_admission,
            })
        }
        XswdNotificationKind::AppDisconnect => {
            let summary = match create_lifecycle_event_summary(
                xswd_sessions,
                &state,
                XswdRequestType::AppDisconnect,
            )
            .await
            {
                Ok(summary) => summary,
                Err(code) => {
                    debug!("XSWD_APP_DISCONNECT_PROJECTION_FAILED:{code}");
                    return None;
                }
            };
            Some(PreparedXswdNotification {
                state,
                summary,
                kind: XswdNotificationKind::AppDisconnect,
                cancelled_application_admission: false,
            })
        }
    }
}

fn cancel_deferred_xswd_decisions(
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

fn defer_xswd_decision(deferred: &mut VecDeque<DeferredXswdEvent>, event: XSWDEvent) {
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

fn defer_xswd_disconnect(
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

fn is_xswd_decision_event(event: &DeferredXswdEvent) -> bool {
    matches!(
        event,
        DeferredXswdEvent::Raw(
            XSWDEvent::RequestApplication(_, _)
                | XSWDEvent::RequestPermission(_, _, _)
                | XSWDEvent::PrefetchPermissions(_, _, _)
        )
    )
}

fn fail_deferred_xswd_events(deferred: &mut VecDeque<DeferredXswdEvent>, code: &'static str) {
    while let Some(event) = deferred.pop_front() {
        fail_deferred_xswd_event(event, code);
    }
}

fn fail_deferred_xswd_event(event: DeferredXswdEvent, code: &'static str) {
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

fn xswd_event_state(event: &XSWDEvent) -> &Arc<AppState> {
    match event {
        XSWDEvent::RequestApplication(state, _)
        | XSWDEvent::RequestPermission(state, _, _)
        | XSWDEvent::PrefetchPermissions(state, _, _)
        | XSWDEvent::CancelRequest(state, _)
        | XSWDEvent::AppDisconnect(state) => state,
    }
}

fn track_xswd_state(observed: &mut Vec<Weak<AppState>>, state: &Arc<AppState>) {
    observed.retain(|registered| registered.strong_count() > 0);
    let state_ref = Arc::downgrade(state);
    if !observed
        .iter()
        .any(|registered| Weak::ptr_eq(registered, &state_ref))
    {
        observed.push(state_ref);
    }
}

async fn invalidate_observed_xswd_states(
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
    Cancel: Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>,
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
            let (state, kind) = event.acknowledge();
            if matches!(kind, XswdNotificationKind::AppDisconnect) {
                xswd_sessions.lock().await.invalidate_state(&state);
            }
            if let Some(notification) =
                prepare_xswd_lifecycle_notification(state, kind, false, &xswd_sessions).await
            {
                notification
                    .complete(cancel_request_dart_callback, app_disconnect_dart_callback)
                    .await;
            }
        }
        PreparedXswdEvent::Handled => {}
    }
}

async fn create_event_summary(
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    state: &Arc<AppState>,
    event_type: XswdRequestType,
) -> std::result::Result<XswdRequestSummary, XswdSessionReferenceError> {
    let session_ref = xswd_sessions.lock().await.register(state)?;
    let application_info = create_app_info_with_session_ref(state, false, session_ref).await;
    Ok(XswdRequestSummary::new(event_type, application_info))
}

async fn create_lifecycle_event_summary(
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    state: &Arc<AppState>,
    event_type: XswdRequestType,
) -> std::result::Result<XswdRequestSummary, XswdSessionReferenceError> {
    let session_ref = xswd_sessions.lock().await.project(state)?;
    let application_info = create_app_info_with_session_ref(state, false, session_ref).await;
    Ok(XswdRequestSummary::new(event_type, application_info))
}

#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn create_app_info(
    xswd_sessions: &xelis_common::tokio::sync::Mutex<XswdSessionRegistry>,
    state: &Arc<AppState>,
    is_relayer: bool,
) -> Result<AppInfo> {
    let session_ref = xswd_sessions
        .lock()
        .await
        .project(state)
        .map_err(|error| anyhow!(error.code()))?;
    Ok(create_app_info_with_session_ref(state, is_relayer, session_ref).await)
}

async fn create_app_info_with_session_ref(
    state: &Arc<AppState>,
    is_relayer: bool,
    session_ref: u64,
) -> AppInfo {
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

    AppInfo {
        session_ref,
        id: state.get_id().to_string(),
        name: state.get_name().clone(),
        description: state.get_description().clone(),
        url: state.get_url().clone(),
        permissions,
        is_relayer,
    }
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

fn record_xswd_notification_outcome(
    kind: XswdNotificationKind,
    outcome: XswdNotificationCallbackOutcome,
) {
    if !matches!(outcome, XswdNotificationCallbackOutcome::Completed) {
        debug!(
            "XSWD_{}_CALLBACK_FAILED:{}",
            xswd_notification_name(kind),
            notification_failure_code(outcome)
        );
    }
}

fn record_abandoned_xswd_notification(kind: XswdNotificationKind, code: &'static str) {
    debug!(
        "XSWD_{}_CALLBACK_ABANDONED:{code}",
        xswd_notification_name(kind)
    );
}

fn xswd_notification_name(kind: XswdNotificationKind) -> &'static str {
    match kind {
        XswdNotificationKind::CancelRequest => "CANCEL_REQUEST",
        XswdNotificationKind::AppDisconnect => "APP_DISCONNECT",
    }
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
