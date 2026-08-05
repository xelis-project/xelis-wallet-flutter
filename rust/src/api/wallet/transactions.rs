use super::super::error::{NativeXelisError, NativeXelisErrorCode};
use super::super::models::wallet_dtos::{
    BroadcastTransactionOutcome, NativePreparedTransaction,
    NativePreparedTransactionBroadcastOutcome, NativePreparedTransactionKind,
    NativePreparedTransferExtraData, NativeTransactionFeePolicy, NativeTransactionTransferRequest,
    Transfer,
};
use super::{amounts, Transaction, TransactionBuilderState, XelisWallet};
use anyhow::{Context, Result};
use log::{error, info};
use parking_lot::RwLock;
use std::future::Future;
use xelis_common::api::wallet::BaseFeeMode;
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{Address, Hash, Hashable};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{FeeBuilder, TransactionTypeBuilder};
use xelis_common::utils::format_coin;
use xelis_wallet::error::WalletError;

mod builders;
mod prepared;
mod submission;

pub(super) use builders::{
    amount_after_fee, apply_fee_policy, build_atomic_transfers, build_burn_all_type,
    build_burn_type, build_transfer, build_transfer_all_type, create_transfers,
    parse_transaction_asset, parse_transaction_destination,
};
use builders::{project_prepared_transfer, transaction_summary_json};
pub(super) use prepared::PreparedTransactionPreparationGuard;
pub(super) use prepared::PreparedTransactionStore;
use prepared::{PreparedTransactionError, PreparedTransactionGuard};
use submission::{ensure_wallet_online, resolve_submission, SubmissionResolution};

/// Native value retained in the single prepared slot.
///
/// Review extra data is deliberately stored beside the exact transaction and
/// its builder state so replacement, cancellation, submission, and retry all
/// have the same lifecycle and generation guard.
pub(super) struct PreparedWalletTransaction {
    transaction: Transaction,
    state: TransactionBuilderState,
    review_extra_data: Vec<Option<NativePreparedTransferExtraData>>,
}

impl PreparedWalletTransaction {
    fn new(
        transaction: Transaction,
        state: TransactionBuilderState,
        review_extra_data: Vec<Option<NativePreparedTransferExtraData>>,
    ) -> Self {
        Self {
            transaction,
            state,
            review_extra_data,
        }
    }

    pub(super) fn without_review_extra_data(
        transaction: Transaction,
        state: TransactionBuilderState,
    ) -> Self {
        Self::new(transaction, state, Vec::new())
    }

    fn transaction_and_state(&self) -> (&Transaction, &TransactionBuilderState) {
        (&self.transaction, &self.state)
    }

    fn into_transaction_and_state(self) -> (Transaction, TransactionBuilderState) {
        (self.transaction, self.state)
    }

    fn review_extra_data(&self, transfer_index: usize) -> Option<&NativePreparedTransferExtraData> {
        self.review_extra_data
            .get(transfer_index)
            .and_then(Option::as_ref)
    }

    fn transfer_count(&self) -> usize {
        self.review_extra_data.len()
    }
}

async fn build_and_store_prepared<T, Build, BuildFuture>(
    store: &RwLock<PreparedTransactionStore<T>>,
    transaction_type: TransactionTypeBuilder,
    build: Build,
) -> Result<String>
where
    Build: FnOnce(TransactionTypeBuilder) -> BuildFuture,
    BuildFuture: Future<Output = Result<(Hash, u64, T)>>,
{
    let (hash, fee, prepared) = build(transaction_type.clone()).await?;
    let summary = transaction_summary_json(&hash, fee, transaction_type);
    store.write().replace(hash, prepared)?;

    Ok(summary)
}

pub(super) fn prepared_transaction_error(error: PreparedTransactionError) -> NativeXelisError {
    let code = match error {
        PreparedTransactionError::PreparationInProgress
        | PreparedTransactionError::ReplacementDuringSubmission
        | PreparedTransactionError::CancellationDuringSubmission
        | PreparedTransactionError::AlreadySubmitting => NativeXelisErrorCode::OperationInProgress,
        PreparedTransactionError::CannotDelete | PreparedTransactionError::NotFound => {
            NativeXelisErrorCode::NotFound
        }
        PreparedTransactionError::GenerationOverflow
        | PreparedTransactionError::PreparationStateInconsistent
        | PreparedTransactionError::CancellationStateInconsistent
        | PreparedTransactionError::SubmissionStateInconsistent
        | PreparedTransactionError::EmptyGuard => NativeXelisErrorCode::Internal,
    };

    NativeXelisError::xelis_wallet_flutter(code, error.native_kind(), error.to_string())
}

