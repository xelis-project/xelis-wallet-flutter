use std::sync::Arc;

use xelis_common::{
    crypto::Hash,
    tokio::{
        sync::broadcast,
        task::{self, yield_now},
        time::{timeout, Duration},
    },
};
use xelis_wallet::wallet::Event;

use super::*;
use crate::api::error::{NativeXelisErrorCode, NativeXelisErrorSource};

#[tokio::test]
async fn subscription_filters_business_events_and_preserves_runtime_order() {
    let (sender, receiver) = broadcast::channel(4);
    let subscription = WalletRuntimeEventSubscription::new(7, receiver);

    sender.send(Event::Online).unwrap();
    sender
        .send(Event::TrackAsset {
            asset: Hash::new([7; 32]),
        })
        .unwrap();
    sender
        .send(Event::NewTopoHeight { topoheight: 42 })
        .unwrap();

    let online = subscription.next_event().await.unwrap().unwrap();
    let topoheight = subscription.next_event().await.unwrap().unwrap();

    assert_eq!(online.generation, 7);
    assert_eq!(online.sequence, 1);
    assert_eq!(online.version, NATIVE_WALLET_RUNTIME_EVENT_VERSION);
    assert!(matches!(online.event, NativeWalletRuntimeEvent::Online));
    assert_eq!(topoheight.sequence, 2);
    assert!(matches!(
        topoheight.event,
        NativeWalletRuntimeEvent::NewTopoHeight { topoheight: 42 }
    ));
}

#[test]
fn runtime_mapping_preserves_every_control_payload_and_filters_asset_events() {
    assert!(matches!(
        runtime_event_from_wallet_event(Event::Offline),
        Some(NativeWalletRuntimeEvent::Offline)
    ));
    assert!(matches!(
        runtime_event_from_wallet_event(Event::Rescan {
            start_topoheight: 12
        }),
        Some(NativeWalletRuntimeEvent::Rescan {
            start_topoheight: 12
        })
    ));
    assert!(matches!(
        runtime_event_from_wallet_event(Event::HistorySynced { topoheight: 34 }),
        Some(NativeWalletRuntimeEvent::HistorySynced { topoheight: 34 })
    ));
    assert!(runtime_event_from_wallet_event(Event::TrackAsset {
        asset: Hash::new([1; 32]),
    })
    .is_none());
    assert!(runtime_event_from_wallet_event(Event::UntrackAsset {
        asset: Hash::new([2; 32]),
    })
    .is_none());
}

#[tokio::test]
async fn lag_is_reported_before_the_next_preserved_event() {
    let (sender, receiver) = broadcast::channel(1);
    let subscription = WalletRuntimeEventSubscription::new(1, receiver);

    sender.send(Event::NewTopoHeight { topoheight: 1 }).unwrap();
    sender.send(Event::NewTopoHeight { topoheight: 2 }).unwrap();
    sender.send(Event::NewTopoHeight { topoheight: 3 }).unwrap();

    let degraded = subscription.next_event().await.unwrap().unwrap();
    let preserved = subscription.next_event().await.unwrap().unwrap();

    match degraded.event {
        NativeWalletRuntimeEvent::Degraded {
            skipped_events,
            failure,
        } => {
            assert_eq!(skipped_events, 2);
            assert_eq!(failure.source, NativeXelisErrorSource::XelisWalletFlutter);
            assert_eq!(failure.code, NativeXelisErrorCode::StreamLagged);
            assert_eq!(failure.native_kind.as_deref(), Some("WALLET_EVENTS_LAGGED"));
        }
        event => panic!("expected degradation event, got {event:?}"),
    }
    assert_eq!(degraded.sequence, 1);
    assert_eq!(preserved.sequence, 2);
    assert!(matches!(
        preserved.event,
        NativeWalletRuntimeEvent::NewTopoHeight { topoheight: 3 }
    ));
}

#[tokio::test]
async fn native_channel_close_is_reported_once_then_terminates() {
    let (sender, receiver) = broadcast::channel(1);
    let subscription = WalletRuntimeEventSubscription::new(3, receiver);
    drop(sender);

    let closed = subscription.next_event().await.unwrap().unwrap();
    match closed.event {
        NativeWalletRuntimeEvent::Closed { reason, failure } => {
            assert_eq!(
                reason,
                NativeWalletRuntimeStreamCloseReason::NativeChannelClosed
            );
            assert_eq!(failure.code, NativeXelisErrorCode::StreamClosedUnexpectedly);
            assert_eq!(
                failure.native_kind.as_deref(),
                Some("WALLET_EVENT_STREAM_CLOSED")
            );
        }
        event => panic!("expected closed event, got {event:?}"),
    }
    assert!(subscription.next_event().await.unwrap().is_none());
}

