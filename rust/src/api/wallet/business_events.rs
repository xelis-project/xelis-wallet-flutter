use std::sync::atomic::{AtomicBool, Ordering};

use anyhow::Result as AnyhowResult;
use flutter_rust_bridge::frb;
use indexmap::IndexMap;
use xelis_common::{
    api::{
        wallet::{EntryType, TransactionEntry, TransactionPending, TransferIn, TransferOut},
        DataElement, ElementType, ValueType,
    },
    crypto::Hash,
    tokio::{
        select,
        sync::{
            broadcast::{error::RecvError, Receiver},
            watch, Mutex,
        },
    },
    transaction::extra_data::{PlaintextExtraData, PlaintextFlag},
};
use xelis_wallet::wallet::Event;

use super::{assets::asset_metadata, XelisWallet};
use crate::api::{
    error::{NativeXelisError, NativeXelisErrorCode},
    models::{
        address_dtos::NativeXelisDataElement,
        business_event_dtos::{
            NativeWalletAsset, NativeWalletAssetAmount, NativeWalletBusinessEvent,
            NativeWalletBusinessEventFrame, NativeWalletBusinessStreamCloseReason,
            NativeWalletContractTransferGroup, NativeWalletDeployInvoke, NativeWalletExtraData,
            NativeWalletExtraDataDisclosure, NativeWalletExtraDataFlag,
            NativeWalletExtraDataPayloadKind, NativeWalletPendingTransaction,
            NativeWalletTransactionEntry, NativeWalletTransactionEntryData, NativeWalletTransferIn,
            NativeWalletTransferOut, NATIVE_WALLET_BUSINESS_EVENT_VERSION,
        },
    },
};

struct WalletBusinessEventSubscriptionState {
    receiver: Receiver<Event>,
    cancellation: watch::Receiver<bool>,
    next_sequence: u64,
}

/// Pull-driven native cursor for session-scoped wallet business events.
#[frb(opaque)]
pub struct WalletBusinessEventSubscription {
    generation: u64,
    extra_data_projection: ExtraDataProjection,
    state: Mutex<WalletBusinessEventSubscriptionState>,
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

impl WalletBusinessEventSubscription {
    #[frb(ignore)]
    fn new(generation: u64, receiver: Receiver<Event>) -> Self {
        Self::new_with_projection(generation, receiver, ExtraDataProjection::Redacted)
    }

