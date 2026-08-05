use std::sync::atomic::{AtomicBool, Ordering};

use flutter_rust_bridge::frb;
use xelis_common::tokio::{
    select,
    sync::{
        broadcast::{error::RecvError, Receiver},
        watch, Mutex,
    },
};
use xelis_wallet::wallet::Event;

use super::XelisWallet;
use crate::api::{
    error::{NativeXelisError, NativeXelisErrorCode},
    models::runtime_event_dtos::{
        NativeWalletRuntimeEvent, NativeWalletRuntimeEventFrame,
        NativeWalletRuntimeStreamCloseReason, NATIVE_WALLET_RUNTIME_EVENT_VERSION,
    },
};

struct WalletRuntimeEventSubscriptionState {
    receiver: Receiver<Event>,
    cancellation: watch::Receiver<bool>,
    next_sequence: u64,
}

/// Pull-driven native cursor for one generation of wallet runtime events.
///
/// The authored Dart wrapper is responsible for exposing this private bridge
/// object as a single-subscription `Stream` and for cancelling it before the
/// wallet handle is closed.
#[frb(opaque)]
pub struct WalletRuntimeEventSubscription {
    generation: u64,
    state: Mutex<WalletRuntimeEventSubscriptionState>,
    cancellation: watch::Sender<bool>,
    cancelled: AtomicBool,
    next_in_progress: AtomicBool,
    terminated: AtomicBool,
}

struct NextEventGuard<'a> {
    in_progress: &'a AtomicBool,
}

impl Drop for NextEventGuard<'_> {
    fn drop(&mut self) {
        self.in_progress.store(false, Ordering::Release);
    }
}

impl WalletRuntimeEventSubscription {
    #[frb(ignore)]
    fn new(generation: u64, receiver: Receiver<Event>) -> Self {
        let (cancellation, cancellation_receiver) = watch::channel(false);
        Self {
            generation,
            state: Mutex::new(WalletRuntimeEventSubscriptionState {
                receiver,
                cancellation: cancellation_receiver,
                next_sequence: 1,
            }),
            cancellation,
            cancelled: AtomicBool::new(false),
            next_in_progress: AtomicBool::new(false),
            terminated: AtomicBool::new(false),
        }
    }

    #[frb(sync)]
    pub fn generation(&self) -> u64 {
        self.generation
    }

    /// Waits for the next runtime event, a degradation marker, or termination.
    ///
    /// Business events are deliberately consumed but not returned by this
    /// connection-scoped subscription. The separate session-scoped business
    /// subscription owns their package-authored typed contract.
    pub async fn next_event(
        &self,
    ) -> Result<Option<NativeWalletRuntimeEventFrame>, NativeXelisError> {
        let _next_guard = self.begin_next()?;
        if self.cancelled.load(Ordering::Acquire) || self.terminated.load(Ordering::Acquire) {
            return Ok(None);
        }

        let mut state = self.state.lock().await;
        loop {
            if self.cancelled.load(Ordering::Acquire) {
                return Ok(None);
            }

            let WalletRuntimeEventSubscriptionState {
                receiver,
                cancellation,
                next_sequence,
            } = &mut *state;

            let received = select! {
                biased;
                cancellation_result = cancellation.changed() => {
                    let _ = cancellation_result;
                    return Ok(None);
                }
                received = receiver.recv() => received,
            };

            match received {
                Ok(event) => {
                    if let Some(event) = runtime_event_from_wallet_event(event) {
                        return Ok(Some(next_frame(self.generation, next_sequence, event)?));
                    }
                }
                Err(RecvError::Lagged(skipped_events)) => {
                    let failure = NativeXelisError::xelis_wallet_flutter(
                        NativeXelisErrorCode::StreamLagged,
                        "WALLET_EVENTS_LAGGED",
                        format!("Runtime event receiver skipped {skipped_events} upstream events"),
                    );
                    return Ok(Some(next_frame(
                        self.generation,
                        next_sequence,
                        NativeWalletRuntimeEvent::Degraded {
                            skipped_events,
                            failure,
                        },
                    )?));
                }
                Err(RecvError::Closed) => {
                    self.terminated.store(true, Ordering::Release);
                    return Ok(Some(next_frame(
                        self.generation,
                        next_sequence,
                        NativeWalletRuntimeEvent::Closed {
                            reason: NativeWalletRuntimeStreamCloseReason::NativeChannelClosed,
                            failure: NativeXelisError::xelis_wallet_flutter(
                                NativeXelisErrorCode::StreamClosedUnexpectedly,
                                "WALLET_EVENT_STREAM_CLOSED",
                                "Native wallet event channel closed while the subscription was active",
                            ),
                        },
                    )?));
                }
            }
        }
    }

