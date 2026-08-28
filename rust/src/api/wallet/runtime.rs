use std::path::Path;
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use super::super::precomputed_tables::PrecomputedTableType;
use super::multisig::PendingMultisigStore;
use super::{
    ActiveWalletConnection, WalletConnectionAttempt, WalletConnectionAttempts, XelisWallet,
};
use crate::api::error::{NativeXelisError, NativeXelisErrorCode};
use crate::api::models::runtime_dtos::{
    NativeWalletConnectionOptions, NativeWalletReconnectPolicy, WalletDaemonInfo,
};
use anyhow::{anyhow, bail, Result};
use flutter_rust_bridge::frb;
use log::info;
use parking_lot::{Mutex as StateMutex, RwLock as StateRwLock};
use url::Url;
use xelis_common::{
    network::Network,
    tokio::{spawn_task, sync::oneshot, time::timeout},
    utils::sanitize_ws_address,
};
use xelis_wallet::{
    daemon_api::DaemonAPI,
    error::WalletError,
    network_handler::NetworkError,
    precomputed_tables,
    wallet::{RecoverOption, Wallet},
};

mod table_cache;

static MT_PARAMS: StateMutex<Option<(usize, usize)>> = StateMutex::new(None);
const DEFAULT_ONLINE_MODE_TIMEOUT: Duration = Duration::from_secs(20);
const DAEMON_EVENT_CAPACITY: usize = 64;

fn invalid_daemon_address() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::InvalidInput,
        "DAEMON_ADDRESS_INVALID",
        "Daemon address must be an HTTP or WebSocket origin, or host[:port], without credentials, path, query, or fragment",
    )
}

fn daemon_rpc_endpoint(daemon_address: &str) -> std::result::Result<String, NativeXelisError> {
    let normalized_address = sanitize_ws_address(daemon_address);
    let url = Url::parse(&normalized_address).map_err(|_| invalid_daemon_address())?;
    let supported_scheme = matches!(url.scheme(), "ws" | "wss");
    let is_origin = url.host().is_some()
        && url.username().is_empty()
        && url.password().is_none()
        && matches!(url.path(), "" | "/")
        && url.query().is_none()
        && url.fragment().is_none();

    if !supported_scheme || !is_origin {
        return Err(invalid_daemon_address());
    }

    Ok(format!("{normalized_address}/json_rpc"))
}

fn ensure_daemon_network(
    wallet_network: &Network,
    daemon_network: &Network,
) -> std::result::Result<(), NativeXelisError> {
    if wallet_network == daemon_network {
        return Ok(());
    }

    Err(NativeXelisError::from(WalletError::NetworkError(
        NetworkError::NetworkMismatch,
    )))
}

fn normalize_offline_mode_result(
    result: std::result::Result<(), WalletError>,
) -> std::result::Result<(), NativeXelisError> {
    match result {
        Ok(())
        | Err(WalletError::NotOnlineMode)
        | Err(WalletError::NetworkError(NetworkError::NotRunning))
        | Err(WalletError::NetworkError(NetworkError::DaemonAPIError(_))) => Ok(()),
        Err(error) => Err(NativeXelisError::from(error)),
    }
}

async fn disconnect_daemon_api(api: &DaemonAPI) {
    let _ = api.disconnect_force().await;
}

fn network_connect_timeout() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::Network,
        "NETWORK_CONNECT_TIMEOUT",
        "Native wallet connection exceeded its configured caller limit",
    )
}

fn network_connect_worker_failed() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::Internal,
        "NETWORK_CONNECT_WORKER_FAILED",
        "Native wallet connection worker stopped before acknowledgement",
    )
}

fn network_connect_cancelled() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::Cancelled,
        "NETWORK_CONNECT_CANCELLED",
        "Native wallet connection was cancelled before activation",
    )
}

struct ConnectionAttemptGuard {
    attempts: Arc<WalletConnectionAttempts>,
    attempt: Arc<WalletConnectionAttempt>,
}

