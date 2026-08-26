use std::{error::Error, fmt};

use xelis_common::rpc::client::JsonRPCError;
use xelis_common::{
    crypto::proofs::ProofGenerationError, serializer::ReaderError,
    transaction::builder::GenerationError,
};
use xelis_wallet::{error::WalletError, mnemonics::MnemonicsError};

use xelis_wallet::network_handler::NetworkError;

/// Version of the native structured error contract.
pub const NATIVE_XELIS_ERROR_VERSION: u16 = 1;

/// Native component that produced or surfaced an operation failure.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeXelisErrorSource {
    XelisWalletFlutter,
    XelisWallet,
    XelisCommon,
    Dependency,
    Unknown,
}

/// Stable package-owned error category.
///
/// Consumers may use this value for recovery and presentation decisions. The
/// optional native kind remains diagnostic metadata and is not a replacement
/// for this package-owned contract.
///
/// Flutter Rust Bridge encodes these variants by declaration order. Preserve
/// the existing prefix and append new codes only; reordering requires a native
/// contract-version migration.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeXelisErrorCode {
    InvalidInput,
    Offline,
    Network,
    RemoteRejected,
    InsufficientFunds,
    Conflict,
    NotFound,
    Unsupported,
    Storage,
    Serialization,
    Initialization,
    Internal,
    AuthenticationOrCorruptData,
    NetworkMismatch,
    Cancelled,
    OperationInProgress,
    OperationFailed,
    StreamLagged,
    StreamClosedUnexpectedly,
}

/// Structured error transported by the private native bridge.
///
/// `diagnostic_message` is privileged diagnostic data. It may contain values
/// supplied by a dependency or the caller and must not be displayed or logged
/// without an explicit diagnostic policy.
#[derive(Clone, Eq, PartialEq)]
pub struct NativeXelisError {
    pub version: u16,
    pub source: NativeXelisErrorSource,
    pub code: NativeXelisErrorCode,
    pub native_kind: Option<String>,
    pub native_code: Option<i32>,
    pub diagnostic_message: String,
}

impl fmt::Debug for NativeXelisError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeXelisError")
            .field("version", &self.version)
            .field("source", &self.source)
            .field("code", &self.code)
            .field("native_kind", &self.native_kind)
            .field("native_code", &self.native_code)
            .field("diagnostic_message", &"<privileged>")
            .finish()
    }
}

impl NativeXelisError {
    pub(crate) fn xelis_wallet(
        code: NativeXelisErrorCode,
        native_kind: &'static str,
        diagnostic_message: impl Into<String>,
    ) -> Self {
        Self::new(
            NativeXelisErrorSource::XelisWallet,
            code,
            Some(native_kind.to_owned()),
            None,
            diagnostic_message.into(),
        )
    }

    pub(crate) fn xelis_common(
        code: NativeXelisErrorCode,
        native_kind: &'static str,
        diagnostic_message: impl Into<String>,
    ) -> Self {
        Self::new(
            NativeXelisErrorSource::XelisCommon,
            code,
            Some(native_kind.to_owned()),
            None,
            diagnostic_message.into(),
        )
    }

    pub(crate) fn xelis_wallet_flutter(
        code: NativeXelisErrorCode,
        native_kind: &'static str,
        diagnostic_message: impl Into<String>,
    ) -> Self {
        Self::new(
            NativeXelisErrorSource::XelisWalletFlutter,
            code,
            Some(native_kind.to_owned()),
            None,
            diagnostic_message.into(),
        )
    }

    #[cfg(not(target_arch = "wasm32"))]
    pub(crate) fn dependency(
        code: NativeXelisErrorCode,
        native_kind: &'static str,
        diagnostic_message: impl Into<String>,
    ) -> Self {
        Self::new(
            NativeXelisErrorSource::Dependency,
            code,
            Some(native_kind.to_owned()),
            None,
            diagnostic_message.into(),
        )
    }

    pub(crate) fn from_wallet_operation(
        error: anyhow::Error,
        fallback_code: NativeXelisErrorCode,
        fallback_kind: &'static str,
    ) -> Self {
        Self::from_wallet_operation_with_policy(
            error,
            fallback_code,
            fallback_kind,
            WalletOperationErrorPolicy::Standard,
        )
    }

    pub(crate) fn from_wallet_storage_operation(
        error: anyhow::Error,
        fallback_kind: &'static str,
    ) -> Self {
        let diagnostic_message = anyhow_diagnostic_message(&error);
        let classification = classify_storage_operation_error(&error).unwrap_or_else(|| {
            typed_classification(
                NativeXelisErrorSource::XelisWallet,
                NativeXelisErrorCode::Storage,
                fallback_kind,
            )
        });
        Self::from_classification(classification, diagnostic_message)
    }

