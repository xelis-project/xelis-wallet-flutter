use super::*;

#[test]
fn stable_history_error_fallbacks_are_structured() {
    let storage = classify_history_error(
        anyhow::anyhow!("database read failure"),
        NativeXelisErrorCode::Storage,
        "WALLET_HISTORY_READ_FAILED",
    );
    assert_eq!(storage.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(storage.code, NativeXelisErrorCode::Storage);
    assert_eq!(
        storage.native_kind.as_deref(),
        Some("WALLET_HISTORY_READ_FAILED")
    );

    let invalid = classify_history_error(
        anyhow::anyhow!("invalid page"),
        NativeXelisErrorCode::InvalidInput,
        "WALLET_HISTORY_FILTER_INVALID",
    );
    assert_eq!(invalid.code, NativeXelisErrorCode::InvalidInput);

    let serialization = classify_history_error(
        anyhow::anyhow!("payload serialization failed"),
        NativeXelisErrorCode::Serialization,
        "WALLET_HISTORY_EXTRA_DATA_SERIALIZATION_FAILED",
    );
    assert_eq!(serialization.code, NativeXelisErrorCode::Serialization);
}