fn invalid_prepared_transaction_hash() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::InvalidInput,
        "PREPARED_TRANSACTION_HASH_INVALID",
        "Prepared transaction hash is not valid hexadecimal data",
    )
}

fn offline_prepared_transaction_outcome<T>(
    store: &RwLock<PreparedTransactionStore<T>>,
    preparation_id: u64,
    hash: &Hash,
) -> std::result::Result<NativePreparedTransactionBroadcastOutcome, NativeXelisError> {
    store
        .read()
        .ensure_ready_exact(preparation_id, hash)
        .map_err(prepared_transaction_error)?;
    Ok(NativePreparedTransactionBroadcastOutcome::Retryable {
        failure: NativeXelisError::from(WalletError::NotOnlineMode),
    })
}

impl XelisWallet {
    async fn create_and_store_prepared_transaction(
        &self,
        transaction_type: TransactionTypeBuilder,
        action: &'static str,
    ) -> Result<String> {
        build_and_store_prepared(
            &self.prepared_transaction,
            transaction_type,
            |transaction_type| async move {
                let (tx, state) = {
                    let mut storage = self.wallet.get_storage().write().await;
                    self.wallet
                        .create_transaction_with_storage(
                            &mut storage,
                            transaction_type,
                            FeeBuilder::default(),
                            BaseFeeMode::None,
                            None,
                        )
                        .await?
                };

                info!("Transaction created!");
                let hash = tx.hash();
                info!("Tx Hash: {}", hash);
                let fee = tx.get_fee();
                log_transaction_context(action, &tx, &state);

                Ok((
                    hash,
                    fee,
                    PreparedWalletTransaction::without_review_extra_data(tx, state),
                ))
            },
        )
        .await
    }