    pub(crate) fn from_wallet_authentication_operation(
        error: anyhow::Error,
        fallback_code: NativeXelisErrorCode,
        fallback_kind: &'static str,
    ) -> Self {
        Self::from_wallet_operation_with_policy(
            error,
            fallback_code,
            fallback_kind,
            WalletOperationErrorPolicy::Authentication,
        )
    }

    pub(crate) fn from_wallet_seed_recovery_operation(error: anyhow::Error) -> Self {
        if let Some(mnemonics_error) = error.downcast_ref::<MnemonicsError>() {
            let (native_kind, diagnostic_message) = safe_mnemonics_recovery_error(mnemonics_error);
            return Self::new(
                NativeXelisErrorSource::XelisWallet,
                NativeXelisErrorCode::InvalidInput,
                Some(native_kind.to_owned()),
                None,
                diagnostic_message,
            );
        }

        Self::from_wallet_operation(
            error,
            NativeXelisErrorCode::Internal,
            "WALLET_RECOVER_SEED_FAILED",
        )
    }

    pub(crate) fn from_wallet_private_key_recovery_operation(error: anyhow::Error) -> Self {
        if let Some(reader_error) = error.downcast_ref::<ReaderError>() {
            let (native_kind, diagnostic_message) = safe_private_key_reader_error(reader_error);
            return Self::new(
                NativeXelisErrorSource::XelisCommon,
                NativeXelisErrorCode::InvalidInput,
                Some(native_kind.to_owned()),
                None,
                diagnostic_message.to_owned(),
            );
        }

        Self::from_wallet_operation(
            error,
            NativeXelisErrorCode::Internal,
            "WALLET_RECOVER_PRIVATE_KEY_FAILED",
        )
    }

    fn from_wallet_operation_with_policy(
        error: anyhow::Error,
        fallback_code: NativeXelisErrorCode,
        fallback_kind: &'static str,
        policy: WalletOperationErrorPolicy,
    ) -> Self {
        let diagnostic_message = anyhow_diagnostic_message(&error);
        let classification =
            classify_anyhow_error_with_policy(&error, policy).unwrap_or_else(|| {
                typed_classification(
                    NativeXelisErrorSource::XelisWallet,
                    fallback_code,
                    fallback_kind,
                )
            });
        Self::from_classification(classification, diagnostic_message)
    }

    fn from_classification(
        classification: NativeErrorClassification,
        diagnostic_message: String,
    ) -> Self {
        Self::new(
            classification.source,
            classification.code,
            classification.native_kind,
            classification.native_code,
            diagnostic_message,
        )
    }

    fn new(
        source: NativeXelisErrorSource,
        code: NativeXelisErrorCode,
        native_kind: Option<String>,
        native_code: Option<i32>,
        diagnostic_message: String,
    ) -> Self {
        Self {
            version: NATIVE_XELIS_ERROR_VERSION,
            source,
            code,
            native_kind,
            native_code,
            diagnostic_message,
        }
    }
}

impl fmt::Display for NativeXelisError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        // Keep implicit formatting safe. Detailed native diagnostics remain
        // available only through the explicit diagnostic_message field.
        write!(
            formatter,
            "native XELIS error ({:?}/{:?})",
            self.source, self.code
        )
    }
}

impl Error for NativeXelisError {}

impl From<WalletError> for NativeXelisError {
    fn from(error: WalletError) -> Self {
        let classification = classify_wallet_error(&error);
        let diagnostic_message = wallet_diagnostic_message(&error);
        Self::from_classification(classification, diagnostic_message)
    }
}

impl From<JsonRPCError> for NativeXelisError {
    fn from(error: JsonRPCError) -> Self {
        let classification = classify_json_rpc_error(&error);
        let diagnostic_message = json_rpc_diagnostic_message(&error);
        Self::from_classification(classification, diagnostic_message)
    }
}

#[derive(Debug, Eq, PartialEq)]
struct NativeErrorClassification {
    source: NativeXelisErrorSource,
    code: NativeXelisErrorCode,
    native_kind: Option<String>,
    native_code: Option<i32>,
}

#[derive(Clone, Copy)]
enum WalletOperationErrorPolicy {
    Standard,
    Authentication,
}

impl NativeErrorClassification {
    fn new(
        source: NativeXelisErrorSource,
        code: NativeXelisErrorCode,
        native_kind: Option<String>,
        native_code: Option<i32>,
    ) -> Self {
        Self {
            source,
            code,
            native_kind,
            native_code,
        }
    }
}

