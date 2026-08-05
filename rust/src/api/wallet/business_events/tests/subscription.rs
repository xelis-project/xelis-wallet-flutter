use super::*;

#[test]
fn filters_runtime_events_from_the_business_cursor() {
    assert!(business_event_from_wallet_event(Event::Online)
        .unwrap()
        .is_none());
    assert!(
        business_event_from_wallet_event(Event::NewTopoHeight { topoheight: 42 })
            .unwrap()
            .is_none()
    );
}

#[test]
fn subscription_reports_lag_and_then_recovers() {
    let (sender, receiver) = broadcast::channel(1);
    let subscription = WalletBusinessEventSubscription::new(4, receiver);
    sender
        .send(Event::TrackAsset {
            asset: Hash::new([1; 32]),
        })
        .unwrap();
    sender
        .send(Event::TrackAsset {
            asset: Hash::new([2; 32]),
        })
        .unwrap();

    let degraded = next(&subscription).unwrap();
    assert_eq!(degraded.sequence, 1);
    match degraded.event {
        NativeWalletBusinessEvent::Degraded {
            skipped_events,
            failure,
        } => {
            assert_eq!(skipped_events, 1);
            assert_eq!(failure.code, NativeXelisErrorCode::StreamLagged);
        }
        _ => panic!("expected degraded event"),
    }

    let recovered = next(&subscription).unwrap();
    assert_eq!(recovered.sequence, 2);
    assert!(matches!(
        recovered.event,
        NativeWalletBusinessEvent::AssetTracked { .. }
    ));
}

#[tokio::test]
async fn native_channel_close_is_reported_once_then_terminates() {
    let (sender, receiver) = broadcast::channel(1);
    let subscription = WalletBusinessEventSubscription::new(3, receiver);
    drop(sender);

    let closed = subscription.next_event().await.unwrap().unwrap();
    match closed.event {
        NativeWalletBusinessEvent::Closed { reason, failure } => {
            assert_eq!(
                reason,
                NativeWalletBusinessStreamCloseReason::NativeChannelClosed
            );
            assert_eq!(failure.code, NativeXelisErrorCode::StreamClosedUnexpectedly);
            assert_eq!(
                failure.native_kind.as_deref(),
                Some("WALLET_BUSINESS_EVENT_STREAM_CLOSED")
            );
        }
        event => panic!("expected closed event, got {event:?}"),
    }
    assert!(subscription.next_event().await.unwrap().is_none());
}

#[test]
fn cancellation_wakes_an_in_flight_read() {
    let (_sender, receiver) = broadcast::channel(1);
    let subscription = std::sync::Arc::new(WalletBusinessEventSubscription::new(1, receiver));
    let reader = subscription.clone();
    let thread = std::thread::spawn(move || block_on(reader.next_event()).unwrap());
    std::thread::yield_now();
    subscription.cancel();
    assert!(thread.join().unwrap().is_none());
}

#[test]
fn generation_is_monotone_and_checked() {
    let mut generation = 0;
    assert_eq!(next_business_event_generation(&mut generation).unwrap(), 1);
    assert_eq!(next_business_event_generation(&mut generation).unwrap(), 2);

    let mut exhausted = u64::MAX;
    let error = next_business_event_generation(&mut exhausted).unwrap_err();
    assert_eq!(error.code, NativeXelisErrorCode::Internal);
}