    #[frb(ignore)]
    fn new_with_projection(
        generation: u64,
        receiver: Receiver<Event>,
        extra_data_projection: ExtraDataProjection,
    ) -> Self {
        let (cancellation, cancellation_receiver) = watch::channel(false);
        Self {
            generation,
            extra_data_projection,
            state: Mutex::new(WalletBusinessEventSubscriptionState {
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

    /// Waits for the next business event, degradation marker, or termination.
    pub async fn next_event(
        &self,
    ) -> Result<Option<NativeWalletBusinessEventFrame>, NativeXelisError> {
        let _next_guard = self.begin_next()?;
        if self.cancelled.load(Ordering::Acquire) || self.terminated.load(Ordering::Acquire) {
            return Ok(None);
        }

        let mut state = self.state.lock().await;
        loop {
            if self.cancelled.load(Ordering::Acquire) {
                return Ok(None);
            }

            let WalletBusinessEventSubscriptionState {
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
                    if let Some(event) = business_event_from_wallet_event_with_projection(
                        event,
                        self.extra_data_projection,
                    )? {
                        return Ok(Some(next_frame(self.generation, next_sequence, event)?));
                    }
                }
                Err(RecvError::Lagged(skipped_events)) => {
                    let failure = NativeXelisError::xelis_wallet_flutter(
                        NativeXelisErrorCode::StreamLagged,
                        "WALLET_BUSINESS_EVENTS_LAGGED",
                        format!("Business event receiver skipped {skipped_events} upstream events"),
                    );
                    return Ok(Some(next_frame(
                        self.generation,
                        next_sequence,
                        NativeWalletBusinessEvent::Degraded {
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
                        NativeWalletBusinessEvent::Closed {
                            reason: NativeWalletBusinessStreamCloseReason::NativeChannelClosed,
                            failure: NativeXelisError::xelis_wallet_flutter(
                                NativeXelisErrorCode::StreamClosedUnexpectedly,
                                "WALLET_BUSINESS_EVENT_STREAM_CLOSED",
                                "Native wallet business event channel closed while the subscription was active",
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
                    "WALLET_BUSINESS_EVENT_NEXT_IN_PROGRESS",
                    "Only one business event read may be active per subscription",
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

impl Drop for WalletBusinessEventSubscription {
    fn drop(&mut self) {
        self.cancel_internal();
    }
}

fn next_frame(
    generation: u64,
    next_sequence: &mut u64,
    event: NativeWalletBusinessEvent,
) -> Result<NativeWalletBusinessEventFrame, NativeXelisError> {
    let sequence = *next_sequence;
    *next_sequence = next_sequence.checked_add(1).ok_or_else(|| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Internal,
            "WALLET_BUSINESS_EVENT_SEQUENCE_EXHAUSTED",
            "Business event sequence exhausted u64",
        )
    })?;
    Ok(NativeWalletBusinessEventFrame {
        version: NATIVE_WALLET_BUSINESS_EVENT_VERSION,
        generation,
        sequence,
        event,
    })
}

fn next_business_event_generation(current_generation: &mut u64) -> Result<u64, NativeXelisError> {
    let next_generation = current_generation.checked_add(1).ok_or_else(|| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::Internal,
            "WALLET_BUSINESS_EVENT_GENERATION_EXHAUSTED",
            "Business event subscription generation exhausted u64",
        )
    })?;
    *current_generation = next_generation;
    Ok(next_generation)
}

#[cfg(test)]
fn business_event_from_wallet_event(
    event: Event,
) -> Result<Option<NativeWalletBusinessEvent>, NativeXelisError> {
    business_event_from_wallet_event_with_projection(event, ExtraDataProjection::Redacted)
}

fn business_event_from_wallet_event_with_projection(
    event: Event,
    extra_data_projection: ExtraDataProjection,
) -> Result<Option<NativeWalletBusinessEvent>, NativeXelisError> {
    let event = match event {
        Event::NewTransaction(transaction) => Some(NativeWalletBusinessEvent::NewTransaction {
            transaction: transaction_entry(transaction, extra_data_projection)
                .map_err(business_event_projection_error)?,
        }),
        Event::NewPendingTransaction(transaction) => {
            Some(NativeWalletBusinessEvent::NewPendingTransaction {
                transaction: pending_transaction(transaction, extra_data_projection)
                    .map_err(business_event_projection_error)?,
            })
        }
        Event::BalanceChanged(balance) => Some(NativeWalletBusinessEvent::BalanceChanged {
            asset: balance.asset.to_hex(),
            balance: balance.balance,
        }),
        Event::NewAsset(asset) => Some(NativeWalletBusinessEvent::NewAsset {
            asset: NativeWalletAsset {
                asset_hash: asset.asset.to_hex(),
                topoheight: asset.topoheight,
                metadata: asset_metadata(&asset.inner),
            },
        }),
        Event::TrackAsset { asset } => Some(NativeWalletBusinessEvent::AssetTracked {
            asset: asset.to_hex(),
        }),
        Event::UntrackAsset { asset } => Some(NativeWalletBusinessEvent::AssetUntracked {
            asset: asset.to_hex(),
        }),
        Event::NewTopoHeight { .. }
        | Event::Rescan { .. }
        | Event::HistorySynced { .. }
        | Event::Online
        | Event::Offline
        | Event::SyncError { .. } => None,
    };
    Ok(event)
}

fn business_event_projection_error(error: anyhow::Error) -> NativeXelisError {
    NativeXelisError::from_wallet_operation(
        error,
        NativeXelisErrorCode::Serialization,
        "WALLET_BUSINESS_EVENT_PROJECTION_FAILED",
    )
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(super) enum ExtraDataProjection {
    Redacted,
    Metadata,
    Detailed,
}

impl ExtraDataProjection {
    pub(super) fn from_disclosure(disclosure: NativeWalletExtraDataDisclosure) -> Self {
        match disclosure {
            NativeWalletExtraDataDisclosure::Redacted => Self::Redacted,
            NativeWalletExtraDataDisclosure::Metadata => Self::Metadata,
            NativeWalletExtraDataDisclosure::Detailed => Self::Detailed,
        }
    }
}

pub(super) fn transaction_entry(
    value: TransactionEntry<'static>,
    extra_data_projection: ExtraDataProjection,
) -> AnyhowResult<NativeWalletTransactionEntry> {
    Ok(NativeWalletTransactionEntry {
        hash: value.hash.to_hex(),
        topoheight: value.topoheight,
        timestamp_millis: value.timestamp,
        entry: transaction_entry_data(value.entry, extra_data_projection)?,
    })
}

pub(super) fn pending_transaction(
    value: TransactionPending<'static>,
    extra_data_projection: ExtraDataProjection,
) -> AnyhowResult<NativeWalletPendingTransaction> {
    Ok(NativeWalletPendingTransaction {
        hash: value.hash.to_hex(),
        timestamp_millis: value.timestamp,
        entry: transaction_entry_data(value.entry, extra_data_projection)?,
    })
}

fn transaction_entry_data(
    value: EntryType<'static>,
    extra_data_projection: ExtraDataProjection,
) -> AnyhowResult<NativeWalletTransactionEntryData> {
    Ok(match value {
        EntryType::Coinbase { reward } => NativeWalletTransactionEntryData::Coinbase { reward },
        EntryType::Burn {
            asset,
            amount,
            fee,
            nonce,
        } => NativeWalletTransactionEntryData::Burn {
            asset: asset.to_hex(),
            amount,
            fee,
            nonce,
        },
        EntryType::Incoming { from, transfers } => NativeWalletTransactionEntryData::Incoming {
            from: from.to_string(),
            transfers: transfers
                .into_iter()
                .map(|value| transfer_in(value, extra_data_projection))
                .collect::<AnyhowResult<Vec<_>>>()?,
        },
        EntryType::Outgoing {
            transfers,
            fee,
            nonce,
        } => NativeWalletTransactionEntryData::Outgoing {
            transfers: transfers
                .into_iter()
                .map(|value| transfer_out(value, extra_data_projection))
                .collect::<AnyhowResult<Vec<_>>>()?,
            fee,
            nonce,
        },
        EntryType::MultiSig {
            participants,
            threshold,
            fee,
            nonce,
        } => NativeWalletTransactionEntryData::Multisig {
            participants: participants.iter().map(ToString::to_string).collect(),
            threshold,
            fee,
            nonce,
        },
        EntryType::InvokeContract {
            contract,
            deposits,
            received,
            chunk_id,
            fee,
            max_gas,
            nonce,
        } => NativeWalletTransactionEntryData::InvokeContract {
            contract: contract.to_hex(),
            deposits: asset_amounts(&deposits),
            received: contract_transfer_groups(&received),
            chunk_id,
            fee,
            max_gas,
            nonce,
        },
        EntryType::DeployContract { fee, nonce, invoke } => {
            NativeWalletTransactionEntryData::DeployContract {
                fee,
                nonce,
                invoke: invoke.map(|invoke| NativeWalletDeployInvoke {
                    max_gas: invoke.max_gas,
                    deposits: asset_amounts(&invoke.deposits),
                }),
            }
        }
        EntryType::IncomingContract { transfers } => {
            NativeWalletTransactionEntryData::IncomingContract {
                transfers: contract_transfer_groups(&transfers),
            }
        }
        EntryType::OutgoingBlob {
            destinations,
            fee,
            nonce,
            data,
        } => NativeWalletTransactionEntryData::OutgoingBlob {
            destinations: destinations.iter().map(ToString::to_string).collect(),
            fee,
            nonce,
            data: extra_data(&data, extra_data_projection)?,
        },
        EntryType::IncomingBlob {
            from,
            destinations,
            data,
        } => NativeWalletTransactionEntryData::IncomingBlob {
            from: from.to_string(),
            destinations: destinations.iter().map(ToString::to_string).collect(),
            data: extra_data(&data, extra_data_projection)?,
        },
    })
}

fn transfer_in(
    value: TransferIn<'static>,
    extra_data_projection: ExtraDataProjection,
) -> AnyhowResult<NativeWalletTransferIn> {
    Ok(NativeWalletTransferIn {
        asset: value.asset.to_hex(),
        amount: value.amount,
        extra_data: value
            .extra_data
            .as_ref()
            .as_ref()
            .map(|value| extra_data(value, extra_data_projection))
            .transpose()?,
    })
}

fn transfer_out(
    value: TransferOut<'static>,
    extra_data_projection: ExtraDataProjection,
) -> AnyhowResult<NativeWalletTransferOut> {
    Ok(NativeWalletTransferOut {
        destination: value.destination.to_string(),
        asset: value.asset.to_hex(),
        amount: value.amount,
        extra_data: value
            .extra_data
            .as_ref()
            .as_ref()
            .map(|value| extra_data(value, extra_data_projection))
            .transpose()?,
    })
}

fn extra_data(
    value: &PlaintextExtraData,
    projection: ExtraDataProjection,
) -> AnyhowResult<NativeWalletExtraData> {
    let (payload, payload_kind) = match (projection, value.data()) {
        (ExtraDataProjection::Redacted, _) | (_, None) => (None, None),
        (ExtraDataProjection::Metadata, Some(payload)) => {
            (None, Some(extra_data_payload_kind(payload)))
        }
        (ExtraDataProjection::Detailed, Some(payload)) => (
            Some(NativeXelisDataElement::from_xelis(payload.clone())),
            Some(extra_data_payload_kind(payload)),
        ),
    };

    Ok(NativeWalletExtraData {
        flag: match value.flag() {
            PlaintextFlag::Private => NativeWalletExtraDataFlag::Private,
            PlaintextFlag::Public => NativeWalletExtraDataFlag::Public,
            PlaintextFlag::Proprietary => NativeWalletExtraDataFlag::Proprietary,
            PlaintextFlag::Failed => NativeWalletExtraDataFlag::Failed,
        },
        has_payload: value.data().is_some(),
        payload,
        payload_kind,
    })
}

fn extra_data_payload_kind(payload: &DataElement) -> NativeWalletExtraDataPayloadKind {
    match payload.kind() {
        ElementType::Value(ValueType::Bool) => NativeWalletExtraDataPayloadKind::BoolValue,
        ElementType::Value(ValueType::String) => NativeWalletExtraDataPayloadKind::String,
        ElementType::Value(ValueType::U8) => NativeWalletExtraDataPayloadKind::U8,
        ElementType::Value(ValueType::U16) => NativeWalletExtraDataPayloadKind::U16,
        ElementType::Value(ValueType::U32) => NativeWalletExtraDataPayloadKind::U32,
        ElementType::Value(ValueType::U64) => NativeWalletExtraDataPayloadKind::U64,
        ElementType::Value(ValueType::U128) => NativeWalletExtraDataPayloadKind::U128,
        ElementType::Value(ValueType::Hash) => NativeWalletExtraDataPayloadKind::Hash,
        ElementType::Value(ValueType::Blob) => NativeWalletExtraDataPayloadKind::Blob,
        ElementType::Array => NativeWalletExtraDataPayloadKind::Array,
        ElementType::Fields => NativeWalletExtraDataPayloadKind::Fields,
    }
}

fn asset_amounts(values: &IndexMap<Hash, u64>) -> Vec<NativeWalletAssetAmount> {
    values
        .iter()
        .map(|(asset, amount)| NativeWalletAssetAmount {
            asset: asset.to_hex(),
            amount: *amount,
        })
        .collect()
}

fn contract_transfer_groups(
    values: &IndexMap<Hash, IndexMap<Hash, u64>>,
) -> Vec<NativeWalletContractTransferGroup> {
    values
        .iter()
        .map(|(contract, transfers)| NativeWalletContractTransferGroup {
            contract: contract.to_hex(),
            transfers: asset_amounts(transfers),
        })
        .collect()
}

impl XelisWallet {
    /// Opens a session-scoped business-event cursor.
    pub async fn subscribe_business_events(
        &self,
        extra_data_disclosure: NativeWalletExtraDataDisclosure,
    ) -> Result<WalletBusinessEventSubscription, NativeXelisError> {
        let receiver = self.wallet.subscribe_events().await;
        let generation = {
            let mut generation = self.business_event_generation.lock();
            next_business_event_generation(&mut *generation)?
        };

        let extra_data_projection = ExtraDataProjection::from_disclosure(extra_data_disclosure);
        Ok(WalletBusinessEventSubscription::new_with_projection(
            generation,
            receiver,
            extra_data_projection,
        ))
    }
}

#[cfg(test)]
mod tests;
