use super::super::error::NativeXelisError;

/// Version of the package-owned runtime-event contract.
pub const NATIVE_WALLET_RUNTIME_EVENT_VERSION: u16 = 1;

/// One ordered event read from a generation-scoped wallet subscription.
#[derive(Clone, Debug)]
pub struct NativeWalletRuntimeEventFrame {
    pub version: u16,
    pub generation: u64,
    pub sequence: u64,
    pub event: NativeWalletRuntimeEvent,
}

/// Runtime and synchronization events that are safe to consume independently
/// from the transaction and asset DTO contracts.
#[derive(Clone, Debug)]
pub enum NativeWalletRuntimeEvent {
    Online,
    Offline,
    SyncIssue {
        failure: NativeXelisError,
    },
    NewTopoHeight {
        topoheight: u64,
    },
    Rescan {
        start_topoheight: u64,
    },
    HistorySynced {
        topoheight: u64,
    },
    Degraded {
        skipped_events: u64,
        failure: NativeXelisError,
    },
    Closed {
        reason: NativeWalletRuntimeStreamCloseReason,
        failure: NativeXelisError,
    },
}

/// Stable reason reported when the native upstream channel terminates.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeWalletRuntimeStreamCloseReason {
    NativeChannelClosed,
}
