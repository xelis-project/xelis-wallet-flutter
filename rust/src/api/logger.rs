use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
pub use log::Level;
use log::{Log, Metadata, Record};
use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::Arc;

use crate::api::error::{NativeXelisError, NativeXelisErrorCode};
use crate::frb_generated::StreamSink;

pub(crate) const CONSUMER_LOG_TARGET: &str = "xelis_wallet_flutter";

lazy_static! {
    static ref SEND_TO_DART_LOGGER_STREAM_SINK: parking_lot::RwLock<Option<Arc<StreamSink<NativeLogEntry>>>> =
        parking_lot::RwLock::new(None);
    static ref LOGGER_CONFIGURATION: parking_lot::Mutex<Option<LoggerConfiguration>> =
        parking_lot::Mutex::new(None);
}

static SEND_TO_DART_LOGGER: SendToDartLogger = SendToDartLogger;
static LOG_SCOPE: AtomicU8 = AtomicU8::new(NativeLogScope::Standard as u8);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum NativeLogScope {
    Standard = 0,
    PackageDiagnostic = 1,
    UnsafeUpstreamDiagnostic = 2,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct LoggerConfiguration {
    minimum_level: Level,
    scope: NativeLogScope,
}

/// A native log record forwarded through the private generated bridge.
pub struct NativeLogEntry {
    pub level: Level,
    pub target: String,
    pub message: String,
}

#[frb(mirror(Level))]
pub enum _Level {
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

/// Installs the process-wide logger with an immutable configuration.
///
/// Retrying the same configuration is idempotent. A different configuration
/// is rejected because changing diagnostic policy while a process is running
/// would make the confidentiality boundary ambiguous.
#[frb(ignore)]
pub(crate) fn init_logger(
    minimum_level: Level,
    scope: NativeLogScope,
) -> std::result::Result<(), NativeXelisError> {
    let requested = LoggerConfiguration {
        minimum_level,
        scope,
    };
    let mut configuration = LOGGER_CONFIGURATION.lock();

    if let Some(installed) = *configuration {
        if installed == requested {
            return Ok(());
        }

        return Err(NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Conflict,
            "LOGGER_CONFIGURATION_CONFLICT",
            "the Rust logger is already initialized with a different configuration",
        ));
    }

    log::set_logger(&SEND_TO_DART_LOGGER).map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Initialization,
            "LOGGER_INSTALLATION_FAILED",
            format!("failed to install the Rust logger: {error}"),
        )
    })?;

    LOG_SCOPE.store(scope as u8, Ordering::Release);
    log::set_max_level(minimum_level.to_level_filter());
    *configuration = Some(requested);
    Ok(())
}

#[frb(ignore)]
pub(crate) fn replace_stream_sink(stream_sink: StreamSink<NativeLogEntry>) {
    let previous = SEND_TO_DART_LOGGER_STREAM_SINK
        .write()
        .replace(Arc::new(stream_sink));
    drop(previous);
}

struct SendToDartLogger;

impl SendToDartLogger {
    fn record_to_entry(record: &Record) -> NativeLogEntry {
        NativeLogEntry {
            level: record.level(),
            target: record.target().to_owned(),
            message: record.args().to_string(),
        }
    }

    fn accepts(
        metadata: &Metadata,
        scope: NativeLogScope,
        maximum_level: log::LevelFilter,
    ) -> bool {
        metadata.level().to_level_filter() <= maximum_level
            && match scope {
                NativeLogScope::Standard => metadata.target() == CONSUMER_LOG_TARGET,
                NativeLogScope::PackageDiagnostic => {
                    metadata.target() == CONSUMER_LOG_TARGET
                        || metadata.target().starts_with("xelis_wallet_flutter::")
                }
                NativeLogScope::UnsafeUpstreamDiagnostic => {
                    metadata.target() == CONSUMER_LOG_TARGET
                        || metadata.target().starts_with("xelis_wallet_flutter::")
                        || metadata.target() == "xelis_wallet"
                        || metadata.target().starts_with("xelis_wallet::")
                        || metadata.target() == "xelis_common"
                        || metadata.target().starts_with("xelis_common::")
                }
            }
    }
}

