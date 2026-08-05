use std::io::Write;

#[cfg(not(target_arch = "wasm32"))]
use std::path::Path;
#[cfg(not(target_arch = "wasm32"))]
use tempfile::NamedTempFile;

use super::super::models::wallet_dtos::{
    ExactIntegratedHistoryDestination, HistoryPageFilter, PreparedHistoryFilter,
};
use super::business_events::{pending_transaction, transaction_entry, ExtraDataProjection};
use super::XelisWallet;
use crate::api::{
    error::{NativeXelisError, NativeXelisErrorCode},
    models::business_event_dtos::{NativeWalletPendingTransaction, NativeWalletTransactionEntry},
};
use anyhow::{Context, Result};
use xelis_common::crypto::{Hash, PublicKey};
use xelis_common::serializer::Serializer;
use xelis_wallet::entry::{EntryData, TransactionEntry};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct FilteredPagination {
    offset: usize,
    limit: Option<usize>,
}

impl FilteredPagination {
    fn prepare(options: &mut xelis_wallet::storage::TransactionFilterOptions<'_>) -> Result<Self> {
        let offset = options.skip.take().unwrap_or(0);
        let limit = options.limit;

        // ba7e020 applies `skip` before deserializing and filtering. Ask it
        // for the filtered prefix needed by this page, then skip locally.
        options.limit = limit
            .map(|limit| {
                offset
                    .checked_add(limit)
                    .context("Pagination range is too large")
            })
            .transpose()?;

        Ok(Self { offset, limit })
    }

    fn apply<T>(self, values: Vec<T>) -> Vec<T> {
        match self.limit {
            Some(limit) => values.into_iter().skip(self.offset).take(limit).collect(),
            None => values,
        }
    }
}

/// Applies the information that the locked upstream storage filter cannot
/// represent: an exact integrated destination rather than only its public key.
///
/// Incoming entries have no stored destination because the current wallet is
/// implicit. They can therefore match only when the integrated base address is
/// this wallet's public key. Outgoing entries retain only transfers whose
/// destination key and canonical protocol data both match.
fn apply_exact_integrated_destination(
    mut transactions: Vec<TransactionEntry>,
    destination: &ExactIntegratedHistoryDestination,
    wallet_public_key: &PublicKey,
) -> Vec<TransactionEntry> {
    let accepts_incoming = destination.matches_wallet(wallet_public_key);

    transactions.retain_mut(|transaction| match transaction.get_mut_entry() {
        EntryData::Incoming { transfers, .. } if accepts_incoming => {
            transfers.retain(|transfer| {
                destination.matches(
                    wallet_public_key,
                    transfer
                        .get_extra_data()
                        .as_ref()
                        .and_then(|extra_data| extra_data.data()),
                )
            });
            !transfers.is_empty()
        }
        EntryData::Outgoing { transfers, .. } => {
            transfers.retain(|transfer| {
                destination.matches(
                    transfer.get_destination(),
                    transfer
                        .get_extra_data()
                        .as_ref()
                        .and_then(|extra_data| extra_data.data()),
                )
            });
            !transfers.is_empty()
        }
        _ => false,
    });

    transactions
}

fn classify_history_error(
    error: anyhow::Error,
    fallback_code: NativeXelisErrorCode,
    fallback_kind: &'static str,
) -> NativeXelisError {
    NativeXelisError::from_wallet_operation(error, fallback_code, fallback_kind)
}

fn ensure_transactions_to_export(
    transaction_count: usize,
) -> std::result::Result<(), NativeXelisError> {
    if transaction_count == 0 {
        return Err(NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::NotFound,
            "WALLET_HISTORY_CSV_EMPTY",
            "No matching transactions are available for CSV export",
        ));
    }

    Ok(())
}

#[cfg(not(target_arch = "wasm32"))]
fn csv_path_error(
    error: impl std::fmt::Display,
    destination: &Path,
    native_kind: &'static str,
    action: &'static str,
) -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::Storage,
        native_kind,
        format!("{action}; path={}: {error}", destination.display()),
    )
}

#[cfg(not(target_arch = "wasm32"))]
fn create_temporary_csv_file(
    destination: &Path,
) -> std::result::Result<NamedTempFile, NativeXelisError> {
    let directory = destination
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));

    NamedTempFile::new_in(directory).map_err(|error| {
        csv_path_error(
            error,
            destination,
            "WALLET_HISTORY_CSV_TEMP_FILE_CREATE_FAILED",
            "Unable to create the temporary CSV file",
        )
    })
}