    /// Cancels this subscription and wakes an in-flight `next_event` call.
    #[frb(sync)]
    pub fn cancel(&self) {
        self.cancel_internal();
    }

    fn begin_next(&self) -> Result<NextEventGuard<'_>, NativeXelisError> {
        self.next_in_progress
            .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
            .map_err(|_| {
                NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::OperationInProgress,
                    "WALLET_EVENT_NEXT_IN_PROGRESS",
                    "Only one runtime event read may be active per subscription",
                )
            })?;
        Ok(NextEventGuard {
            in_progress: &self.next_in_progress,
        })
    }

    fn cancel_internal(&self) {
        if !self.cancelled.swap(true, Ordering::AcqRel) {
            let _ = self.cancellation.send(true);
        }
    }
}

impl Drop for WalletRuntimeEventSubscription {
    fn drop(&mut self) {
        self.cancel_internal();
    }
}

fn next_frame(
    generation: u64,
    next_sequence: &mut u64,
    event: NativeWalletRuntimeEvent,
) -> Result<NativeWalletRuntimeEventFrame, NativeXelisError> {
    let sequence = *next_sequence;
    *next_sequence = next_sequence.checked_add(1).ok_or_else(|| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Internal,
            "WALLET_EVENT_SEQUENCE_EXHAUSTED",
            "Runtime event sequence exhausted u64",
        )
    })?;
    Ok(NativeWalletRuntimeEventFrame {
        version: NATIVE_WALLET_RUNTIME_EVENT_VERSION,
        generation,
        sequence,
        event,
    })
}

fn next_runtime_event_generation(current_generation: &mut u64) -> Result<u64, NativeXelisError> {
    let next_generation = current_generation.checked_add(1).ok_or_else(|| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Internal,
            "WALLET_EVENT_GENERATION_EXHAUSTED",
            "Runtime event subscription generation exhausted u64",
        )
    })?;
    *current_generation = next_generation;
    Ok(next_generation)
}

fn runtime_event_from_wallet_event(event: Event) -> Option<NativeWalletRuntimeEvent> {
    match event {
        Event::NewTopoHeight { topoheight } => {
            Some(NativeWalletRuntimeEvent::NewTopoHeight { topoheight })
        }
        Event::Rescan { start_topoheight } => {
            Some(NativeWalletRuntimeEvent::Rescan { start_topoheight })
        }
        Event::HistorySynced { topoheight } => {
            Some(NativeWalletRuntimeEvent::HistorySynced { topoheight })
        }
        Event::Online => Some(NativeWalletRuntimeEvent::Online),
        Event::Offline => Some(NativeWalletRuntimeEvent::Offline),
        Event::SyncError { message } => Some(NativeWalletRuntimeEvent::SyncIssue {
            failure: NativeXelisError::xelis_wallet(
                NativeXelisErrorCode::OperationFailed,
                "WALLET_SYNC_ERROR",
                message,
            ),
        }),
        Event::NewTransaction(_)
        | Event::NewPendingTransaction(_)
        | Event::BalanceChanged(_)
        | Event::NewAsset(_)
        | Event::TrackAsset { .. }
        | Event::UntrackAsset { .. } => None,
    }
}

impl XelisWallet {
    /// Opens a generation-scoped runtime event cursor after its upstream
    /// receiver has been registered.
    pub async fn subscribe_runtime_events(
        &self,
    ) -> Result<WalletRuntimeEventSubscription, NativeXelisError> {
        let receiver = self.wallet.subscribe_events().await;
        let generation = {
            let mut generation = self.runtime_event_generation.lock();
            next_runtime_event_generation(&mut *generation)?
        };

        Ok(WalletRuntimeEventSubscription::new(generation, receiver))
    }
}

#[cfg(test)]
mod tests;
