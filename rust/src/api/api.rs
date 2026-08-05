use crate::api::error::NativeXelisError;
#[cfg(not(target_arch = "wasm32"))]
use crate::api::error::NativeXelisErrorCode;
use crate::api::logger;
use crate::api::logger::{Level, NativeLogEntry};
use crate::api::progress_report::{ProgressReport, PROGRESS_REPORT_STREAM_SINK};
use crate::frb_generated::StreamSink;

/// Initialize xelis_common configuration
/// This must be called before using any wallet functionality
/// It initializes VM libraries and other global configuration
pub fn initialize_xelis_config() -> anyhow::Result<()> {
    xelis_common::config::init();
    Ok(())
}

pub fn initialize_crypto_provider() -> std::result::Result<(), NativeXelisError> {
    // Initialize the crypto provider for rustls.
    // This is necessary for tls connections
    // and should be called before any tls connections are made.
    #[cfg(not(target_arch = "wasm32"))]
    rustls::crypto::ring::default_provider()
        .install_default()
        .map_err(|_| {
            NativeXelisError::dependency(
                NativeXelisErrorCode::Conflict,
                "CRYPTO_PROVIDER_ALREADY_INSTALLED",
                "failed to install ring because a process-wide crypto provider is already installed",
            )
        })?;
    Ok(())
}

pub fn set_up_rust_logger(
    minimum_level: Level,
    diagnostic_mode: bool,
) -> std::result::Result<(), NativeXelisError> {
    logger::init_logger(minimum_level, diagnostic_mode)
}

pub fn create_log_stream(s: StreamSink<NativeLogEntry>) -> anyhow::Result<()> {
    logger::replace_stream_sink(s);
    Ok(())
}

pub fn create_progress_report_stream(
    stream_sink: StreamSink<ProgressReport>,
) -> anyhow::Result<()> {
    let mut guard = PROGRESS_REPORT_STREAM_SINK.write();
    *guard = Some(stream_sink);
    drop(guard);
    Ok(())
}