impl ConnectionAttemptGuard {
    fn acquire(
        attempts: Arc<WalletConnectionAttempts>,
    ) -> std::result::Result<Self, NativeXelisError> {
        let attempt = Arc::new(WalletConnectionAttempt::new());
        {
            let mut state = attempts.state.lock();
            if state.closed {
                return Err(network_connect_cancelled());
            }
            if state.current.is_some() {
                return Err(NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::OperationInProgress,
                    "NETWORK_CONNECT_IN_PROGRESS",
                    "A native wallet connection attempt is already in progress",
                ));
            }
            state.current = Some(Arc::clone(&attempt));
        }
        Ok(Self { attempts, attempt })
    }

    fn attempt(&self) -> Arc<WalletConnectionAttempt> {
        Arc::clone(&self.attempt)
    }
}

impl Drop for ConnectionAttemptGuard {
    fn drop(&mut self) {
        self.attempt.complete();
        let mut state = self.attempts.state.lock();
        if state
            .current
            .as_ref()
            .is_some_and(|current| Arc::ptr_eq(current, &self.attempt))
        {
            state.current = None;
        }
    }
}

async fn rollback_connection(wallet: &Arc<Wallet>, api: &Arc<DaemonAPI>) {
    api.client().set_auto_reconnect_delay(None).await;
    disconnect_daemon_api(api.as_ref()).await;
    // Force the socket closed first so pending sync RPCs wake up before the
    // network handler is stopped and removed from the wallet.
    let _ = wallet.set_offline_mode().await;
}

async fn connect_wallet(
    wallet: &Arc<Wallet>,
    daemon_address: &str,
    attempt: &WalletConnectionAttempt,
    timeout_duration: Duration,
    reconnect_policy: NativeWalletReconnectPolicy,
) -> std::result::Result<Arc<DaemonAPI>, NativeXelisError> {
    let rpc_endpoint = daemon_rpc_endpoint(daemon_address)?;
    let api = Arc::new(
        DaemonAPI::with(rpc_endpoint, Some(timeout_duration), DAEMON_EVENT_CAPACITY)
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::Network,
                    "DAEMON_CONNECT_FAILED",
                )
            })?,
    );
    *attempt.api.lock().await = Some(Arc::clone(&api));

    if matches!(
        reconnect_policy,
        NativeWalletReconnectPolicy::ApplicationManaged
    ) {
        api.client().set_auto_reconnect_delay(None).await;
    }
    if attempt.is_cancelled() {
        disconnect_daemon_api(api.as_ref()).await;
        return Err(network_connect_cancelled());
    }

    let daemon_info = match api.get_info().await {
        Ok(info) => info,
        Err(error) => {
            let classified = NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::Network,
                "DAEMON_INFO_PREFLIGHT_FAILED",
            );
            disconnect_daemon_api(api.as_ref()).await;
            return Err(classified);
        }
    };

    if let Err(error) = ensure_daemon_network(wallet.get_network(), &daemon_info.network) {
        disconnect_daemon_api(api.as_ref()).await;
        return Err(error);
    }
    if attempt.is_cancelled() {
        disconnect_daemon_api(api.as_ref()).await;
        return Err(network_connect_cancelled());
    }

    {
        let _activation_guard = attempt.activation.lock().await;
        if attempt.is_cancelled() {
            disconnect_daemon_api(api.as_ref()).await;
            return Err(network_connect_cancelled());
        }
        if let Err(error) = wallet
            .set_online_mode_with_api(
                Arc::clone(&api),
                matches!(
                    reconnect_policy,
                    NativeWalletReconnectPolicy::UpstreamManagedExperimental
                ),
            )
            .await
        {
            disconnect_daemon_api(api.as_ref()).await;
            return Err(NativeXelisError::from(error));
        }
        if attempt.is_cancelled() {
            rollback_connection(wallet, &api).await;
            return Err(network_connect_cancelled());
        }
    }

    Ok(api)
}

