use std::borrow::Cow;
use std::path::Path;
use std::sync::{Arc, RwLock};
use std::time::Duration;

use anyhow::anyhow;
use futures::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{accept_async, tungstenite::Message, WebSocketStream};
use xelis_common::api::daemon::{BlockOrderedEvent, BlockType, GetInfoResult};
use xelis_common::block::BlockVersion;
use xelis_common::crypto::{ecdlp::ECDLPTables, Hash};
use xelis_common::difficulty::Difficulty;
use xelis_common::network::Network;
use xelis_common::tokio::net::{TcpListener, TcpStream};
use xelis_common::tokio::sync::oneshot;
use xelis_wallet::daemon_api::DaemonAPI;
use xelis_wallet::error::WalletError;
use xelis_wallet::network_handler::NetworkError;
use xelis_wallet::precomputed_tables::{PrecomputedTablesShared, L1_FULL, L1_LOW, L1_MEDIUM};
use xelis_wallet::wallet::RecoverOption;
use xelis_wallet::wallet::Wallet;

use super::super::XelisWallet;
use super::{
    await_connection_acknowledgements, complete_connection_timeout, complete_offline_mode,
    daemon_rpc_endpoint, ensure_daemon_network, mt_params_for_cpu_cores,
    normalize_offline_mode_result, precomputed_table_type_from_l1, recover_option,
    recovery_input_kind, resolve_wallet_path, ConnectionAttemptGuard, RecoveryInputKind,
};
use crate::api::error::NativeXelisErrorCode;
use crate::api::models::runtime_dtos::{
    NativeWalletConnectionOptions, NativeWalletReconnectPolicy,
};
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

// Models the worker immediately after successful result delivery, while the
// caller has selected its timeout branch. Explicit polling fixes the ordering;
// no network timing, sleeps, or scheduler luck participates in this regression.
#[tokio::test]
async fn connection_timeout_releases_worker_acknowledgements_before_join() {
    let attempts = Arc::new(WalletConnectionAttempts::default());
    let guard = ConnectionAttemptGuard::acquire(Arc::clone(&attempts)).unwrap();
    let attempt = guard.attempt();
    let (accepted, accepted_receiver) = oneshot::channel();
    let (finalized, finalized_receiver) = oneshot::channel();
    let mut worker = Box::pin(observe_connection_handshake(
        guard,
        accepted_receiver,
        finalized_receiver,
    ));
    assert!(futures::poll!(worker.as_mut()).is_pending());
    let mut cleanup = Box::pin(complete_connection_timeout(
        accepted,
        finalized,
        cancel_test_connection_attempt(&attempts),
    ));
    assert!(futures::poll!(cleanup.as_mut()).is_pending());
    assert!(attempt.is_cancelled());
    assert_eq!(
        futures::poll!(worker.as_mut()),
        std::task::Poll::Ready(false)
    );
    let error = cleanup.await.unwrap_err();
    assert_eq!(
        error.native_kind.as_deref(),
        Some("NETWORK_CONNECT_TIMEOUT")
    );
    assert!(ConnectionAttemptGuard::acquire(attempts).is_ok());
}

async fn observe_connection_handshake(
    guard: ConnectionAttemptGuard,
    accepted: oneshot::Receiver<()>,
    finalized: oneshot::Receiver<()>,
) -> bool {
    let finalized = await_connection_acknowledgements(accepted, finalized).await;
    let activated = finalized && !guard.attempt().is_cancelled();
    drop(guard);
    activated
}

async fn cancel_test_connection_attempt(attempts: &WalletConnectionAttempts) {
    if let Some(attempt) = attempts.cancel_current(false) {
        attempt.wait_completed().await;
    }
}

#[tokio::test]
async fn connection_handshake_requires_both_acknowledgements() {
    let attempts = Arc::new(WalletConnectionAttempts::default());
    let guard = ConnectionAttemptGuard::acquire(attempts).unwrap();
    let (accepted, accepted_receiver) = oneshot::channel();
    let (finalized, finalized_receiver) = oneshot::channel();
    let mut worker = Box::pin(observe_connection_handshake(
        guard,
        accepted_receiver,
        finalized_receiver,
    ));
    assert!(futures::poll!(worker.as_mut()).is_pending());
    accepted.send(()).unwrap();
    assert!(futures::poll!(worker.as_mut()).is_pending());
    finalized.send(()).unwrap();
    assert_eq!(
        futures::poll!(worker.as_mut()),
        std::task::Poll::Ready(true)
    );
}