#[cfg(not(target_arch = "wasm32"))]
fn persist_csv_file(
    mut temporary: NamedTempFile,
    destination: &Path,
) -> std::result::Result<(), NativeXelisError> {
    temporary.as_file_mut().sync_all().map_err(|error| {
        csv_path_error(
            error,
            destination,
            "WALLET_HISTORY_CSV_SYNC_FAILED",
            "Unable to sync the temporary CSV file",
        )
    })?;
    temporary.persist(destination).map_err(|error| {
        csv_path_error(
            error.error,
            destination,
            "WALLET_HISTORY_CSV_REPLACE_FAILED",
            "Unable to atomically replace the CSV file",
        )
    })?;
    Ok(())
}

impl XelisWallet {
    pub async fn get_history_count(&self) -> std::result::Result<usize, NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;
        storage.get_transactions_count().map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::Storage,
                "WALLET_HISTORY_COUNT_READ_FAILED",
            )
        })
    }

    pub async fn history(
        &self,
        filter: HistoryPageFilter,
        include_extra_data_payload: bool,
    ) -> std::result::Result<Vec<NativeWalletTransactionEntry>, NativeXelisError> {
        let mut txs = Vec::new();
        let PreparedHistoryFilter {
            mut options,
            exact_integrated_destination,
        } = filter.prepare().map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::InvalidInput,
                "WALLET_HISTORY_FILTER_INVALID",
            )
        })?;
        let pagination = FilteredPagination::prepare(&mut options).map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::InvalidInput,
                "WALLET_HISTORY_FILTER_INVALID",
            )
        })?;
        if exact_integrated_destination.is_some() {
            // The exact-data filter runs below. Limiting the base-filtered
            // prefix here could consume a page with non-matching payloads.
            options.limit = None;
        }

        let storage = self.wallet.get_storage().read().await;

        let mut transactions = storage
            .get_filtered_transactions(options)
            .map_err(|error| {
                classify_history_error(
                    error,
                    NativeXelisErrorCode::Storage,
                    "WALLET_HISTORY_READ_FAILED",
                )
            })?;
        if let Some(destination) = exact_integrated_destination.as_ref() {
            transactions = apply_exact_integrated_destination(
                transactions,
                destination,
                self.wallet.get_address().get_public_key(),
            );
        }
        let mainnet = self.wallet.get_network().is_mainnet();
        let projection = ExtraDataProjection::explicit(include_extra_data_payload);

        for tx in pagination.apply(transactions) {
            txs.push(
                transaction_entry(tx.serializable(mainnet), projection).map_err(|error| {
                    classify_history_error(
                        error,
                        NativeXelisErrorCode::Serialization,
                        "WALLET_HISTORY_EXTRA_DATA_SERIALIZATION_FAILED",
                    )
                })?,
            );
        }

        Ok(txs)
    }

    pub async fn get_pending_transactions(
        &self,
        include_extra_data_payload: bool,
    ) -> std::result::Result<Vec<NativeWalletPendingTransaction>, NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;
        let mainnet = self.wallet.get_network().is_mainnet();
        let projection = ExtraDataProjection::explicit(include_extra_data_payload);

        storage
            .get_pending_txs()
            .iter()
            .cloned()
            .map(|tx| {
                pending_transaction(tx.serializable(mainnet), projection).map_err(|error| {
                    classify_history_error(
                        error,
                        NativeXelisErrorCode::Serialization,
                        "WALLET_PENDING_EXTRA_DATA_SERIALIZATION_FAILED",
                    )
                })
            })
            .collect()
    }

    pub async fn get_transaction_by_hash(
        &self,
        hash: String,
        include_extra_data_payload: bool,
    ) -> std::result::Result<NativeWalletTransactionEntry, NativeXelisError> {
        let hash = Hash::from_hex(&hash).map_err(|error| {
            classify_history_error(
                error.into(),
                NativeXelisErrorCode::InvalidInput,
                "WALLET_TRANSACTION_HASH_INVALID",
            )
        })?;
        let storage = self.wallet.get_storage().read().await;
        let transaction = storage.get_transaction(&hash).map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::NotFound,
                "WALLET_TRANSACTION_NOT_FOUND",
            )
        })?;

        transaction_entry(
            transaction.serializable(self.wallet.get_network().is_mainnet()),
            ExtraDataProjection::explicit(include_extra_data_payload),
        )
        .map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::Serialization,
                "WALLET_TRANSACTION_EXTRA_DATA_SERIALIZATION_FAILED",
            )
        })
    }

    pub async fn get_pending_transaction_by_hash(
        &self,
        hash: String,
        include_extra_data_payload: bool,
    ) -> std::result::Result<NativeWalletPendingTransaction, NativeXelisError> {
        let hash = Hash::from_hex(&hash).map_err(|error| {
            classify_history_error(
                error.into(),
                NativeXelisErrorCode::InvalidInput,
                "WALLET_TRANSACTION_HASH_INVALID",
            )
        })?;
        let storage = self.wallet.get_storage().read().await;
        let transaction = storage
            .get_pending_txs()
            .iter()
            .find(|transaction| transaction.hash == hash)
            .cloned()
            .ok_or_else(|| {
                NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::NotFound,
                    "WALLET_PENDING_TRANSACTION_NOT_FOUND",
                    "Pending transaction was not found in wallet storage",
                )
            })?;

        pending_transaction(
            transaction.serializable(self.wallet.get_network().is_mainnet()),
            ExtraDataProjection::explicit(include_extra_data_payload),
        )
        .map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::Serialization,
                "WALLET_PENDING_TRANSACTION_EXTRA_DATA_SERIALIZATION_FAILED",
            )
        })
    }

    #[cfg(not(target_arch = "wasm32"))]
    pub async fn export_transactions_to_csv_file(
        &self,
        file_path: String,
        filter: HistoryPageFilter,
    ) -> std::result::Result<(), NativeXelisError> {
        let path = Path::new(&file_path);
        let mut temporary = create_temporary_csv_file(path)?;
        self.export_csv_transactions(filter, &mut temporary).await?;
        persist_csv_file(temporary, path)
    }

    #[cfg(target_arch = "wasm32")]
    pub async fn export_transactions_to_csv_file(
        &self,
        _file_path: String,
        _filter: HistoryPageFilter,
    ) -> std::result::Result<(), NativeXelisError> {
        Err(NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Unsupported,
            "WALLET_HISTORY_CSV_FILE_EXPORT_UNSUPPORTED",
            "Native CSV file export is unavailable on Web; convert the history to CSV and use a browser download",
        ))
    }

    pub async fn convert_transactions_to_csv(
        &self,
        filter: HistoryPageFilter,
    ) -> std::result::Result<String, NativeXelisError> {
        let mut buffer = Vec::new();

        self.export_csv_transactions(filter, &mut buffer).await?;
        String::from_utf8(buffer).map_err(|error| {
            NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::Serialization,
                "WALLET_HISTORY_CSV_ENCODING_FAILED",
                format!("Unable to convert the CSV export to UTF-8: {error}"),
            )
        })
    }

    async fn export_csv_transactions(
        &self,
        filter: HistoryPageFilter,
        writer: &mut impl Write,
    ) -> std::result::Result<(), NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;
        let PreparedHistoryFilter {
            mut options,
            exact_integrated_destination,
        } = filter.prepare().map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::InvalidInput,
                "WALLET_HISTORY_CSV_FILTER_INVALID",
            )
        })?;
        let pagination = FilteredPagination::prepare(&mut options).map_err(|error| {
            classify_history_error(
                error,
                NativeXelisErrorCode::InvalidInput,
                "WALLET_HISTORY_CSV_FILTER_INVALID",
            )
        })?;
        if exact_integrated_destination.is_some() {
            options.limit = None;
        }
        let mut transactions = storage
            .get_filtered_transactions(options)
            .map_err(|error| {
                classify_history_error(
                    error,
                    NativeXelisErrorCode::Storage,
                    "WALLET_HISTORY_CSV_READ_FAILED",
                )
            })?;
        if let Some(destination) = exact_integrated_destination.as_ref() {
            transactions = apply_exact_integrated_destination(
                transactions,
                destination,
                self.wallet.get_address().get_public_key(),
            );
        }
        let transactions = pagination.apply(transactions);

        ensure_transactions_to_export(transactions.len())?;

        self.wallet
            .export_transactions_in_csv(&storage, transactions, writer)
            .await
            .map_err(|error| {
                classify_history_error(
                    error.into(),
                    NativeXelisErrorCode::Serialization,
                    "WALLET_HISTORY_CSV_SERIALIZATION_FAILED",
                )
            })
    }
}

#[cfg(test)]
mod tests;