fn mt_params_for_cpu_cores(cpu_cores: usize) -> (usize, usize) {
    let thread_count = (cpu_cores.saturating_sub(2)).max(1).min(32);
    (thread_count, thread_count * 4)
}

fn get_mt_params() -> (usize, usize) {
    let mut guard = MT_PARAMS.lock();

    if let Some(params) = *guard {
        return params;
    }

    let cpu_cores = thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);
    let params = mt_params_for_cpu_cores(cpu_cores);

    *guard = Some(params);
    params
}

fn resolve_wallet_path(name: &str, directory: &str) -> Result<String> {
    if name.is_empty() {
        if directory.is_empty() {
            bail!("Either 'name' or 'directory' must be non-empty");
        }

        return Ok(directory.to_owned());
    }

    Ok(Path::new(directory)
        .join(name)
        .to_string_lossy()
        .into_owned())
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum RecoveryInputKind {
    None,
    Seed,
    PrivateKey,
}

fn recovery_input_kind(
    has_seed: bool,
    has_private_key: bool,
) -> std::result::Result<RecoveryInputKind, NativeXelisError> {
    match (has_seed, has_private_key) {
        (true, true) => Err(NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "WALLET_RECOVERY_INPUT_CONFLICT",
            "Seed and private key recovery inputs are mutually exclusive",
        )),
        (true, false) => Ok(RecoveryInputKind::Seed),
        (false, true) => Ok(RecoveryInputKind::PrivateKey),
        (false, false) => Ok(RecoveryInputKind::None),
    }
}

fn recover_option<'a>(
    kind: RecoveryInputKind,
    seed: Option<&'a str>,
    private_key: Option<&'a str>,
) -> RecoverOption<'a> {
    match kind {
        RecoveryInputKind::None => RecoverOption::None,
        RecoveryInputKind::Seed => {
            RecoverOption::Seed(seed.expect("validated seed recovery input missing"))
        }
        RecoveryInputKind::PrivateKey => RecoverOption::PrivateKey(
            private_key.expect("validated private-key recovery input missing"),
        ),
    }
}

fn precomputed_table_type_from_l1(size: usize) -> PrecomputedTableType {
    match size {
        precomputed_tables::L1_LOW => PrecomputedTableType::L1Low,
        precomputed_tables::L1_MEDIUM => PrecomputedTableType::L1Medium,
        precomputed_tables::L1_FULL => PrecomputedTableType::L1Full,
        custom => PrecomputedTableType::Custom(custom),
    }
}

pub(super) fn refresh_mt_params() {
    *MT_PARAMS.lock() = None;
    let _ = get_mt_params();
}

pub(super) fn set_mt_params(thread_count: usize, concurrency: usize) {
    *MT_PARAMS.lock() = Some((thread_count, concurrency));
}

pub(super) fn clear_cached_tables() {
    table_cache::clear_cached_tables();
}

pub(super) fn drop_wallet(wallet: XelisWallet) {
    drop(wallet);
}

pub(super) async fn update_tables(
    precomputed_tables_path: String,
    precomputed_table_type: PrecomputedTableType,
) -> Result<()> {
    let precomputed_tables_size = precomputed_table_type.to_l1_size()?;

    table_cache::materialize_precomputed_tables(&precomputed_tables_path, precomputed_tables_size)
        .await?;
    Ok(())
}

pub(super) fn get_current_precomputed_tables_type() -> Result<PrecomputedTableType> {
    info!("Getting current precomputed tables type...");
    let size =
        table_cache::current_l1().ok_or_else(|| anyhow!("Precomputed tables not initialized"))?;

    info!("Precomputed tables found in cache.");
    info!("Current precomputed tables L1 size: {}", size);

    Ok(precomputed_table_type_from_l1(size))
}

