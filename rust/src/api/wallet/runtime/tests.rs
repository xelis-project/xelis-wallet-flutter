use std::path::Path;
use std::sync::Arc;

use anyhow::anyhow;
use xelis_common::network::Network;
use xelis_wallet::error::WalletError;
use xelis_wallet::network_handler::NetworkError;
use xelis_wallet::precomputed_tables::{L1_FULL, L1_LOW, L1_MEDIUM};
use xelis_wallet::wallet::RecoverOption;

use super::{
    daemon_rpc_endpoint, ensure_daemon_network, mt_params_for_cpu_cores,
    normalize_offline_mode_result, precomputed_table_type_from_l1, recover_option,
    recovery_input_kind, resolve_wallet_path, ConnectionAttemptGuard, RecoveryInputKind,
};
use crate::api::error::NativeXelisErrorCode;
use crate::api::precomputed_tables::PrecomputedTableType;
use crate::api::wallet::WalletConnectionAttempts;

#[test]
fn wallet_path_uses_directory_when_name_is_empty() {
    assert_eq!(
        resolve_wallet_path("", "wallet-directory").unwrap(),
        "wallet-directory"
    );
}

#[test]
fn wallet_path_joins_directory_and_name() {
    let path = resolve_wallet_path("primary", "wallets").unwrap();

    assert_eq!(path, Path::new("wallets").join("primary").to_string_lossy());
}

#[test]
fn wallet_path_accepts_name_without_directory() {
    assert_eq!(resolve_wallet_path("primary", "").unwrap(), "primary");
}

#[test]
fn wallet_path_rejects_empty_name_and_directory() {
    let error = resolve_wallet_path("", "").unwrap_err();

    assert_eq!(
        error.to_string(),
        "Either 'name' or 'directory' must be non-empty"
    );
}

#[test]
fn connection_attempt_guard_rejects_overlap_and_releases_on_drop() {
    let attempts = Arc::new(WalletConnectionAttempts::default());
    let guard = ConnectionAttemptGuard::acquire(Arc::clone(&attempts)).unwrap();

    let error = match ConnectionAttemptGuard::acquire(Arc::clone(&attempts)) {
        Ok(_) => panic!("overlapping connection attempt was accepted"),
        Err(error) => error,
    };
    assert_eq!(error.code, NativeXelisErrorCode::OperationInProgress);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("NETWORK_CONNECT_IN_PROGRESS")
    );

    drop(guard);
    assert!(ConnectionAttemptGuard::acquire(attempts).is_ok());
}

#[test]
fn connection_attempt_registry_cancels_the_published_token_and_can_close() {
    let attempts = Arc::new(WalletConnectionAttempts::default());
    let guard = ConnectionAttemptGuard::acquire(Arc::clone(&attempts)).unwrap();
    let attempt = guard.attempt();

    attempts.cancel_current(false);
    assert!(attempt.is_cancelled());
    drop(guard);

    let next = ConnectionAttemptGuard::acquire(Arc::clone(&attempts)).unwrap();
    drop(next);
    attempts.cancel_current(true);
    let error = match ConnectionAttemptGuard::acquire(attempts) {
        Ok(_) => panic!("closed connection registry accepted an attempt"),
        Err(error) => error,
    };
    assert_eq!(error.code, NativeXelisErrorCode::Cancelled);
}

#[tokio::test]
async fn connection_attempt_guard_publishes_worker_completion() {
    let attempts = Arc::new(WalletConnectionAttempts::default());
    let guard = ConnectionAttemptGuard::acquire(attempts).unwrap();
    let attempt = guard.attempt();

    assert!(!attempt.completed.load(std::sync::atomic::Ordering::Acquire));
    drop(guard);
    attempt.wait_completed().await;
    assert!(attempt.completed.load(std::sync::atomic::Ordering::Acquire));
}

#[test]
fn offline_mode_accepts_states_that_are_already_disconnected() {
    assert!(normalize_offline_mode_result(Err(WalletError::NotOnlineMode)).is_ok());
    assert!(normalize_offline_mode_result(Err(WalletError::NetworkError(
        NetworkError::NotRunning,
    )))
    .is_ok());
    assert!(normalize_offline_mode_result(Err(WalletError::NetworkError(
        NetworkError::DaemonAPIError(anyhow!("finished network task")),
    )))
    .is_ok());
}

