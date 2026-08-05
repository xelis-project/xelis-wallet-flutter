use std::collections::HashMap;
use std::future::Future;

use super::super::models::wallet_dtos::{XelisAssetMetadata, XelisAssetOwner, XelisMaxSupplyMode};
use super::XelisWallet;
use crate::api::error::{NativeXelisError, NativeXelisErrorCode};
use anyhow::{Context, Result};
use futures::lock::Mutex as AsyncMutex;
use log::{debug, info};
use xelis_common::asset::AssetData;
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::Hash;
use xelis_common::serializer::Serializer;
use xelis_wallet::error::WalletError;

fn classify_asset_error(
    error: anyhow::Error,
    fallback_code: NativeXelisErrorCode,
    fallback_kind: &'static str,
) -> NativeXelisError {
    NativeXelisError::from_wallet_operation(error, fallback_code, fallback_kind)
}

fn classify_asset_storage_error(
    error: anyhow::Error,
    fallback_kind: &'static str,
) -> NativeXelisError {
    NativeXelisError::from_wallet_storage_operation(error, fallback_kind)
}

pub(super) fn asset_metadata(asset_data: &AssetData) -> XelisAssetMetadata {
    XelisAssetMetadata {
        name: asset_data.get_name().to_owned(),
        ticker: asset_data.get_ticker().to_owned(),
        decimals: asset_data.get_decimals(),
        max_supply: XelisMaxSupplyMode::from(asset_data.get_max_supply()),
        owner: XelisAssetOwner::from(asset_data.get_owner()),
    }
}

fn resolve_asset_hash(asset_hash: Option<&str>) -> Result<Hash> {
    match asset_hash {
        Some(value) => Hash::from_hex(value).context("Invalid asset"),
        None => Ok(XELIS_ASSET),
    }
}

async fn resolve_asset_data<Load, LoadFuture, Fetch, FetchFuture, Persist, PersistFuture>(
    resolution_lock: &AsyncMutex<()>,
    mut load_cached: Load,
    fetch_from_daemon: Fetch,
    persist: Persist,
) -> Result<AssetData>
where
    Load: FnMut() -> LoadFuture,
    LoadFuture: Future<Output = Result<Option<AssetData>>>,
    Fetch: FnOnce() -> FetchFuture,
    FetchFuture: Future<Output = Result<AssetData>>,
    Persist: FnOnce(AssetData) -> PersistFuture,
    PersistFuture: Future<Output = Result<AssetData>>,
{
    if let Some(asset_data) = load_cached().await? {
        return Ok(asset_data);
    }

    let _resolution_guard = resolution_lock.lock().await;

    // Another request may have persisted the asset while this one waited.
    if let Some(asset_data) = load_cached().await? {
        return Ok(asset_data);
    }

    let asset_data = fetch_from_daemon().await?;
    persist(asset_data).await
}

impl XelisWallet {
    pub async fn has_asset_balance(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let storage = self.wallet.get_storage().read().await;
        storage.has_balance_for(&asset_hash).await
    }