fn typed_classification(
    source: NativeXelisErrorSource,
    code: NativeXelisErrorCode,
    native_kind: &'static str,
) -> NativeErrorClassification {
    NativeErrorClassification::new(source, code, native_kind_option(native_kind), None)
}

fn native_kind_option(native_kind: &'static str) -> Option<String> {
    (native_kind != "UNSPECIFIED").then(|| native_kind.to_owned())
}

fn safe_mnemonics_recovery_error(error: &MnemonicsError) -> (&'static str, String) {
    match error {
        MnemonicsError::InvalidWordsCount => (
            "MNEMONICS_INVALID_WORDS_COUNT",
            "Mnemonic has an invalid word count".to_owned(),
        ),
        MnemonicsError::InvalidChecksum => (
            "MNEMONICS_INVALID_CHECKSUM",
            "Mnemonic checksum is invalid".to_owned(),
        ),
        MnemonicsError::InvalidChecksumIndex => (
            "MNEMONICS_INVALID_CHECKSUM_INDEX",
            "Mnemonic checksum index is invalid".to_owned(),
        ),
        MnemonicsError::InvalidLanguageIndex => (
            "MNEMONICS_INVALID_LANGUAGE_INDEX",
            "Mnemonic language index is invalid".to_owned(),
        ),
        MnemonicsError::InvalidLanguage => (
            "MNEMONICS_INVALID_LANGUAGE",
            "Mnemonic language is invalid".to_owned(),
        ),
        MnemonicsError::UnknownWord(_, position) => (
            "MNEMONICS_UNKNOWN_WORD",
            format!("Unknown mnemonic word at position {position}"),
        ),
        MnemonicsError::InvalidKeySize => (
            "MNEMONICS_INVALID_KEY_SIZE",
            "Mnemonic produced an invalid key size".to_owned(),
        ),
        MnemonicsError::InvalidKeyFromBytes => (
            "MNEMONICS_INVALID_KEY_FROM_BYTES",
            "Mnemonic key bytes are invalid".to_owned(),
        ),
        MnemonicsError::InvalidChecksumCalculation => (
            "MNEMONICS_INVALID_CHECKSUM_CALCULATION",
            "Mnemonic checksum calculation failed".to_owned(),
        ),
        MnemonicsError::NoIndicesFound => (
            "MNEMONICS_NO_INDICES_FOUND",
            "Mnemonic word indices are unavailable".to_owned(),
        ),
        MnemonicsError::WordListSanityCheckError => (
            "MNEMONICS_WORD_LIST_SANITY_CHECK_FAILED",
            "Mnemonic word list validation failed".to_owned(),
        ),
        MnemonicsError::OutOfBounds => (
            "MNEMONICS_OUT_OF_BOUNDS",
            "Mnemonic data is out of bounds".to_owned(),
        ),
    }
}

fn safe_private_key_reader_error(error: &ReaderError) -> (&'static str, &'static str) {
    match error {
        ReaderError::InvalidSize => (
            "PRIVATE_KEY_INVALID_SIZE",
            "Private key has an invalid size",
        ),
        ReaderError::InvalidValue => (
            "PRIVATE_KEY_INVALID_VALUE",
            "Private key contains an invalid value",
        ),
        ReaderError::InvalidHex => (
            "PRIVATE_KEY_INVALID_HEX",
            "Private key is not valid hexadecimal data",
        ),
        ReaderError::ErrorTryInto
        | ReaderError::TrailingBytes
        | ReaderError::TryFromSliceError(_) => (
            "PRIVATE_KEY_INVALID_ENCODING",
            "Private key encoding is invalid",
        ),
        ReaderError::Any(_) => (
            "PRIVATE_KEY_INVALID_DATA",
            "Private key data could not be decoded",
        ),
    }
}

fn wallet_diagnostic_message(error: &WalletError) -> String {
    match error {
        WalletError::Any(inner) => anyhow_diagnostic_message(&inner.error),
        WalletError::NetworkError(NetworkError::DaemonAPIError(inner)) => {
            anyhow_diagnostic_message(inner)
        }
        _ => error.to_string(),
    }
}

fn anyhow_diagnostic_message(error: &anyhow::Error) -> String {
    let mut diagnostic = format!("{error:#}");

    if let Some(rpc_error) = error.downcast_ref::<JsonRPCError>() {
        append_json_rpc_data(&mut diagnostic, rpc_error);
    }

    diagnostic
}

