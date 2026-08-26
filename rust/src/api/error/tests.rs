use super::*;
use xelis_common::serializer::ReaderError;
use xelis_wallet::cipher::Cipher;
use xelis_wallet::mnemonics::MnemonicsError;

fn crypto_wallet_error() -> WalletError {
    let encrypting_cipher = Cipher::new(&[1; 32], None).unwrap();
    let decrypting_cipher = Cipher::new(&[2; 32], None).unwrap();
    let encrypted = encrypting_cipher.encrypt_value(b"test value").unwrap();
    let error = decrypting_cipher.decrypt_value(&encrypted).unwrap_err();
    assert!(matches!(error, WalletError::CryptoError(_)));
    error
}

#[test]
fn native_error_code_v1_prefix_is_append_only() {
    let codes = [
        NativeXelisErrorCode::InvalidInput,
        NativeXelisErrorCode::Offline,
        NativeXelisErrorCode::Network,
        NativeXelisErrorCode::RemoteRejected,
        NativeXelisErrorCode::InsufficientFunds,
        NativeXelisErrorCode::Conflict,
        NativeXelisErrorCode::NotFound,
        NativeXelisErrorCode::Unsupported,
        NativeXelisErrorCode::Storage,
        NativeXelisErrorCode::Serialization,
        NativeXelisErrorCode::Initialization,
        NativeXelisErrorCode::Internal,
        NativeXelisErrorCode::AuthenticationOrCorruptData,
        NativeXelisErrorCode::NetworkMismatch,
        NativeXelisErrorCode::Cancelled,
        NativeXelisErrorCode::OperationInProgress,
        NativeXelisErrorCode::OperationFailed,
        NativeXelisErrorCode::StreamLagged,
        NativeXelisErrorCode::StreamClosedUnexpectedly,
    ];

    for (index, code) in codes.into_iter().enumerate() {
        assert_eq!(code as usize, index);
    }
}