    pub async fn get_xelis_balance(&self) -> std::result::Result<u64, NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;
        let has_balance = storage
            .has_balance_for(&XELIS_ASSET)
            .await
            .map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::Storage,
                    "WALLET_XELIS_BALANCE_READ_FAILED",
                )
            })?;
        if has_balance {
            storage
                .get_plaintext_balance_for(&XELIS_ASSET)
                .await
                .map_err(|error| {
                    classify_asset_error(
                        error,
                        NativeXelisErrorCode::Storage,
                        "WALLET_XELIS_BALANCE_READ_FAILED",
                    )
                })
        } else {
            Ok(0)
        }
    }

    pub async fn get_tracked_balances(
        &self,
    ) -> std::result::Result<HashMap<String, u64>, NativeXelisError> {
        let mut balances = HashMap::new();

        let storage = self.wallet.get_storage().read().await;

        let tracked_assets = storage.get_tracked_assets().map_err(|error| {
            classify_asset_error(
                error,
                NativeXelisErrorCode::Storage,
                "WALLET_TRACKED_BALANCES_READ_FAILED",
            )
        })?;
        for result in tracked_assets {
            let asset = result.map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::Storage,
                    "WALLET_TRACKED_BALANCES_READ_FAILED",
                )
            })?;
            let has_balance = storage.has_balance_for(&asset).await.map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::Storage,
                    "WALLET_TRACKED_BALANCES_READ_FAILED",
                )
            })?;
            let balance = if has_balance {
                storage
                    .get_plaintext_balance_for(&asset)
                    .await
                    .map_err(|error| {
                        classify_asset_error(
                            error,
                            NativeXelisErrorCode::Storage,
                            "WALLET_TRACKED_BALANCES_READ_FAILED",
                        )
                    })?
            } else {
                0
            };
            info!("Retrieving atomic balance for asset {}", asset);
            balances.insert(asset.to_hex(), balance);
        }

        Ok(balances)
    }

    pub async fn get_known_assets(
        &self,
    ) -> std::result::Result<HashMap<String, XelisAssetMetadata>, NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;

        let mut assets = HashMap::new();

        let assets_with_data = storage.get_assets_with_data().await.map_err(|error| {
            classify_asset_error(
                error,
                NativeXelisErrorCode::Storage,
                "WALLET_KNOWN_ASSETS_READ_FAILED",
            )
        })?;
        for result in assets_with_data {
            let (hash, asset_data) = result.map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::Storage,
                    "WALLET_KNOWN_ASSETS_READ_FAILED",
                )
            })?;

            info!("Retrieving asset data for asset {}", hash);
            assets.insert(hash.to_hex(), asset_metadata(&asset_data));
        }

        Ok(assets)
    }

    pub async fn track_asset(&self, asset: String) -> std::result::Result<bool, NativeXelisError> {
        let asset_hash = Hash::from_hex(&asset)
            .context("Invalid asset")
            .map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "WALLET_ASSET_HASH_INVALID",
                )
            })?;
        self.wallet
            .track_asset(asset_hash)
            .await
            .context("Error tracking asset")
            .map_err(|error| classify_asset_storage_error(error, "WALLET_ASSET_TRACK_FAILED"))
    }

    pub async fn untrack_asset(
        &self,
        asset: String,
    ) -> std::result::Result<bool, NativeXelisError> {
        let asset_hash = Hash::from_hex(&asset)
            .context("Invalid asset")
            .map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "WALLET_ASSET_HASH_INVALID",
                )
            })?;
        self.wallet
            .untrack_asset(asset_hash)
            .await
            .context("Error untracking asset")
            .map_err(|error| classify_asset_storage_error(error, "WALLET_ASSET_UNTRACK_FAILED"))
    }

    pub async fn get_asset_decimals(&self, asset: String) -> Result<u8> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let data = self.get_asset_data(&asset_hash).await?;
        Ok(data.get_decimals())
    }

    pub async fn get_asset_ticker(&self, asset: String) -> Result<String> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let data = self.get_asset_data(&asset_hash).await?;
        Ok(data.get_ticker().to_string())
    }

    pub async fn get_asset_metadata(
        &self,
        asset: String,
    ) -> std::result::Result<XelisAssetMetadata, NativeXelisError> {
        let asset_hash = Hash::from_hex(&asset)
            .context("Invalid asset")
            .map_err(|error| {
                classify_asset_error(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "WALLET_ASSET_HASH_INVALID",
                )
            })?;
        let asset_data = self.get_asset_data(&asset_hash).await.map_err(|error| {
            classify_asset_storage_error(error, "WALLET_ASSET_METADATA_READ_FAILED")
        })?;

        Ok(asset_metadata(&asset_data))
    }

    pub async fn format_coin(
        &self,
        atomic_amount: u64,
        asset_hash: Option<String>,
    ) -> Result<String> {
        let asset = resolve_asset_hash(asset_hash.as_deref())?;

        let data = self.get_asset_data(&asset).await?;
        Ok(xelis_common::utils::format_coin(
            atomic_amount,
            data.get_decimals(),
        ))
    }

    async fn get_asset_data(&self, asset_hash: &Hash) -> Result<AssetData> {
        resolve_asset_data(
            &self.asset_resolution,
            || async {
                let storage = self.wallet.get_storage().read().await;
                storage
                    .get_optional_asset(asset_hash)
                    .await
                    .context("Error reading asset from wallet storage")
            },
            || async {
                if !self.wallet.is_online().await {
                    return Err(
                        anyhow::Error::new(WalletError::NotOnlineMode).context(format!(
                            "Asset {} not found in wallet storage/cache",
                            asset_hash
                        )),
                    );
                }

                let network_handler = self.wallet.get_network_handler().lock().await;
                let handler = network_handler
                    .as_ref()
                    .ok_or_else(|| anyhow::Error::new(WalletError::NoNetworkHandler))?;

                debug!("Fetching asset {} from daemon", asset_hash);
                let data = handler
                    .get_api()
                    .get_asset(asset_hash)
                    .await
                    .context("Failed to fetch asset from daemon")?;

                Ok(data.inner)
            },
            |asset_data| async move {
                debug!(
                    "Storing fetched asset {} from network in wallet storage",
                    asset_hash
                );

                let mut storage = self.wallet.get_storage().write().await;
                storage
                    .add_asset(asset_hash, asset_data.clone())
                    .await
                    .context("Error storing fetched asset in wallet storage")?;

                debug!("Asset {} stored in wallet storage", asset_hash);
                Ok(asset_data)
            },
        )
        .await
    }
}

#[cfg(test)]
mod tests;
