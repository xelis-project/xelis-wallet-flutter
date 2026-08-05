use anyhow::{anyhow, Result};
use futures::lock::Mutex as AsyncMutex;
use parking_lot::Mutex;
use xelis_common::asset::{AssetData, AssetOwner, MaxSupplyMode};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::Hash;

use super::{
    asset_metadata, classify_asset_error, classify_asset_storage_error, resolve_asset_data,
    resolve_asset_hash,
};
use crate::api::{
    error::{NativeXelisErrorCode, NativeXelisErrorSource},
    models::wallet_dtos::{XelisAssetOwner, XelisMaxSupplyMode},
};

enum CacheOutcome {
    Hit(AssetData),
    Miss,
    Error,
}

enum DaemonOutcome {
    Success(AssetData),
    Error,
}

struct FakeAssetDataSource {
    cache: Mutex<CacheOutcome>,
    daemon: DaemonOutcome,
    persistence_fails: bool,
    resolution_lock: AsyncMutex<()>,
    events: Mutex<Vec<&'static str>>,
    persisted: Mutex<Option<AssetData>>,
}

impl FakeAssetDataSource {
    fn new(cache: CacheOutcome, daemon: DaemonOutcome, persistence_fails: bool) -> Self {
        Self {
            cache: Mutex::new(cache),
            daemon,
            persistence_fails,
            resolution_lock: AsyncMutex::new(()),
            events: Mutex::new(Vec::new()),
            persisted: Mutex::new(None),
        }
    }

    async fn resolve(&self) -> Result<AssetData> {
        resolve_asset_data(
            &self.resolution_lock,
            || async {
                self.events.lock().push("cache");

                match &*self.cache.lock() {
                    CacheOutcome::Hit(asset_data) => Ok(Some(asset_data.clone())),
                    CacheOutcome::Miss => Ok(None),
                    CacheOutcome::Error => Err(anyhow!("cache failure")),
                }
            },
            || async {
                self.events.lock().push("daemon");
                tokio::task::yield_now().await;

                match &self.daemon {
                    DaemonOutcome::Success(asset_data) => Ok(asset_data.clone()),
                    DaemonOutcome::Error => Err(anyhow!("daemon failure")),
                }
            },
            |asset_data| async move {
                self.events.lock().push("persist");

                if self.persistence_fails {
                    return Err(anyhow!("persistence failure"));
                }

                *self.persisted.lock() = Some(asset_data.clone());
                *self.cache.lock() = CacheOutcome::Hit(asset_data.clone());
                Ok(asset_data)
            },
        )
        .await
    }
}

fn test_asset(name: &str, ticker: &str) -> AssetData {
    AssetData::new(
        8,
        name.to_owned(),
        ticker.to_owned(),
        MaxSupplyMode::Fixed(1_000_000),
        AssetOwner::None,
    )
}

mod errors;
mod models;
mod parsing;
mod resolution;