#[test]
fn wallet_variants_map_to_package_owned_codes() {
    let offline = NativeXelisError::from(WalletError::NotOnlineMode);
    assert_eq!(offline.version, NATIVE_XELIS_ERROR_VERSION);
    assert_eq!(offline.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(offline.code, NativeXelisErrorCode::Offline);
    assert_eq!(offline.native_kind.as_deref(), Some("NOT_ONLINE_MODE"));

    let funds = NativeXelisError::from(WalletError::NotEnoughFundsForFee(10, 20));
    assert_eq!(funds.code, NativeXelisErrorCode::InsufficientFunds);

    let proof_funds = NativeXelisError::from(WalletError::GenerationError(GenerationError::Proof(
        ProofGenerationError::InsufficientFunds {
            required: 20,
            available: 10,
        },
    )));
    assert_eq!(proof_funds.source, NativeXelisErrorSource::XelisCommon);
    assert_eq!(proof_funds.code, NativeXelisErrorCode::InsufficientFunds);

    let invalid = NativeXelisError::from(WalletError::InvalidAddressParams);
    assert_eq!(invalid.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        invalid.native_kind.as_deref(),
        Some("INVALID_ADDRESS_PARAMS")
    );

    let authentication = NativeXelisError::from(WalletError::InvalidEncryptedValue);
    assert_eq!(
        authentication.code,
        NativeXelisErrorCode::AuthenticationOrCorruptData
    );
}

#[test]
fn wallet_any_preserves_a_typed_json_rpc_cause_through_anyhow_context() {
    let rpc_error = anyhow::Error::new(JsonRPCError::ConnectionError(
        "private endpoint context".to_owned(),
    ))
    .context("wallet network operation failed");
    let classified = NativeXelisError::from(WalletError::from(rpc_error));

    assert_eq!(classified.source, NativeXelisErrorSource::XelisCommon);
    assert_eq!(classified.code, NativeXelisErrorCode::Network);
    assert_eq!(classified.native_kind.as_deref(), Some("CONNECTION_ERROR"));
    assert_eq!(classified.native_code, None);
    assert!(classified
        .diagnostic_message
        .contains("wallet network operation failed"));
    assert!(classified
        .diagnostic_message
        .contains("private endpoint context"));
}

#[test]
fn json_rpc_server_error_preserves_numeric_code_without_parsing_text() {
    let classified = NativeXelisError::from(JsonRPCError::ServerError {
        code: -32042,
        message: "daemon rejected request".to_owned(),
        data: Some("privileged diagnostic data".to_owned()),
    });

    assert_eq!(classified.source, NativeXelisErrorSource::XelisCommon);
    assert_eq!(classified.code, NativeXelisErrorCode::RemoteRejected);
    assert_eq!(classified.native_kind.as_deref(), Some("SERVER_ERROR"));
    assert_eq!(classified.native_code, Some(-32042));
    assert!(classified
        .diagnostic_message
        .contains("privileged diagnostic data"));
}

#[test]
fn wallet_network_error_preserves_nested_json_rpc_classification() {
    let error = WalletError::NetworkError(NetworkError::DaemonAPIError(anyhow::Error::new(
        JsonRPCError::TimedOut("get_info".to_owned()),
    )));
    let classified = NativeXelisError::from(error);

    assert_eq!(classified.source, NativeXelisErrorSource::XelisCommon);
    assert_eq!(classified.code, NativeXelisErrorCode::Network);
    assert_eq!(classified.native_kind.as_deref(), Some("TIMED_OUT"));
}

#[test]
fn network_mismatch_has_a_dedicated_recovery_code() {
    let classified =
        NativeXelisError::from(WalletError::NetworkError(NetworkError::NetworkMismatch));

    assert_eq!(classified.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(classified.code, NativeXelisErrorCode::NetworkMismatch);
    assert_eq!(classified.native_kind.as_deref(), Some("NETWORK_MISMATCH"));
}

#[test]
fn unspecified_wallet_any_error_uses_a_safe_fallback() {
    let classified = NativeXelisError::from(WalletError::from(anyhow::anyhow!(
        "unclassified privileged diagnostic"
    )));

    assert_eq!(classified.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(classified.code, NativeXelisErrorCode::Internal);
    assert_eq!(classified.native_kind, None);
}

#[test]
fn display_does_not_expose_the_diagnostic_message() {
    let error = NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::Internal,
        "TEST_FAILURE",
        "C:\\private\\wallet.db",
    );

    assert!(!error.to_string().contains("private"));
    assert!(!format!("{error:?}").contains("private"));
    assert_eq!(error.diagnostic_message, "C:\\private\\wallet.db");
}

#[test]
fn crypto_errors_are_authentication_failures_only_at_auth_boundaries() {
    let general = NativeXelisError::from_wallet_operation(
        anyhow::Error::new(crypto_wallet_error()),
        NativeXelisErrorCode::Internal,
        "WALLET_OPERATION_FAILED",
    );
    assert_eq!(general.code, NativeXelisErrorCode::Internal);

    let authentication = NativeXelisError::from_wallet_authentication_operation(
        anyhow::Error::new(crypto_wallet_error()),
        NativeXelisErrorCode::Internal,
        "WALLET_PASSWORD_VERIFICATION_FAILED",
    );
    assert_eq!(
        authentication.code,
        NativeXelisErrorCode::AuthenticationOrCorruptData
    );
    assert_eq!(authentication.source, NativeXelisErrorSource::XelisWallet);

    let unrelated = NativeXelisError::from_wallet_authentication_operation(
        anyhow::anyhow!("wallet file is unavailable"),
        NativeXelisErrorCode::Internal,
        "WALLET_OPEN_FAILED",
    );
    assert_eq!(unrelated.code, NativeXelisErrorCode::Internal);
}

#[test]
fn password_change_auth_boundary_classifies_an_invalid_old_password() {
    let classified = NativeXelisError::from_wallet_authentication_operation(
        anyhow::Error::new(crypto_wallet_error()),
        NativeXelisErrorCode::Internal,
        "WALLET_PASSWORD_CHANGE_FAILED",
    );

    assert_eq!(classified.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(
        classified.code,
        NativeXelisErrorCode::AuthenticationOrCorruptData
    );
    assert_eq!(classified.native_kind.as_deref(), Some("CRYPTO_ERROR"));
    assert!(!classified.diagnostic_message.is_empty());
}

#[test]
fn untyped_wallet_errors_use_the_operation_fallback_without_text_parsing() {
    let classified = NativeXelisError::from_wallet_operation(
        anyhow::anyhow!("privileged failure at C:\\wallets\\primary"),
        NativeXelisErrorCode::Internal,
        "WALLET_CREATE_FAILED",
    );

    assert_eq!(classified.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(classified.code, NativeXelisErrorCode::Internal);
    assert_eq!(
        classified.native_kind.as_deref(),
        Some("WALLET_CREATE_FAILED")
    );
    assert!(classified.diagnostic_message.contains("primary"));
    assert!(!classified.to_string().contains("primary"));
}

#[test]
fn seed_recovery_errors_are_typed_without_retaining_seed_material() {
    let secret_seed = "alpha beta gamma sensitive-word delta";
    let error = anyhow::Error::new(MnemonicsError::UnknownWord("sensitive-word".to_owned(), 3))
        .context(format!("Recovery failed for {secret_seed}"));

    let classified = NativeXelisError::from_wallet_seed_recovery_operation(error);

    assert_eq!(classified.source, NativeXelisErrorSource::XelisWallet);
    assert_eq!(classified.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        classified.native_kind.as_deref(),
        Some("MNEMONICS_UNKNOWN_WORD")
    );
    assert_eq!(
        classified.diagnostic_message,
        "Unknown mnemonic word at position 3"
    );
    assert!(!classified.diagnostic_message.contains("sensitive-word"));
    assert!(!classified.diagnostic_message.contains(secret_seed));
}

#[test]
fn private_key_recovery_errors_are_typed_without_retaining_the_key() {
    let private_key = "0123456789abcdef-private-key";
    let error = anyhow::Error::new(ReaderError::InvalidHex)
        .context(format!("Invalid private key provided: {private_key}"));

    let classified = NativeXelisError::from_wallet_private_key_recovery_operation(error);

    assert_eq!(classified.source, NativeXelisErrorSource::XelisCommon);
    assert_eq!(classified.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        classified.native_kind.as_deref(),
        Some("PRIVATE_KEY_INVALID_HEX")
    );
    assert_eq!(
        classified.diagnostic_message,
        "Private key is not valid hexadecimal data"
    );
    assert!(!classified.diagnostic_message.contains(private_key));
}

#[test]
fn private_key_trailing_bytes_reuse_the_stable_encoding_classification() {
    let private_key = "0123456789abcdef-sensitive-private-key";
    let error = anyhow::Error::new(ReaderError::TrailingBytes)
        .context(format!("Invalid private key provided: {private_key}"));

    let classified = NativeXelisError::from_wallet_private_key_recovery_operation(error);

    assert_eq!(classified.source, NativeXelisErrorSource::XelisCommon);
    assert_eq!(classified.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        classified.native_kind.as_deref(),
        Some("PRIVATE_KEY_INVALID_ENCODING")
    );
    assert_eq!(
        classified.diagnostic_message,
        "Private key encoding is invalid"
    );
    assert!(!classified.diagnostic_message.contains(private_key));
}