pub(super) async fn create_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    seed: Option<String>,
    private_key: Option<String>,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> std::result::Result<XelisWallet, NativeXelisError> {
    let recovery_input = recovery_input_kind(seed.is_some(), private_key.is_some())?;

    let full_path = resolve_wallet_path(&name, &directory).map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "WALLET_PATH_INVALID",
            format!("{error:#}"),
        )
    })?;

    let precomputed_tables_size = precomputed_table_type.to_l1_size().map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "PRECOMPUTED_TABLE_TYPE_INVALID",
            format!("{error:#}"),
        )
    })?;

    info!("Creating wallet");

    let precomputed_tables = table_cache::get_or_load_precomputed_tables(
        precomputed_tables_path.as_deref(),
        precomputed_tables_size,
    )
    .await
    .map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Initialization,
            "PRECOMPUTED_TABLES_INITIALIZATION_FAILED",
            format!("{error:#}"),
        )
    })?;

    let recover = recover_option(recovery_input, seed.as_deref(), private_key.as_deref());

    let (thread_count, concurrency) = get_mt_params();

    let xelis_wallet = Wallet::create(
        &full_path,
        &password,
        recover,
        network,
        precomputed_tables,
        thread_count,
        concurrency,
    )
    .await
    .map_err(|error| match recovery_input {
        RecoveryInputKind::None => NativeXelisError::from_wallet_operation(
            error,
            NativeXelisErrorCode::Internal,
            "WALLET_CREATE_FAILED",
        ),
        RecoveryInputKind::Seed => NativeXelisError::from_wallet_seed_recovery_operation(error),
        RecoveryInputKind::PrivateKey => {
            NativeXelisError::from_wallet_private_key_recovery_operation(error)
        }
    })?;

    Ok(XelisWallet {
        wallet: xelis_wallet,
        connection_attempts: Arc::new(WalletConnectionAttempts::default()),
        active_connection: Default::default(),
        runtime_event_generation: Default::default(),
        business_event_generation: Default::default(),
        asset_resolution: Default::default(),
        prepared_transaction: StateRwLock::new(Default::default()),
        pending_multisig: StateRwLock::new(PendingMultisigStore::default()),
    })
}

pub(super) async fn open_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> std::result::Result<XelisWallet, NativeXelisError> {
    let full_path = resolve_wallet_path(&name, &directory).map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "WALLET_PATH_INVALID",
            format!("{error:#}"),
        )
    })?;

    let precomputed_tables_size = precomputed_table_type.to_l1_size().map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "PRECOMPUTED_TABLE_TYPE_INVALID",
            format!("{error:#}"),
        )
    })?;

    let precomputed_tables = table_cache::get_or_load_precomputed_tables(
        precomputed_tables_path.as_deref(),
        precomputed_tables_size,
    )
    .await
    .map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Initialization,
            "PRECOMPUTED_TABLES_INITIALIZATION_FAILED",
            format!("{error:#}"),
        )
    })?;

    let (thread_count, concurrency) = get_mt_params();

    let xelis_wallet = Wallet::open(
        &full_path,
        &password,
        network,
        precomputed_tables,
        thread_count,
        concurrency,
    )
    .map_err(|error| {
        NativeXelisError::from_wallet_authentication_operation(
            error,
            NativeXelisErrorCode::Internal,
            "WALLET_OPEN_FAILED",
        )
    })?;

    Ok(XelisWallet {
        wallet: xelis_wallet,
        connection_attempts: Arc::new(WalletConnectionAttempts::default()),
        active_connection: Default::default(),
        runtime_event_generation: Default::default(),
        business_event_generation: Default::default(),
        asset_resolution: Default::default(),
        prepared_transaction: StateRwLock::new(Default::default()),
        pending_multisig: StateRwLock::new(PendingMultisigStore::default()),
    })
}

impl XelisWallet {
    async fn cancel_connection_attempt(&self, terminal: bool) {
        if let Some(attempt) = self.connection_attempts.cancel_current(terminal) {
            if let Some(api) = attempt.api.lock().await.clone() {
                api.client().set_auto_reconnect_delay(None).await;
                disconnect_daemon_api(api.as_ref()).await;
            }
            // Synchronize with the only check-and-activate region. Once this
            // barrier is acquired, the cancelled worker can no longer install
            // a handler after offline/close has applied its postcondition.
            let activation_barrier = attempt.activation.lock().await;
            drop(activation_barrier);
            attempt.wait_completed().await;
        }
    }