#[test]
fn offline_mode_preserves_unexpected_network_handler_failures() {
    let error = normalize_offline_mode_result(Err(WalletError::NetworkError(
        NetworkError::NetworkMismatch,
    )))
    .unwrap_err();

    assert_eq!(error.code, NativeXelisErrorCode::NetworkMismatch);
    assert_eq!(error.native_kind.as_deref(), Some("NETWORK_MISMATCH"));
}

#[test]
fn mt_params_reserve_cores_and_apply_bounds() {
    assert_eq!(mt_params_for_cpu_cores(0), (1, 4));
    assert_eq!(mt_params_for_cpu_cores(1), (1, 4));
    assert_eq!(mt_params_for_cpu_cores(2), (1, 4));
    assert_eq!(mt_params_for_cpu_cores(8), (6, 24));
    assert_eq!(mt_params_for_cpu_cores(64), (32, 128));
}

#[test]
fn recovery_rejects_seed_and_private_key_together() {
    let error = recovery_input_kind(true, true).unwrap_err();

    assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("WALLET_RECOVERY_INPUT_CONFLICT")
    );
}

#[test]
fn recovery_maps_each_valid_input_without_precedence() {
    let seed = recovery_input_kind(true, false).unwrap();
    let private_key = recovery_input_kind(false, true).unwrap();
    let none = recovery_input_kind(false, false).unwrap();

    assert!(matches!(
        recover_option(seed, Some("seed words"), None),
        RecoverOption::Seed("seed words")
    ));
    assert!(matches!(
        recover_option(private_key, None, Some("private-key")),
        RecoverOption::PrivateKey("private-key")
    ));
    assert!(matches!(
        recover_option(none, None, None),
        RecoverOption::None
    ));

    assert!(matches!(seed, RecoveryInputKind::Seed));
    assert!(matches!(private_key, RecoveryInputKind::PrivateKey));
    assert!(matches!(none, RecoveryInputKind::None));
}

#[test]
fn l1_sizes_map_to_known_and_custom_table_types() {
    assert!(matches!(
        precomputed_table_type_from_l1(L1_LOW),
        PrecomputedTableType::L1Low
    ));
    assert!(matches!(
        precomputed_table_type_from_l1(L1_MEDIUM),
        PrecomputedTableType::L1Medium
    ));
    assert!(matches!(
        precomputed_table_type_from_l1(L1_FULL),
        PrecomputedTableType::L1Full
    ));
    assert!(matches!(
        precomputed_table_type_from_l1(24),
        PrecomputedTableType::Custom(24)
    ));
}

#[test]
fn daemon_origin_is_normalized_like_the_upstream_network_handler() {
    assert_eq!(
        daemon_rpc_endpoint("https://node.xelis.io/").unwrap(),
        "wss://node.xelis.io/json_rpc"
    );
    assert_eq!(
        daemon_rpc_endpoint("http://127.0.0.1:8080").unwrap(),
        "ws://127.0.0.1:8080/json_rpc"
    );
    assert_eq!(
        daemon_rpc_endpoint("wss://node.xelis.io").unwrap(),
        "wss://node.xelis.io/json_rpc"
    );
    assert_eq!(
        daemon_rpc_endpoint("node.xelis.io").unwrap(),
        "wss://node.xelis.io/json_rpc"
    );
    assert_eq!(
        daemon_rpc_endpoint("127.0.0.1:8080").unwrap(),
        "ws://127.0.0.1:8080/json_rpc"
    );
}

#[test]
fn daemon_origin_rejects_unsafe_or_ambiguous_addresses() {
    for address in [
        "",
        "not a valid origin",
        "ftp://node.xelis.io",
        "https://user:secret@node.xelis.io",
        "https://node.xelis.io/custom",
        "https://node.xelis.io/?token=secret",
        "https://node.xelis.io/#fragment",
    ] {
        let error = daemon_rpc_endpoint(address).unwrap_err();
        assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
        assert_eq!(error.native_kind.as_deref(), Some("DAEMON_ADDRESS_INVALID"));
        assert!(address.is_empty() || !error.diagnostic_message.contains(address));
    }
}

#[test]
fn daemon_network_preflight_is_typed_without_text_matching() {
    assert!(ensure_daemon_network(&Network::Mainnet, &Network::Mainnet).is_ok());

    let error = ensure_daemon_network(&Network::Mainnet, &Network::Testnet).unwrap_err();
    assert_eq!(error.code, NativeXelisErrorCode::NetworkMismatch);
    assert_eq!(error.native_kind.as_deref(), Some("NETWORK_MISMATCH"));
}
