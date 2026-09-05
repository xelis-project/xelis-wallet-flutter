use flutter_rust_bridge::frb;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use self::multisig::PendingMultisigStore;
use super::error::NativeXelisError;
use super::models::wallet_dtos::NativeMultisigSigningTransaction;
use super::precomputed_tables::PrecomputedTableType;
use super::xswd::XswdSessionRegistry;
use anyhow::Result;
use futures::lock::Mutex as AsyncMutex;
use parking_lot::{Mutex, RwLock};
use xelis_common::network::Network;
use xelis_common::tokio::sync::{Mutex as TokioMutex, Notify};
use xelis_common::transaction::builder::UnsignedTransaction;
use xelis_common::transaction::MultiSigPayload;
pub use xelis_common::transaction::Transaction;
use xelis_wallet::daemon_api::DaemonAPI;
pub use xelis_wallet::precomputed_tables::PrecomputedTablesShared;
pub use xelis_wallet::transaction_builder::TransactionBuilderState;
use xelis_wallet::wallet::Wallet;

mod amounts;
mod assets;
pub mod business_events;
mod history;
mod multisig;
mod runtime;
pub mod runtime_events;
mod transactions;

#[frb(ignore)]
struct PendingMultisigTransaction {
    unsigned: UnsignedTransaction,
    state: TransactionBuilderState,
    configuration: MultiSigPayload,
    transaction_preview: NativeMultisigSigningTransaction,
}

#[frb(ignore)]
struct WalletConnectionAttempt {
    cancelled: AtomicBool,
    completed: AtomicBool,
    activation: TokioMutex<()>,
    api: TokioMutex<Option<Arc<DaemonAPI>>>,
    completion: Notify,
}

impl WalletConnectionAttempt {
    fn new() -> Self {
        Self {
            cancelled: AtomicBool::new(false),
            completed: AtomicBool::new(false),
            activation: TokioMutex::new(()),
            api: TokioMutex::new(None),
            completion: Notify::new(),
        }
    }

    fn cancel(&self) {
        self.cancelled.store(true, Ordering::Release);
    }

    fn is_cancelled(&self) -> bool {
        self.cancelled.load(Ordering::Acquire)
    }

    fn complete(&self) {
        self.completed.store(true, Ordering::Release);
        self.completion.notify_waiters();
    }

    async fn wait_completed(&self) {
        loop {
            if self.completed.load(Ordering::Acquire) {
                return;
            }
            let notified = self.completion.notified();
            if self.completed.load(Ordering::Acquire) {
                return;
            }
            notified.await;
        }
    }
}

#[derive(Default)]
#[frb(ignore)]
struct WalletConnectionAttemptState {
    current: Option<Arc<WalletConnectionAttempt>>,
    closed: bool,
}

#[derive(Default)]
#[frb(ignore)]
struct WalletConnectionAttempts {
    state: Mutex<WalletConnectionAttemptState>,
}

#[frb(ignore)]
struct ActiveWalletConnection {
    api: Arc<DaemonAPI>,
}

impl WalletConnectionAttempts {
    fn cancel_current(&self, terminal: bool) -> Option<Arc<WalletConnectionAttempt>> {
        let attempt = {
            let mut state = self.state.lock();
            if terminal {
                state.closed = true;
            }
            state.current.clone()
        };
        if let Some(attempt) = attempt.as_ref() {
            attempt.cancel();
        }
        attempt
    }
}

#[frb(opaque)]
pub struct XelisWallet {
    wallet: Arc<Wallet>,
    connection_attempts: Arc<WalletConnectionAttempts>,
    active_connection: TokioMutex<Option<ActiveWalletConnection>>,
    runtime_event_generation: Mutex<u64>,
    business_event_generation: Mutex<u64>,
    asset_resolution: AsyncMutex<()>,
    prepared_transaction:
        RwLock<transactions::PreparedTransactionStore<transactions::PreparedWalletTransaction>>,
    pending_multisig: RwLock<PendingMultisigStore<PendingMultisigTransaction>>,
    xswd_sessions: Arc<TokioMutex<XswdSessionRegistry>>,
}

impl Drop for XelisWallet {
    fn drop(&mut self) {
        self.connection_attempts.cancel_current(true);
    }
}

#[frb(sync)]
pub fn refresh_mt_params() {
    runtime::refresh_mt_params()
}

#[frb(sync)]
pub fn set_mt_params(thread_count: usize, concurrency: usize) {
    runtime::set_mt_params(thread_count, concurrency)
}

#[frb(sync)]
pub fn clear_cached_tables() {
    runtime::clear_cached_tables()
}

#[frb(sync)]
pub fn drop_wallet(wallet: XelisWallet) {
    runtime::drop_wallet(wallet)
}

pub async fn update_tables(
    precomputed_tables_path: String,
    precomputed_table_type: PrecomputedTableType,
) -> std::result::Result<(), NativeXelisError> {
    precomputed_table_type.to_l1_size().map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            super::error::NativeXelisErrorCode::InvalidInput,
            "PRECOMPUTED_TABLE_TYPE_INVALID",
            format!("{error:#}"),
        )
    })?;

    runtime::update_tables(precomputed_tables_path, precomputed_table_type)
        .await
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                super::error::NativeXelisErrorCode::Storage,
                "PRECOMPUTED_TABLES_UPDATE_FAILED",
            )
        })
}

pub fn get_current_precomputed_tables_type() -> Result<PrecomputedTableType> {
    runtime::get_current_precomputed_tables_type()
}

pub async fn create_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    seed: Option<String>,
    private_key: Option<String>,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> std::result::Result<XelisWallet, NativeXelisError> {
    runtime::create_xelis_wallet(
        name,
        directory,
        password,
        network,
        seed,
        private_key,
        precomputed_tables_path,
        precomputed_table_type,
    )
    .await
}

pub async fn open_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> std::result::Result<XelisWallet, NativeXelisError> {
    runtime::open_xelis_wallet(
        name,
        directory,
        password,
        network,
        precomputed_tables_path,
        precomputed_table_type,
    )
    .await
}

impl XelisWallet {
    #[cfg(test)]
    pub(crate) fn from_test_wallet(wallet: Arc<Wallet>) -> Self {
        Self {
            wallet,
            connection_attempts: Arc::new(WalletConnectionAttempts::default()),
            active_connection: Default::default(),
            runtime_event_generation: Default::default(),
            business_event_generation: Default::default(),
            asset_resolution: Default::default(),
            prepared_transaction: Default::default(),
            pending_multisig: Default::default(),
            xswd_sessions: Default::default(),
        }
    }

    #[frb(ignore)]
    pub(crate) fn xswd_sessions(&self) -> &Arc<TokioMutex<XswdSessionRegistry>> {
        &self.xswd_sessions
    }

    #[frb(ignore)]
    pub fn get_wallet(&self) -> &Arc<Wallet> {
        &self.wallet
    }

    pub fn clear_transaction(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        self.clear_transaction_internal(tx_hash)
    }
}