    pub(super) async fn estimate_target_fee(
        &self,
        transaction_type: TransactionTypeBuilder,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<u64, NativeXelisError> {
        let base_fee = self
            .wallet
            .estimate_fees(transaction_type, FeeBuilder::default(), BaseFeeMode::None)
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error.into(),
                    NativeXelisErrorCode::OperationFailed,
                    "TRANSACTION_FEE_ESTIMATION_FAILED",
                )
            })?;

        apply_fee_policy(base_fee, fee_policy)
    }

    pub(super) async fn create_and_commit_prepared_transaction(
        &self,
        preparation: PreparedTransactionPreparationGuard<'_, PreparedWalletTransaction>,
        transaction_type: TransactionTypeBuilder,
        transaction: NativePreparedTransactionKind,
        review_extra_data: Vec<Option<NativePreparedTransferExtraData>>,
        target_fee: u64,
        action: &'static str,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type,
                    FeeBuilder::Fixed(target_fee),
                    BaseFeeMode::None,
                    None,
                )
                .await
                .map_err(|error| {
                    NativeXelisError::from_wallet_operation(
                        error.into(),
                        NativeXelisErrorCode::OperationFailed,
                        "PREPARED_TRANSACTION_CREATION_FAILED",
                    )
                })?
        };

        let hash = tx.hash();
        let fee = tx.get_fee();
        if fee != target_fee {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::Internal,
                "PREPARED_TRANSACTION_FEE_MISMATCH",
                format!("Prepared fee {fee} differs from requested fixed fee {target_fee}"),
            ));
        }
        log_transaction_context(action, &tx, &state);
        let preparation_id = preparation
            .commit(
                hash.clone(),
                PreparedWalletTransaction::new(tx, state, review_extra_data),
            )
            .map_err(prepared_transaction_error)?;

        Ok(NativePreparedTransaction {
            hash: hash.to_hex(),
            preparation_id,
            fee,
            transaction,
        })
    }

    pub async fn estimate_transfer_fees_atomic(
        &self,
        transfers: Vec<NativeTransactionTransferRequest>,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<u64, NativeXelisError> {
        apply_fee_policy(0, fee_policy)?;
        let (transaction_type, _, _) = build_atomic_transfers(transfers)?;
        self.estimate_target_fee(transaction_type, fee_policy).await
    }

    pub async fn prepare_transfers_transaction(
        &self,
        transfers: Vec<NativeTransactionTransferRequest>,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        apply_fee_policy(0, fee_policy)?;
        let preparation = PreparedTransactionPreparationGuard::begin(&self.prepared_transaction)
            .map_err(prepared_transaction_error)?;
        let (transaction_type, transaction, review_extra_data) = build_atomic_transfers(transfers)?;
        let target_fee = self
            .estimate_target_fee(transaction_type.clone(), fee_policy)
            .await?;

        self.create_and_commit_prepared_transaction(
            preparation,
            transaction_type,
            transaction,
            review_extra_data,
            target_fee,
            "Prepared stable transfer transaction",
        )
        .await
    }

    pub async fn prepare_transfer_all_transaction(
        &self,
        destination: String,
        asset: String,
        extra_data: Option<String>,
        encrypt_extra_data: bool,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        apply_fee_policy(0, fee_policy)?;
        let preparation = PreparedTransactionPreparationGuard::begin(&self.prepared_transaction)
            .map_err(prepared_transaction_error)?;
        let asset = parse_transaction_asset(&asset)?;
        let destination = parse_transaction_destination(&destination)?;
        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage
                .get_plaintext_balance_for(&asset)
                .await
                .map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "TRANSFER_ALL_BALANCE_READ_FAILED",
                    )
                })?
        };
        let estimated_transaction = build_transfer_all_type(
            destination.clone(),
            balance,
            0,
            asset.clone(),
            extra_data.clone(),
            Some(encrypt_extra_data),
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InsufficientFunds,
                "TRANSFER_ALL_BALANCE_INSUFFICIENT",
            )
        })?;
        let target_fee = self
            .estimate_target_fee(estimated_transaction, fee_policy)
            .await?;
        let amount = amount_after_fee(balance, target_fee, &asset, "Insufficient balance for fees")
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InsufficientFunds,
                    "TRANSFER_ALL_BALANCE_INSUFFICIENT",
                )
            })?;
        let transaction_type = build_transfer_all_type(
            destination.clone(),
            balance,
            target_fee,
            asset.clone(),
            extra_data.clone(),
            Some(encrypt_extra_data),
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InsufficientFunds,
                "TRANSFER_ALL_BALANCE_INSUFFICIENT",
            )
        })?;
        let (prepared_transfer, prepared_extra_data) = project_prepared_transfer(
            &destination,
            &asset,
            amount,
            extra_data.as_deref(),
            encrypt_extra_data,
        )?;
        let transaction = NativePreparedTransactionKind::Transfers {
            transfers: vec![prepared_transfer],
        };

        self.create_and_commit_prepared_transaction(
            preparation,
            transaction_type,
            transaction,
            vec![prepared_extra_data],
            target_fee,
            "Prepared stable transfer all transaction",
        )
        .await
    }

    pub async fn prepare_burn_transaction(
        &self,
        amount: u64,
        asset: String,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        apply_fee_policy(0, fee_policy)?;
        let preparation = PreparedTransactionPreparationGuard::begin(&self.prepared_transaction)
            .map_err(prepared_transaction_error)?;
        if amount == 0 {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "TRANSACTION_AMOUNT_INVALID",
                "Burn amount must be greater than zero",
            ));
        }
        let asset = parse_transaction_asset(&asset)?;
        let transaction_type = build_burn_type(asset.clone(), amount);
        let target_fee = self
            .estimate_target_fee(transaction_type.clone(), fee_policy)
            .await?;
        let transaction = NativePreparedTransactionKind::Burn {
            asset: asset.to_hex(),
            amount,
        };

        self.create_and_commit_prepared_transaction(
            preparation,
            transaction_type,
            transaction,
            Vec::new(),
            target_fee,
            "Prepared stable burn transaction",
        )
        .await
    }

    pub async fn prepare_burn_all_transaction(
        &self,
        asset: String,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        apply_fee_policy(0, fee_policy)?;
        let preparation = PreparedTransactionPreparationGuard::begin(&self.prepared_transaction)
            .map_err(prepared_transaction_error)?;
        let asset = parse_transaction_asset(&asset)?;
        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage
                .get_plaintext_balance_for(&asset)
                .await
                .map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "BURN_ALL_BALANCE_READ_FAILED",
                    )
                })?
        };
        let estimated_transaction =
            build_burn_all_type(asset.clone(), balance, 0).map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InsufficientFunds,
                    "BURN_ALL_BALANCE_INSUFFICIENT",
                )
            })?;
        let target_fee = self
            .estimate_target_fee(estimated_transaction, fee_policy)
            .await?;
        let amount = amount_after_fee(
            balance,
            target_fee,
            &asset,
            "Insufficient balance to pay burn transaction fees",
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InsufficientFunds,
                "BURN_ALL_BALANCE_INSUFFICIENT",
            )
        })?;
        let transaction_type =
            build_burn_all_type(asset.clone(), balance, target_fee).map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InsufficientFunds,
                    "BURN_ALL_BALANCE_INSUFFICIENT",
                )
            })?;
        let transaction = NativePreparedTransactionKind::Burn {
            asset: asset.to_hex(),
            amount,
        };

        self.create_and_commit_prepared_transaction(
            preparation,
            transaction_type,
            transaction,
            Vec::new(),
            target_fee,
            "Prepared stable burn all transaction",
        )
        .await
    }

    pub async fn estimate_fees(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
        let transaction_type_builder = create_transfers(self, transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                transaction_type_builder,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        Ok(format_coin(estimated_fees, COIN_DECIMALS))
    }

    pub async fn create_transfers_transaction(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
        info!("Building transaction...");

        let transaction_type_builder = create_transfers(self, transfers)
            .await
            .context("Error while creating transaction type builder")?;

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared transfer transaction",
        )
        .await
    }

    pub async fn create_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        // TODO: add extra fee options
    ) -> Result<String> {
        info!("Building transfer all transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        let address = Address::from_string(&str_address).context("Invalid address")?;

        let estimated_transaction_type = build_transfer_all_type(
            address.clone(),
            balance,
            0,
            asset.clone(),
            extra_data.clone(),
            encrypt_extra_data,
        )?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                estimated_transaction_type,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        let transaction_type_builder = build_transfer_all_type(
            address,
            balance,
            estimated_fees,
            asset,
            extra_data,
            encrypt_extra_data,
        )?;

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared transfer all transaction",
        )
        .await
    }

    pub async fn create_burn_transaction(
        &self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        info!("Building burn transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (amount, decimals) = {
            let storage = self.wallet.get_storage().read().await;
            let decimals = storage
                .get_asset(&asset)
                .await
                .context("Asset not found in storage")?
                .get_decimals();
            let amount = amounts::checked_atomic_amount(float_amount, decimals)?;
            (amount, decimals)
        };

        info!("Burning {} of {}", format_coin(amount, decimals), asset);

        let transaction_type_builder = build_burn_type(asset, amount);

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared burn transaction",
        )
        .await
    }

    pub async fn create_burn_all_transaction(&self, asset_hash: String) -> Result<String> {
        info!("Building burn all transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        info!("Burning all {} of {}", balance, asset);

        let estimated_transaction_type = build_burn_all_type(asset.clone(), balance, 0)?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                estimated_transaction_type,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        let transaction_type_builder = build_burn_all_type(asset, balance, estimated_fees)?;

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared burn all transaction",
        )
        .await
    }

    pub(super) fn clear_transaction_internal(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        let hash = Hash::from_hex(&tx_hash)?;
        let prepared = self.prepared_transaction.write().cancel(&hash)?;

        info!("tx: {} removed from prepared transaction", hash);
        Ok(prepared.into_transaction_and_state())
    }

    pub fn inspect_prepared_transfer_extra_data(
        &self,
        preparation_id: u64,
        tx_hash: String,
        transfer_index: u32,
    ) -> std::result::Result<NativePreparedTransferExtraData, NativeXelisError> {
        let hash = Hash::from_hex(&tx_hash).map_err(|_| invalid_prepared_transaction_hash())?;
        let transfer_index = usize::try_from(transfer_index).map_err(|_| {
            NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "PREPARED_TRANSFER_INDEX_INVALID",
                "Prepared transfer index is outside the supported range",
            )
        })?;
        let prepared_store = self.prepared_transaction.read();
        let prepared_transaction = prepared_store
            .ready_exact(preparation_id, &hash)
            .map_err(prepared_transaction_error)?;

        if transfer_index >= prepared_transaction.transfer_count() {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "PREPARED_TRANSFER_INDEX_INVALID",
                format!(
                    "Prepared transfer index {transfer_index} is outside the transaction transfer count {}",
                    prepared_transaction.transfer_count()
                ),
            ));
        }

        prepared_transaction
            .review_extra_data(transfer_index)
            .cloned()
            .ok_or_else(|| {
                NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::NotFound,
                    "PREPARED_TRANSFER_EXTRA_DATA_NOT_FOUND",
                    "The selected prepared transfer does not contain extra data",
                )
            })
    }

    pub fn cancel_prepared_transaction(
        &self,
        preparation_id: u64,
        tx_hash: String,
    ) -> std::result::Result<(), NativeXelisError> {
        let hash = Hash::from_hex(&tx_hash).map_err(|_| invalid_prepared_transaction_hash())?;
        let _discarded = self
            .prepared_transaction
            .write()
            .cancel_exact(preparation_id, &hash)
            .map_err(prepared_transaction_error)?;
        info!(
            "Prepared transaction cancelled: hash={}, generation={}",
            hash, preparation_id
        );
        Ok(())
    }

    pub async fn broadcast_transaction(
        &self,
        tx_hash: String,
    ) -> Result<BroadcastTransactionOutcome> {
        info!("start to broadcast tx: {}", tx_hash);

        ensure_wallet_online(self.wallet.is_online().await)?;

        let (storage_tx_version, storage_topoheight, storage_top_block_hash) = {
            let storage = self.wallet.get_storage().read().await;
            (
                storage.get_tx_version().await?,
                storage.get_synced_topoheight()?,
                storage.get_top_block_hash()?,
            )
        };
        let hash = Hash::from_hex(&tx_hash)?;
        let prepared_transaction =
            PreparedTransactionGuard::take(&self.prepared_transaction, hash.clone())?;
        let (tx, state) = prepared_transaction.transaction()?.transaction_and_state();

        log_transaction_context("Broadcasting prepared transaction", tx, state);
        info!(
            "Broadcast storage context: tx_hash={}, storage_tx_version={}, synced_topoheight={}, top_block_hash={}",
            tx_hash, storage_tx_version, storage_topoheight, storage_top_block_hash
        );

        info!("Broadcasting transaction...");
        let submit_result = self.wallet.submit_transaction(tx).await;
        let resolution = resolve_submission(submit_result);

        match resolution {
            SubmissionResolution::Submitted => {
                let (tx, mut state) = prepared_transaction.finish()?.into_transaction_and_state();
                info!("Transaction submitted successfully!");
                let mut storage = self.wallet.get_storage().write().await;
                if let Err(error) = state
                    .apply_changes(&mut storage, self.wallet.as_ref(), &tx)
                    .await
                {
                    error!(
                        "Transaction was submitted but local state application failed: kind={}",
                        error.kind()
                    );
                    storage.delete_unconfirmed_balances().await;
                    return Ok(BroadcastTransactionOutcome::SubmittedNeedsResync);
                }
                info!("Transaction applied to storage");
                Ok(BroadcastTransactionOutcome::Submitted)
            }
            SubmissionResolution::Retryable(error) => {
                let kind = error.kind();
                prepared_transaction.restore()?;
                error!("Retryable transaction submission failure: kind={kind}");
                self.clear_unconfirmed_transaction_state().await;
                Ok(BroadcastTransactionOutcome::Retryable)
            }
            SubmissionResolution::DaemonRejected(error) => {
                let kind = error.kind();
                let _discarded = prepared_transaction.finish()?;
                error!("Daemon rejected transaction submission: kind={kind}");
                self.clear_unconfirmed_transaction_state().await;
                Ok(BroadcastTransactionOutcome::Rejected)
            }
            SubmissionResolution::LocalFailure(error) => {
                let kind = error.kind();
                let _discarded = prepared_transaction.finish()?;
                error!("Local transaction submission failure: kind={kind}");
                self.clear_unconfirmed_transaction_state().await;
                Ok(BroadcastTransactionOutcome::LocalFailure)
            }
        }
    }

    pub async fn broadcast_prepared_transaction(
        &self,
        preparation_id: u64,
        tx_hash: String,
    ) -> std::result::Result<NativePreparedTransactionBroadcastOutcome, NativeXelisError> {
        let hash = Hash::from_hex(&tx_hash).map_err(|_| invalid_prepared_transaction_hash())?;

        // Offline is an explicitly retryable outcome. Do not move the slot to
        // InFlight so the exact preparation capability remains valid.
        if !self.wallet.is_online().await {
            return offline_prepared_transaction_outcome(
                &self.prepared_transaction,
                preparation_id,
                &hash,
            );
        }

        let prepared_transaction = PreparedTransactionGuard::take_exact(
            &self.prepared_transaction,
            preparation_id,
            hash.clone(),
        )
        .map_err(prepared_transaction_error)?;
        let (storage_tx_version, storage_topoheight, storage_top_block_hash) = {
            let storage = self.wallet.get_storage().read().await;
            (
                storage.get_tx_version().await.map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "PREPARED_TRANSACTION_STORAGE_VERSION_READ_FAILED",
                    )
                })?,
                storage.get_synced_topoheight().map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "PREPARED_TRANSACTION_TOPOHEIGHT_READ_FAILED",
                    )
                })?,
                storage.get_top_block_hash().map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "PREPARED_TRANSACTION_TOP_BLOCK_READ_FAILED",
                    )
                })?,
            )
        };
        let (tx, state) = prepared_transaction
            .transaction()
            .map_err(prepared_transaction_error)?
            .transaction_and_state();

        log_transaction_context("Broadcasting stable prepared transaction", tx, state);
        info!(
            "Broadcast stable storage context: tx_hash={}, generation={}, storage_tx_version={}, synced_topoheight={}, top_block_hash={}",
            tx_hash,
            preparation_id,
            storage_tx_version,
            storage_topoheight,
            storage_top_block_hash
        );

        let resolution = resolve_submission(self.wallet.submit_transaction(tx).await);
        match resolution {
            SubmissionResolution::Submitted => {
                let (tx, mut state) = prepared_transaction
                    .finish()
                    .map_err(prepared_transaction_error)?
                    .into_transaction_and_state();
                let mut storage = self.wallet.get_storage().write().await;
                if let Err(error) = state
                    .apply_changes(&mut storage, self.wallet.as_ref(), &tx)
                    .await
                {
                    let failure = NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "PREPARED_TRANSACTION_LOCAL_APPLY_FAILED",
                    );
                    error!(
                        "Stable transaction was submitted but local state application failed: native_kind={}",
                        failure.native_kind.as_deref().unwrap_or("UNSPECIFIED")
                    );
                    storage.delete_unconfirmed_balances().await;
                    return Ok(
                        NativePreparedTransactionBroadcastOutcome::SubmittedNeedsResync { failure },
                    );
                }

                info!("Stable prepared transaction submitted and applied");
                Ok(NativePreparedTransactionBroadcastOutcome::Submitted)
            }
            SubmissionResolution::Retryable(error) => {
                let failure = NativeXelisError::from(error);
                prepared_transaction
                    .restore()
                    .map_err(prepared_transaction_error)?;
                self.clear_unconfirmed_transaction_state().await;
                Ok(NativePreparedTransactionBroadcastOutcome::Retryable { failure })
            }
            SubmissionResolution::DaemonRejected(error) => {
                let failure = NativeXelisError::from(error);
                let _discarded = prepared_transaction
                    .finish()
                    .map_err(prepared_transaction_error)?;
                self.clear_unconfirmed_transaction_state().await;
                Ok(NativePreparedTransactionBroadcastOutcome::Rejected { failure })
            }
            SubmissionResolution::LocalFailure(error) => {
                let failure = NativeXelisError::from(error);
                let _discarded = prepared_transaction
                    .finish()
                    .map_err(prepared_transaction_error)?;
                self.clear_unconfirmed_transaction_state().await;
                Ok(NativePreparedTransactionBroadcastOutcome::LocalFailure { failure })
            }
        }
    }

    async fn clear_unconfirmed_transaction_state(&self) {
        let mut storage = self.wallet.get_storage().write().await;
        storage.delete_unconfirmed_balances().await;
    }
}

pub(super) fn log_transaction_context(
    action: &str,
    tx: &Transaction,
    state: &TransactionBuilderState,
) {
    let tx_reference = tx.get_reference();
    let state_reference = state.get_reference();

    info!(
        "{}: hash={}, nonce={}, tx_version={}, tx_ref=({}, {}), state_nonce={}, state_ref=({}, {})",
        action,
        tx.hash(),
        tx.get_nonce(),
        tx.get_version(),
        tx_reference.topoheight,
        tx_reference.hash,
        state.get_nonce(),
        state_reference.topoheight,
        state_reference.hash
    );
}

#[cfg(test)]
mod tests;
