use super::*;

#[test]
fn stable_asset_error_fallbacks_keep_code_source_and_native_kind() {
    let storage = classify_asset_error(
        anyhow!(r"database failure at C:\private\wallet.db"),
        NativeXelisErrorCode::Storage,
        "WALLET_KNOWN_ASSETS_READ_FAILED",
    );
    assert_eq!(storage.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(storage.code, NativeXelisErrorCode::Storage);
    assert_eq!(
        storage.native_kind.as_deref(),
        Some("WALLET_KNOWN_ASSETS_READ_FAILED")
    );
    assert!(!format!("{storage:?}").contains("private"));

    let invalid = classify_asset_error(
        anyhow!("invalid asset hash"),
        NativeXelisErrorCode::InvalidInput,
        "WALLET_ASSET_HASH_INVALID",
    );
    assert_eq!(invalid.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        invalid.native_kind.as_deref(),
        Some("WALLET_ASSET_HASH_INVALID")
    );
}

#[test]
fn asset_cache_persistence_and_wallet_any_failures_fallback_to_storage() {
    let cases = [
        (
            anyhow!("cache read failure"),
            "WALLET_ASSET_METADATA_READ_FAILED",
        ),
        (
            anyhow!("persistence failure"),
            "WALLET_ASSET_METADATA_READ_FAILED",
        ),
        (
            anyhow::Error::new(xelis_wallet::error::WalletError::from(anyhow!(
                "opaque tracking failure"
            ))),
            "WALLET_ASSET_TRACK_FAILED",
        ),
        (
            anyhow::Error::new(xelis_wallet::error::WalletError::from(anyhow!(
                "opaque untracking failure"
            ))),
            "WALLET_ASSET_UNTRACK_FAILED",
        ),
    ];

    for (error, native_kind) in cases {
        let classified = classify_asset_storage_error(error, native_kind);
        assert_eq!(classified.source, NativeXelisErrorSource::XelisWallet);
        assert_eq!(classified.code, NativeXelisErrorCode::Storage);
        assert_eq!(classified.native_kind.as_deref(), Some(native_kind));
    }
}

#[test]
fn asset_storage_fallback_preserves_typed_wallet_causes() {
    let classified = classify_asset_storage_error(
        anyhow::Error::new(xelis_wallet::error::WalletError::NotOnlineMode),
        "WALLET_ASSET_METADATA_READ_FAILED",
    );

    assert_eq!(classified.code, NativeXelisErrorCode::Offline);
    assert_eq!(classified.native_kind.as_deref(), Some("NOT_ONLINE_MODE"));
}
