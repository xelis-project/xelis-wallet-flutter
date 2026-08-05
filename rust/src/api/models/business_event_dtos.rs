use super::{
    super::error::NativeXelisError, address_dtos::NativeXelisDataElement,
    wallet_dtos::XelisAssetMetadata,
};

/// Version of the package-owned business-event contract.
pub const NATIVE_WALLET_BUSINESS_EVENT_VERSION: u16 = 1;

/// One ordered event read from a session-scoped wallet subscription.
#[derive(Clone, Debug)]
pub struct NativeWalletBusinessEventFrame {
    pub version: u16,
    pub generation: u64,
    pub sequence: u64,
    pub event: NativeWalletBusinessEvent,
}

/// Transaction, balance, and asset events owned by the stable package API.
#[derive(Clone, Debug)]
pub enum NativeWalletBusinessEvent {
    NewTransaction {
        transaction: NativeWalletTransactionEntry,
    },
    NewPendingTransaction {
        transaction: NativeWalletPendingTransaction,
    },
    BalanceChanged {
        asset: String,
        balance: u64,
    },
    NewAsset {
        asset: NativeWalletAsset,
    },
    AssetTracked {
        asset: String,
    },
    AssetUntracked {
        asset: String,
    },
    Degraded {
        skipped_events: u64,
        failure: NativeXelisError,
    },
    Closed {
        reason: NativeWalletBusinessStreamCloseReason,
        failure: NativeXelisError,
    },
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeWalletBusinessStreamCloseReason {
    NativeChannelClosed,
}

#[derive(Clone, Debug)]
pub struct NativeWalletTransactionEntry {
    pub hash: String,
    pub topoheight: u64,
    pub timestamp_millis: u64,
    pub entry: NativeWalletTransactionEntryData,
}

#[derive(Clone, Debug)]
pub struct NativeWalletPendingTransaction {
    pub hash: String,
    pub timestamp_millis: u64,
    pub entry: NativeWalletTransactionEntryData,
}

#[derive(Clone, Debug)]
pub enum NativeWalletTransactionEntryData {
    Coinbase {
        reward: u64,
    },
    Burn {
        asset: String,
        amount: u64,
        fee: u64,
        nonce: u64,
    },
    Incoming {
        from: String,
        transfers: Vec<NativeWalletTransferIn>,
    },
    Outgoing {
        transfers: Vec<NativeWalletTransferOut>,
        fee: u64,
        nonce: u64,
    },
    Multisig {
        participants: Vec<String>,
        threshold: u8,
        fee: u64,
        nonce: u64,
    },
    InvokeContract {
        contract: String,
        deposits: Vec<NativeWalletAssetAmount>,
        received: Vec<NativeWalletContractTransferGroup>,
        chunk_id: u16,
        fee: u64,
        max_gas: u64,
        nonce: u64,
    },
    DeployContract {
        fee: u64,
        nonce: u64,
        invoke: Option<NativeWalletDeployInvoke>,
    },
    IncomingContract {
        transfers: Vec<NativeWalletContractTransferGroup>,
    },
    OutgoingBlob {
        destinations: Vec<String>,
        fee: u64,
        nonce: u64,
        data: NativeWalletExtraData,
    },
    IncomingBlob {
        from: String,
        destinations: Vec<String>,
        data: NativeWalletExtraData,
    },
}

#[derive(Clone, Debug)]
pub struct NativeWalletTransferIn {
    pub asset: String,
    pub amount: u64,
    pub extra_data: Option<NativeWalletExtraData>,
}

#[derive(Clone, Debug)]
pub struct NativeWalletTransferOut {
    pub destination: String,
    pub asset: String,
    pub amount: u64,
    pub extra_data: Option<NativeWalletExtraData>,
}

/// Package-owned projection of decrypted transaction extra data.
///
/// [payload] and [payload_kind] are populated according to the explicit read
/// disclosure. Passive business events always set them to `None`. [payload] is
/// the lossless tagged representation. The upstream shared encryption key never
/// crosses the bridge.
#[derive(Clone, Debug)]
pub struct NativeWalletExtraData {
    pub flag: NativeWalletExtraDataFlag,
    pub has_payload: bool,
    pub payload: Option<NativeXelisDataElement>,
    pub payload_kind: Option<NativeWalletExtraDataPayloadKind>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeWalletExtraDataFlag {
    Private,
    Public,
    Proprietary,
    Failed,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeWalletExtraDataPayloadKind {
    BoolValue,
    String,
    U8,
    U16,
    U32,
    U64,
    U128,
    Hash,
    Blob,
    Array,
    Fields,
    Unknown,
}

#[derive(Clone, Debug)]
pub struct NativeWalletAssetAmount {
    pub asset: String,
    pub amount: u64,
}

#[derive(Clone, Debug)]
pub struct NativeWalletContractTransferGroup {
    pub contract: String,
    pub transfers: Vec<NativeWalletAssetAmount>,
}

#[derive(Clone, Debug)]
pub struct NativeWalletDeployInvoke {
    pub max_gas: u64,
    pub deposits: Vec<NativeWalletAssetAmount>,
}

#[derive(Clone, Debug)]
pub struct NativeWalletAsset {
    pub asset_hash: String,
    pub topoheight: u64,
    pub metadata: XelisAssetMetadata,
}