    pub async fn change_password(
        &self,
        old_password: String,
        new_password: String,
    ) -> std::result::Result<(), NativeXelisError> {
        self.wallet
            .set_password(&old_password, &new_password)
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_authentication_operation(
                    error,
                    NativeXelisErrorCode::Internal,
                    "WALLET_PASSWORD_CHANGE_FAILED",
                )
            })
    }

    pub async fn online_mode(
        &self,
        daemon_address: String,
        options: NativeWalletConnectionOptions,
    ) -> std::result::Result<(), NativeXelisError> {
        if options.timeout_millis == 0 {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "NETWORK_TIMEOUT_INVALID",
                "Connection timeout must be positive",
            ));
        }
        let timeout_duration = Duration::from_millis(options.timeout_millis);
        // The consuming application owns reconnect attempts. The upstream
        // auto-reconnect loop can sleep after sync errors and miss stop signals,
        // which blocks logout/close when a daemon is on the wrong network.
        // Never cancel the connection future directly. The locked upstream
        // constructor starts its WebSocket task before it exposes a handle, so
        // a supervised worker must finish and roll back any late success.
        let attempt_guard = ConnectionAttemptGuard::acquire(Arc::clone(&self.connection_attempts))?;
        let attempt = attempt_guard.attempt();
        if self.wallet.is_online().await {
            return Err(NativeXelisError::from(WalletError::AlreadyOnlineMode));
        }
        if let Some(stale) = self.active_connection.lock().await.take() {
            stale.api.client().set_auto_reconnect_delay(None).await;
            disconnect_daemon_api(stale.api.as_ref()).await;
            normalize_offline_mode_result(self.wallet.set_offline_mode().await)?;
        }
        if attempt.is_cancelled() {
            return Err(network_connect_cancelled());
        }
        let worker_attempt = Arc::clone(&attempt);
        let (result_sender, result_receiver) = oneshot::channel();
        let (accepted_sender, accepted_receiver) = oneshot::channel();
        let (finalized_sender, finalized_receiver) = oneshot::channel();
        let wallet = Arc::clone(&self.wallet);
        spawn_task("wallet-connect", async move {
            let attempt_guard = attempt_guard;
            match connect_wallet(
                &wallet,
                &daemon_address,
                &worker_attempt,
                timeout_duration,
                options.reconnect_policy,
            )
            .await
            {
                Ok(api) => {
                    let delivered = result_sender.send(Ok(Arc::clone(&api))).is_ok();
                    let accepted = delivered && accepted_receiver.await.is_ok();
                    let finalized = accepted && finalized_receiver.await.is_ok();
                    if !finalized || worker_attempt.is_cancelled() {
                        rollback_connection(&wallet, &api).await;
                    }
                    drop(attempt_guard);
                }
                Err(error) => {
                    drop(attempt_guard);
                    let _ = result_sender.send(Err(error));
                }
            }
        });

        match timeout(timeout_duration, result_receiver).await {
            Ok(Ok(Ok(api))) => {
                accepted_sender
                    .send(())
                    .map_err(|_| network_connect_worker_failed())?;
                if attempt.is_cancelled() {
                    drop(finalized_sender);
                    attempt.wait_completed().await;
                    Err(network_connect_cancelled())
                } else {
                    let mut active_connection = self.active_connection.lock().await;
                    if attempt.is_cancelled() {
                        drop(active_connection);
                        drop(finalized_sender);
                        attempt.wait_completed().await;
                        Err(network_connect_cancelled())
                    } else {
                        *active_connection = Some(ActiveWalletConnection {
                            api,
                            timeout: timeout_duration,
                        });
                        finalized_sender
                            .send(())
                            .map_err(|_| network_connect_worker_failed())?;
                        drop(active_connection);
                        attempt.wait_completed().await;
                        if attempt.is_cancelled() {
                            Err(network_connect_cancelled())
                        } else {
                            Ok(())
                        }
                    }
                }
            }
            Ok(Ok(Err(error))) => Err(error),
            Ok(Err(_)) => Err(network_connect_worker_failed()),
            Err(_) => {
                self.cancel_connection_attempt(false).await;
                Err(network_connect_timeout())
            }
        }
    }

    pub async fn offline_mode(&self) -> std::result::Result<(), NativeXelisError> {
        self.cancel_connection_attempt(false).await;
        let active = self.active_connection.lock().await.take();
        let timeout_duration = active
            .as_ref()
            .map_or(DEFAULT_ONLINE_MODE_TIMEOUT, |connection| connection.timeout);
        if let Some(connection) = active {
            connection.api.client().set_auto_reconnect_delay(None).await;
            disconnect_daemon_api(connection.api.as_ref()).await;
        }
        // With application-owned reconnection, the upstream handler runs with
        // auto-reconnect disabled. A failed worker emits SyncError then Offline,
        // disconnects its daemon API, and only afterwards returns its original
        // DaemonAPIError. `set_offline_mode` removes that finished handler before
        // awaiting it, so replaying the old error here would make an idempotent
        // disconnect look like a fresh failure and could stop the next retry.
        match timeout(timeout_duration, self.wallet.set_offline_mode()).await {
            Ok(result) => normalize_offline_mode_result(result),
            Err(_) => Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::Network,
                "NETWORK_DISCONNECT_TIMEOUT",
                "Native wallet disconnection exceeded its configured caller limit",
            )),
        }
    }

    pub async fn is_online(&self) -> bool {
        self.wallet.is_online().await
    }

    pub async fn is_syncing(&self) -> bool {
        let storage = self.wallet.get_storage().read().await;
        storage.is_syncing()
    }

    #[frb(sync)]
    pub fn get_address_str(&self) -> String {
        self.wallet.get_address().to_string()
    }

    #[frb(sync)]
    pub fn get_network(&self) -> Network {
        self.wallet.get_network().clone()
    }

    pub async fn close(&self) {
        self.cancel_connection_attempt(true).await;
        let active = self.active_connection.lock().await.take();
        if let Some(connection) = active {
            connection.api.client().set_auto_reconnect_delay(None).await;
            disconnect_daemon_api(connection.api.as_ref()).await;
        }
        self.wallet.close().await;
    }

    pub async fn get_seed(
        &self,
        language_index: Option<usize>,
    ) -> std::result::Result<String, NativeXelisError> {
        let index = language_index.unwrap_or_default();
        self.wallet.get_seed(index).map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::Internal,
                "WALLET_SEED_READ_FAILED",
            )
        })
    }

    pub async fn get_nonce(&self) -> u64 {
        self.wallet.get_nonce().await
    }

    pub async fn is_valid_password(
        &self,
        password: String,
    ) -> std::result::Result<(), NativeXelisError> {
        self.wallet
            .is_valid_password(&password)
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_authentication_operation(
                    error,
                    NativeXelisErrorCode::Internal,
                    "WALLET_PASSWORD_VERIFICATION_FAILED",
                )
            })
    }

    pub async fn rescan(&self, topoheight: u64) -> std::result::Result<(), NativeXelisError> {
        self.wallet
            .rescan(topoheight, true)
            .await
            .map_err(NativeXelisError::from)
    }

    pub async fn get_daemon_info(&self) -> std::result::Result<WalletDaemonInfo, NativeXelisError> {
        let handler = {
            let guard = self.wallet.get_network_handler().lock().await;
            guard
                .clone()
                .ok_or_else(|| NativeXelisError::from(WalletError::NoNetworkHandler))?
        };
        let info = handler.get_api().get_info().await.map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::Network,
                "DAEMON_INFO_READ_FAILED",
            )
        })?;

        Ok(info.into())
    }
}

#[cfg(test)]
mod tests;