#[tokio::test]
async fn cancellation_wakes_a_pending_read_and_is_idempotent() {
    let (_sender, receiver) = broadcast::channel(1);
    let subscription = Arc::new(WalletRuntimeEventSubscription::new(9, receiver));
    let pending_subscription = Arc::clone(&subscription);
    let pending = task::spawn(async move { pending_subscription.next_event().await });
    yield_now().await;

    subscription.cancel();
    subscription.cancel();

    let result = timeout(Duration::from_secs(1), pending)
        .await
        .expect("pending read should wake")
        .expect("read task should complete")
        .expect("cancellation is not an error");
    assert!(result.is_none());
    assert!(subscription.next_event().await.unwrap().is_none());
}

#[tokio::test]
async fn cancellation_wins_over_an_already_buffered_event() {
    let (sender, receiver) = broadcast::channel(1);
    let subscription = WalletRuntimeEventSubscription::new(9, receiver);
    sender.send(Event::Online).unwrap();

    subscription.cancel();

    assert!(subscription.next_event().await.unwrap().is_none());
}

#[tokio::test]
async fn concurrent_reads_are_rejected_without_breaking_the_first_read() {
    let (sender, receiver) = broadcast::channel(1);
    let subscription = Arc::new(WalletRuntimeEventSubscription::new(1, receiver));
    let pending_subscription = Arc::clone(&subscription);
    let pending = task::spawn(async move { pending_subscription.next_event().await });
    yield_now().await;

    let error = subscription.next_event().await.unwrap_err();
    assert_eq!(error.code, NativeXelisErrorCode::OperationInProgress);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("WALLET_EVENT_NEXT_IN_PROGRESS")
    );

    sender.send(Event::Online).unwrap();
    let frame = pending
        .await
        .expect("read task should complete")
        .expect("first read should succeed")
        .expect("first read should produce an event");
    assert!(matches!(frame.event, NativeWalletRuntimeEvent::Online));

    sender.send(Event::Offline).unwrap();
    let recovered = subscription.next_event().await.unwrap().unwrap();
    assert_eq!(recovered.sequence, 2);
    assert!(matches!(recovered.event, NativeWalletRuntimeEvent::Offline));
}

#[test]
fn sync_issue_keeps_upstream_text_only_in_privileged_diagnostics() {
    let private_message = "sync failed for C:\\private\\wallet.db";
    let event = runtime_event_from_wallet_event(Event::SyncError {
        message: private_message.to_owned(),
    })
    .unwrap();

    match event {
        NativeWalletRuntimeEvent::SyncIssue { failure } => {
            assert_eq!(failure.source, NativeXelisErrorSource::XelisWallet);
            assert_eq!(failure.code, NativeXelisErrorCode::OperationFailed);
            assert_eq!(failure.native_kind.as_deref(), Some("WALLET_SYNC_ERROR"));
            assert_eq!(failure.diagnostic_message, private_message);
            assert!(!failure.to_string().contains("private"));
            assert!(!format!("{failure:?}").contains("private"));
        }
        event => panic!("expected sync issue event, got {event:?}"),
    }
}

#[test]
fn sequence_overflow_fails_before_reusing_an_identifier() {
    let mut next_sequence = u64::MAX - 1;
    let frame = next_frame(1, &mut next_sequence, NativeWalletRuntimeEvent::Online).unwrap();
    assert_eq!(frame.sequence, u64::MAX - 1);

    let error = next_frame(1, &mut next_sequence, NativeWalletRuntimeEvent::Online).unwrap_err();
    assert_eq!(error.code, NativeXelisErrorCode::Internal);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("WALLET_EVENT_SEQUENCE_EXHAUSTED")
    );
}

#[test]
fn subscription_generation_starts_at_one_and_increments() {
    let mut current_generation = 0;

    assert_eq!(
        next_runtime_event_generation(&mut current_generation).unwrap(),
        1
    );
    assert_eq!(
        next_runtime_event_generation(&mut current_generation).unwrap(),
        2
    );
    assert_eq!(current_generation, 2);
}

#[test]
fn subscription_generation_overflow_does_not_mutate_the_counter() {
    let mut current_generation = u64::MAX;

    let error = next_runtime_event_generation(&mut current_generation).unwrap_err();

    assert_eq!(current_generation, u64::MAX);
    assert_eq!(error.source, NativeXelisErrorSource::XelisWalletFlutter);
    assert_eq!(error.code, NativeXelisErrorCode::Internal);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("WALLET_EVENT_GENERATION_EXHAUSTED")
    );
}
