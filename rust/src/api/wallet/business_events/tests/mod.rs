use std::borrow::Cow;

use futures::executor::block_on;
use indexmap::{IndexMap, IndexSet};
use xelis_common::{
    api::{
        wallet::{
            BalanceChanged, DeployInvoke, EntryType, TransactionEntry, TransactionPending,
            TransferIn, TransferOut,
        },
        DataElement, DataValue,
    },
    asset::{AssetData, AssetOwner, MaxSupplyMode, RPCAssetData},
    crypto::{Hash, KeyPair},
    tokio::sync::broadcast,
    transaction::extra_data::{PlaintextExtraData, PlaintextFlag, SharedKey},
};
use xelis_wallet::wallet::Event;

use super::{
    business_event_from_wallet_event, extra_data, extra_data_payload_kind,
    next_business_event_generation, transaction_entry_data, ExtraDataProjection,
    NativeWalletBusinessEvent, NativeWalletBusinessStreamCloseReason,
    WalletBusinessEventSubscription,
};
use crate::api::{
    error::NativeXelisErrorCode,
    models::{
        business_event_dtos::{
            NativeWalletBusinessEventFrame, NativeWalletExtraDataFlag,
            NativeWalletExtraDataPayloadKind, NativeWalletTransactionEntryData,
        },
        wallet_dtos::{XelisAssetOwner, XelisMaxSupplyMode},
    },
};

fn next(subscription: &WalletBusinessEventSubscription) -> Option<NativeWalletBusinessEventFrame> {
    block_on(subscription.next_event()).unwrap()
}

mod disclosure;
mod mapping;
mod subscription;