#[tokio::test]
async fn connection_handshake_abandonment_never_activates() {
    for acknowledge_first in [false, true] {
        let attempts = Arc::new(WalletConnectionAttempts::default());
        let guard = ConnectionAttemptGuard::acquire(Arc::clone(&attempts)).unwrap();
        let (accepted, accepted_receiver) = oneshot::channel();
        let (finalized, finalized_receiver) = oneshot::channel();
        let worker = observe_connection_handshake(guard, accepted_receiver, finalized_receiver);
        if acknowledge_first {
            accepted.send(()).unwrap();
        } else {
            drop(accepted);
        }
        drop(finalized);
        assert!(!worker.await);
        assert!(ConnectionAttemptGuard::acquire(attempts).is_ok());
    }
}

#[tokio::test]
async fn connection_handshake_terminal_cancellation_prevents_late_activation() {
    let attempts = Arc::new(WalletConnectionAttempts::default());
    let guard = ConnectionAttemptGuard::acquire(Arc::clone(&attempts)).unwrap();
    let (accepted, accepted_receiver) = oneshot::channel();
    let (finalized, finalized_receiver) = oneshot::channel();
    let mut worker = Box::pin(observe_connection_handshake(
        guard,
        accepted_receiver,
        finalized_receiver,
    ));
    accepted.send(()).unwrap();
    assert!(futures::poll!(worker.as_mut()).is_pending());
    attempts.cancel_current(true);
    finalized.send(()).unwrap();
    assert_eq!(
        futures::poll!(worker.as_mut()),
        std::task::Poll::Ready(false)
    );
    assert!(ConnectionAttemptGuard::acquire(attempts).is_err());
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

#[tokio::test]
async fn offline_completion_is_not_bounded_by_the_connection_timeout() {
    let (release, released) = xelis_common::tokio::sync::oneshot::channel();
    let completion = complete_offline_mode(async move {
        released.await.unwrap();
        Ok(())
    });
    tokio::pin!(completion);

    assert!(
        xelis_common::tokio::time::timeout(Duration::from_millis(10), completion.as_mut(),)
            .await
            .is_err()
    );

    release.send(()).unwrap();
    assert!(completion.await.is_ok());
}

struct LocalDaemonFixture {
    address: String,
    subscriptions_ready: Option<oneshot::Receiver<()>>,
    trigger_block_event: Option<oneshot::Sender<bool>>,
    block_request_seen: Option<oneshot::Receiver<()>>,
    release_block_request: Option<oneshot::Sender<()>>,
    task: Option<xelis_common::tokio::task::JoinHandle<()>>,
}

impl LocalDaemonFixture {
    async fn start(top_block_hash: Hash) -> Self {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = format!("ws://{}", listener.local_addr().unwrap());
        let (subscriptions_ready_tx, subscriptions_ready) = oneshot::channel();
        let (trigger_block_event, trigger_block_event_rx) = oneshot::channel();
        let (block_request_seen_tx, block_request_seen) = oneshot::channel();
        let (release_block_request, release_block_request_rx) = oneshot::channel();
        let task = xelis_common::tokio::spawn(async move {
            run_local_daemon(
                listener,
                top_block_hash,
                subscriptions_ready_tx,
                trigger_block_event_rx,
                block_request_seen_tx,
                release_block_request_rx,
            )
            .await;
        });

        Self {
            address,
            subscriptions_ready: Some(subscriptions_ready),
            trigger_block_event: Some(trigger_block_event),
            block_request_seen: Some(block_request_seen),
            release_block_request: Some(release_block_request),
            task: Some(task),
        }
    }

    async fn wait_until_subscribed(&mut self) {
        xelis_common::tokio::time::timeout(
            Duration::from_secs(5),
            self.subscriptions_ready.take().unwrap(),
        )
        .await
        .expect("network handler did not establish daemon subscriptions")
        .unwrap();
    }

    fn trigger_block_event(&mut self) {
        self.trigger_block_event.take().unwrap().send(true).unwrap();
    }

    fn skip_block_event(&mut self) {
        self.trigger_block_event
            .take()
            .unwrap()
            .send(false)
            .unwrap();
    }

    async fn wait_for_block_request(&mut self) {
        xelis_common::tokio::time::timeout(
            Duration::from_secs(5),
            self.block_request_seen.take().unwrap(),
        )
        .await
        .expect("network handler did not process the controlled block event")
        .unwrap();
    }

    fn release_block_request(&mut self) {
        self.release_block_request.take().unwrap().send(()).unwrap();
    }

    async fn wait_for_shutdown(&mut self) {
        xelis_common::tokio::time::timeout(Duration::from_secs(5), self.task.take().unwrap())
            .await
            .expect("local daemon did not shut down")
            .expect("local daemon task panicked");
    }
}

impl Drop for LocalDaemonFixture {
    fn drop(&mut self) {
        if let Some(task) = self.task.take() {
            task.abort();
        }
    }
}

async fn run_local_daemon(
    listener: TcpListener,
    top_block_hash: Hash,
    subscriptions_ready: oneshot::Sender<()>,
    trigger_block_event: oneshot::Receiver<bool>,
    block_request_seen: oneshot::Sender<()>,
    release_block_request: oneshot::Receiver<()>,
) {
    let (stream, _) = listener.accept().await.unwrap();
    let mut socket = accept_async(stream).await.unwrap();
    let info = GetInfoResult {
        height: 0,
        topoheight: 0,
        stableheight: 0,
        stable_topoheight: 0,
        pruned_topoheight: None,
        top_block_hash: top_block_hash.clone(),
        circulating_supply: 0,
        burned_supply: 0,
        emitted_supply: 0,
        maximum_supply: 0,
        difficulty: Difficulty::from(0_u64),
        block_time_target: 1000,
        average_block_time: 1000,
        block_reward: 0,
        dev_reward: 0,
        miner_reward: 0,
        mempool_size: 0,
        version: "local-test-daemon".to_owned(),
        network: Network::Devnet,
        block_version: BlockVersion::V0,
    };
    let info = serde_json::to_value(info).unwrap();
    let mut block_subscription_id = None;
    let mut subscription_count = 0;
    let mut subscriptions_ready = Some(subscriptions_ready);
    let mut trigger_block_event = Some(trigger_block_event);
    let mut block_request_seen = Some(block_request_seen);
    let mut release_block_request = Some(release_block_request);

    while let Some(message) = socket.next().await {
        let Ok(Message::Text(text)) = message else {
            break;
        };
        let request: Value = serde_json::from_str(text.as_ref()).unwrap();
        let id = request["id"].clone();
        match request["method"].as_str().unwrap() {
            "get_version" => {
                send_local_daemon_result(&mut socket, id, json!("local-test-daemon")).await;
            }
            "get_info" => {
                send_local_daemon_result(&mut socket, id, info.clone()).await;
            }
            "get_nonce" => {
                send_local_daemon_error(&mut socket, id, "account is not registered").await;
            }
            "subscribe" => {
                if block_subscription_id.is_none() {
                    block_subscription_id = Some(id.clone());
                }
                send_local_daemon_result(&mut socket, id, json!(true)).await;
                subscription_count += 1;
                if subscription_count == 3 {
                    subscriptions_ready.take().unwrap().send(()).unwrap();
                    if !trigger_block_event.take().unwrap().await.unwrap() {
                        continue;
                    }
                    let event = BlockOrderedEvent {
                        block_hash: Cow::Owned(Hash::new([9; 32])),
                        block_type: BlockType::Normal,
                        topoheight: 1,
                    };
                    send_local_daemon_result(
                        &mut socket,
                        block_subscription_id.take().unwrap(),
                        serde_json::to_value(event).unwrap(),
                    )
                    .await;
                }
            }
            "get_block_at_topoheight" | "get_block_with_txs_at_topoheight" => {
                block_request_seen.take().unwrap().send(()).unwrap();
                release_block_request.take().unwrap().await.unwrap();
                send_local_daemon_error(&mut socket, id, "controlled block read failure").await;
            }
            method => panic!("unexpected daemon method: {method}"),
        }
    }
}

async fn send_local_daemon_result(
    socket: &mut WebSocketStream<TcpStream>,
    id: Value,
    result: Value,
) {
    send_local_daemon_message(
        socket,
        json!({"jsonrpc": "2.0", "id": id, "result": result}),
    )
    .await;
}

async fn send_local_daemon_error(
    socket: &mut WebSocketStream<TcpStream>,
    id: Value,
    message: &str,
) {
    send_local_daemon_message(
        socket,
        json!({
            "jsonrpc": "2.0",
            "id": id,
            "error": {"code": -32000, "message": message}
        }),
    )
    .await;
}

async fn send_local_daemon_message(socket: &mut WebSocketStream<TcpStream>, value: Value) {
    socket
        .send(Message::Text(value.to_string().into()))
        .await
        .unwrap();
}

#[tokio::test]
#[ignore = "uses production Argon2 parameters; run explicitly as the real network-handler lifecycle test"]
async fn real_network_handler_wrapper_offline_waits_for_inflight_sync() {
    let directory = tempfile::tempdir().unwrap();
    let wallet_path = directory.path().join("wallet");
    let wallet_path = wallet_path.to_string_lossy().into_owned();
    let top_block_hash = Hash::new([7; 32]);
    let tables: PrecomputedTablesShared = Arc::new(RwLock::new(ECDLPTables::empty(1)));
    let wallet = Wallet::create(
        &wallet_path,
        "integration-test-password",
        RecoverOption::None,
        Network::Devnet,
        tables,
        1,
        1,
    )
    .await
    .unwrap();
    {
        let mut storage = wallet.get_storage().write().await;
        storage.set_synced_topoheight(0).unwrap();
        storage.set_top_block_hash(&top_block_hash).unwrap();
    }
    let wrapper = XelisWallet {
        wallet: Arc::clone(&wallet),
        connection_attempts: Default::default(),
        active_connection: Default::default(),
        runtime_event_generation: Default::default(),
        business_event_generation: Default::default(),
        asset_resolution: Default::default(),
        prepared_transaction: Default::default(),
        pending_multisig: Default::default(),
        xswd_sessions: Default::default(),
    };
    let mut priming_daemon = LocalDaemonFixture::start(top_block_hash.clone()).await;
    wrapper
        .online_mode(
            priming_daemon.address.clone(),
            NativeWalletConnectionOptions {
                timeout_millis: 500,
                reconnect_policy: NativeWalletReconnectPolicy::ApplicationManaged,
            },
        )
        .await
        .unwrap();
    priming_daemon.wait_until_subscribed().await;
    let active_connection = wrapper.active_connection.lock().await.take().unwrap();
    priming_daemon.skip_block_event();
    complete_offline_mode(wallet.set_offline_mode())
        .await
        .unwrap();
    active_connection.api.disconnect_force().await.unwrap();
    priming_daemon.wait_for_shutdown().await;

    let mut daemon = LocalDaemonFixture::start(top_block_hash).await;
    let handler_api = Arc::new(
        DaemonAPI::with(
            format!("{}/json_rpc", daemon.address),
            Some(Duration::from_secs(30)),
            64,
        )
        .await
        .unwrap(),
    );
    wallet
        .set_online_mode_with_api(Arc::clone(&handler_api), false)
        .await
        .unwrap();
    drop(handler_api);
    *wrapper.active_connection.lock().await = Some(active_connection);
    daemon.wait_until_subscribed().await;
    daemon.trigger_block_event();
    daemon.wait_for_block_request().await;

    // Keep the active record created with the authored 500 ms connection
    // timeout, but install the controlled handler with a separate 30 s RPC
    // client. If the timeout field is reintroduced, the wrapper still observes
    // 500 ms, while force-disconnect targets the already closed priming API and
    // cannot release the controlled handler. This exercises the complete
    // XelisWallet::offline_mode method that previously dropped its shutdown
    // future when the connection timeout elapsed.
    let completion = wrapper.offline_mode();
    tokio::pin!(completion);
    assert!(
        xelis_common::tokio::time::timeout(Duration::from_millis(750), completion.as_mut())
            .await
            .is_err(),
        "offline completed before the in-flight handler work was released"
    );

    daemon.release_block_request();
    assert!(
        xelis_common::tokio::time::timeout(Duration::from_secs(5), completion)
            .await
            .expect("offline did not await the released network handler")
            .is_ok()
    );
    assert!(!wrapper.is_online().await);
    wrapper.close().await;
    daemon.wait_for_shutdown().await;
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