fn json_rpc_diagnostic_message(error: &JsonRPCError) -> String {
    let mut diagnostic = match error {
        JsonRPCError::Any(inner) => anyhow_diagnostic_message(inner),
        _ => error.to_string(),
    };
    append_json_rpc_data(&mut diagnostic, error);
    diagnostic
}

fn append_json_rpc_data(diagnostic: &mut String, error: &JsonRPCError) {
    let data = match error {
        JsonRPCError::InternalError { data, .. } | JsonRPCError::ServerError { data, .. } => {
            data.as_deref()
        }
        _ => None,
    };

    if let Some(data) = data {
        diagnostic.push_str("\nRPC data: ");
        diagnostic.push_str(data);
    }
}

fn classify_anyhow_error(error: &anyhow::Error) -> Option<NativeErrorClassification> {
    classify_anyhow_error_with_policy(error, WalletOperationErrorPolicy::Standard)
}

fn classify_storage_operation_error(error: &anyhow::Error) -> Option<NativeErrorClassification> {
    if let Some(json_rpc_error) = error.downcast_ref::<JsonRPCError>() {
        return Some(classify_json_rpc_error(json_rpc_error));
    }

    let wallet_error = error.downcast_ref::<WalletError>()?;
    match wallet_error {
        // An untyped WalletError::Any must not turn a cache/persistence
        // boundary into Internal. Preserve only an actually typed nested cause.
        WalletError::Any(inner) => classify_storage_operation_error(&inner.error),
        _ => Some(classify_wallet_error(wallet_error)),
    }
}

fn classify_anyhow_error_with_policy(
    error: &anyhow::Error,
    policy: WalletOperationErrorPolicy,
) -> Option<NativeErrorClassification> {
    if let Some(json_rpc_error) = error.downcast_ref::<JsonRPCError>() {
        return Some(classify_json_rpc_error(json_rpc_error));
    }

    error
        .downcast_ref::<WalletError>()
        .map(|error| classify_wallet_error_with_policy(error, policy))
}

fn classify_wallet_error_with_policy(
    error: &WalletError,
    policy: WalletOperationErrorPolicy,
) -> NativeErrorClassification {
    match error {
        WalletError::CryptoError(_)
            if matches!(policy, WalletOperationErrorPolicy::Authentication) =>
        {
            typed_classification(
                NativeXelisErrorSource::XelisWallet,
                NativeXelisErrorCode::AuthenticationOrCorruptData,
                error.kind(),
            )
        }
        WalletError::Any(inner) => classify_anyhow_error_with_policy(&inner.error, policy)
            .unwrap_or_else(|| {
                typed_classification(
                    NativeXelisErrorSource::XelisWallet,
                    NativeXelisErrorCode::Internal,
                    inner.kind,
                )
            }),
        _ => classify_wallet_error(error),
    }
}

fn classify_wallet_error(error: &WalletError) -> NativeErrorClassification {
    let native_kind = error.kind();

    match error {
        WalletError::Any(inner) => classify_anyhow_error(&inner.error).unwrap_or_else(|| {
            typed_classification(
                NativeXelisErrorSource::XelisWallet,
                NativeXelisErrorCode::Internal,
                inner.kind,
            )
        }),
        WalletError::NetworkError(error) => classify_network_error(error),
        WalletError::NotOnlineMode
        | WalletError::NoNetworkHandler
        | WalletError::NoAPIServer
        | WalletError::RPCServerNotRunning => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Offline,
            native_kind,
        ),
        WalletError::AlreadyOnlineMode
        | WalletError::AssetAlreadyRegistered
        | WalletError::RPCServerAlreadyRunning
        | WalletError::TxNotBuilt => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Conflict,
            native_kind,
        ),
        WalletError::NotEnoughFunds(..) | WalletError::NotEnoughFundsForFee(..) => {
            typed_classification(
                NativeXelisErrorSource::XelisWallet,
                NativeXelisErrorCode::InsufficientFunds,
                native_kind,
            )
        }
        WalletError::ProofGenerationError(ProofGenerationError::InsufficientFunds { .. })
        | WalletError::GenerationError(GenerationError::Proof(
            ProofGenerationError::InsufficientFunds { .. },
        )) => typed_classification(
            NativeXelisErrorSource::XelisCommon,
            NativeXelisErrorCode::InsufficientFunds,
            native_kind,
        ),
        WalletError::AssetNotTracked(_) | WalletError::BalanceNotFound(_) => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::NotFound,
            native_kind,
        ),
        WalletError::DatabaseError(_) => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Storage,
            native_kind,
        ),
        WalletError::InvalidEncryptedValue
        | WalletError::NoSalt
        | WalletError::NoMasterKeyFound
        | WalletError::NoPasswordSaltFound
        | WalletError::InvalidSaltSize
        | WalletError::NoSaltFound => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::AuthenticationOrCorruptData,
            native_kind,
        ),
        WalletError::NoHandlerAvailable | WalletError::Unsupported => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Unsupported,
            native_kind,
        ),
        WalletError::AEADCipherFormatError(_)
        | WalletError::GenerationError(_)
        | WalletError::ProofGenerationError(_)
        | WalletError::DecompressionError(_) => typed_classification(
            NativeXelisErrorSource::XelisCommon,
            NativeXelisErrorCode::InvalidInput,
            native_kind,
        ),
        WalletError::InvalidDatetime
        | WalletError::TransactionTooBig(..)
        | WalletError::InvalidKeyPair
        | WalletError::InvalidSignature
        | WalletError::ExpectedOneTx
        | WalletError::TooManyTx
        | WalletError::TxOwnerIsReceiver
        | WalletError::InvalidAddressParams
        | WalletError::ExtraDataTooBig(..)
        | WalletError::RescanTopoheightTooHigh
        | WalletError::InvalidFeeProvided(..)
        | WalletError::EmptyName
        | WalletError::NotTransactionSigner => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::InvalidInput,
            native_kind,
        ),
        WalletError::Cipher
        | WalletError::CryptoError(_)
        | WalletError::AlgorithmHashingError(_)
        | WalletError::CiphertextDecode
        | WalletError::NonceGeneration
        | WalletError::PoisonError
        | WalletError::SemaphoreError(_) => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Internal,
            native_kind,
        ),
    }
}