impl Log for SendToDartLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        Self::accepts(
            metadata,
            match LOG_SCOPE.load(Ordering::Acquire) {
                0 => NativeLogScope::Standard,
                1 => NativeLogScope::PackageDiagnostic,
                _ => NativeLogScope::UnsafeUpstreamDiagnostic,
            },
            log::max_level(),
        )
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        let sink = SEND_TO_DART_LOGGER_STREAM_SINK.read().clone();
        let Some(sink) = sink else {
            return;
        };

        if sink.add(Self::record_to_entry(record)).is_err() {
            let failed_sink = {
                let mut current = SEND_TO_DART_LOGGER_STREAM_SINK.write();
                if current
                    .as_ref()
                    .is_some_and(|candidate| Arc::ptr_eq(candidate, &sink))
                {
                    current.take()
                } else {
                    None
                }
            };
            drop(failed_sink);
        }
    }

    fn flush(&self) {}
}

#[cfg(test)]
mod tests {
    use super::*;

    fn metadata(level: Level, target: &'static str) -> Metadata<'static> {
        Metadata::builder().level(level).target(target).build()
    }

    #[test]
    fn log_entry_uses_the_stable_target_instead_of_a_source_path() {
        let arguments = format_args!("wallet opened");
        let record = Record::builder()
            .args(arguments)
            .level(Level::Info)
            .target("xelis_wallet::storage")
            .file(Some(
                "C:\\Users\\developer\\.cargo\\xelis-wallet\\storage.rs",
            ))
            .build();

        let entry = SendToDartLogger::record_to_entry(&record);

        assert_eq!(entry.target, "xelis_wallet::storage");
        assert_eq!(entry.message, "wallet opened");
    }

    #[test]
    fn standard_mode_only_accepts_explicit_consumer_records() {
        assert!(SendToDartLogger::accepts(
            &metadata(Level::Info, CONSUMER_LOG_TARGET),
            NativeLogScope::Standard,
            log::LevelFilter::Trace,
        ));
        assert!(!SendToDartLogger::accepts(
            &metadata(Level::Error, "xelis_wallet::network"),
            NativeLogScope::Standard,
            log::LevelFilter::Trace,
        ));
    }

    #[test]
    fn package_diagnostic_scope_accepts_package_targets_but_rejects_dependencies() {
        assert!(SendToDartLogger::accepts(
            &metadata(Level::Debug, "xelis_wallet_flutter::api::wallet"),
            NativeLogScope::PackageDiagnostic,
            log::LevelFilter::Debug,
        ));
        assert!(!SendToDartLogger::accepts(
            &metadata(Level::Error, "xelis_wallet::api::rpc"),
            NativeLogScope::PackageDiagnostic,
            log::LevelFilter::Debug,
        ));
        assert!(!SendToDartLogger::accepts(
            &metadata(Level::Error, "xelis_common::rpc"),
            NativeLogScope::PackageDiagnostic,
            log::LevelFilter::Debug,
        ));
    }

    #[test]
    fn unsafe_scope_accepts_only_selected_upstream_targets() {
        for target in ["xelis_wallet", "xelis_wallet::api", "xelis_common::rpc"] {
            assert!(SendToDartLogger::accepts(
                &metadata(Level::Info, target),
                NativeLogScope::UnsafeUpstreamDiagnostic,
                log::LevelFilter::Trace,
            ));
        }
        assert!(!SendToDartLogger::accepts(
            &metadata(Level::Info, "reqwest::connect"),
            NativeLogScope::UnsafeUpstreamDiagnostic,
            log::LevelFilter::Trace,
        ));
    }
}