fn classify_network_error(error: &NetworkError) -> NativeErrorClassification {
    match error {
        NetworkError::AlreadyRunning => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Conflict,
            "NETWORK_ALREADY_RUNNING",
        ),
        NetworkError::NotRunning => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Offline,
            "NETWORK_NOT_RUNNING",
        ),
        NetworkError::TaskError(_) => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::Internal,
            "NETWORK_TASK_ERROR",
        ),
        NetworkError::DaemonAPIError(error) => classify_anyhow_error(error).unwrap_or_else(|| {
            typed_classification(
                NativeXelisErrorSource::XelisWallet,
                NativeXelisErrorCode::Network,
                "DAEMON_API_ERROR",
            )
        }),
        NetworkError::NetworkMismatch => typed_classification(
            NativeXelisErrorSource::XelisWallet,
            NativeXelisErrorCode::NetworkMismatch,
            "NETWORK_MISMATCH",
        ),
    }
}

fn classify_json_rpc_error(error: &JsonRPCError) -> NativeErrorClassification {
    if let JsonRPCError::Any(inner) = error {
        if let Some(classification) = classify_anyhow_error(inner) {
            return classification;
        }
    }

    let native_kind: &'static str = error.into();
    let code = match error {
        JsonRPCError::NoResponse(..)
        | JsonRPCError::TimedOut(_)
        | JsonRPCError::HttpError(_)
        | JsonRPCError::ConnectionError(_)
        | JsonRPCError::SocketError(_)
        | JsonRPCError::SendError(..) => NativeXelisErrorCode::Network,
        JsonRPCError::InvalidBatch
        | JsonRPCError::MissingResult
        | JsonRPCError::SerializationError(_) => NativeXelisErrorCode::Serialization,
        JsonRPCError::EventNotRegistered => NativeXelisErrorCode::NotFound,
        JsonRPCError::Any(_) => NativeXelisErrorCode::Internal,
        JsonRPCError::ParseError
        | JsonRPCError::InvalidRequest
        | JsonRPCError::MethodNotFound
        | JsonRPCError::InvalidParams
        | JsonRPCError::InternalError { .. }
        | JsonRPCError::ServerError { .. } => NativeXelisErrorCode::RemoteRejected,
    };
    let native_code = match error {
        JsonRPCError::ParseError => Some(-32700),
        JsonRPCError::InvalidRequest => Some(-32600),
        JsonRPCError::MethodNotFound => Some(-32601),
        JsonRPCError::InvalidParams => Some(-32602),
        JsonRPCError::InternalError { .. } => Some(-32603),
        JsonRPCError::ServerError { code, .. } => Some(i32::from(*code)),
        _ => None,
    };

    NativeErrorClassification::new(
        NativeXelisErrorSource::XelisCommon,
        code,
        native_kind_option(native_kind),
        native_code,
    )
}

#[cfg(test)]
#[path = "error/tests.rs"]
mod tests;
