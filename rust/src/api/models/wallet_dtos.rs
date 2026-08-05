use std::{borrow::Cow, fmt};

use anyhow::{ensure, Context, Result};
use flutter_rust_bridge::frb;

use serde::{Deserialize, Serialize};
use xelis_common::asset::{AssetOwner, MaxSupplyMode};
use xelis_common::crypto::{Hash, PublicKey};
use xelis_common::serializer::Serializer;
pub use xelis_common::transaction::builder::TransactionTypeBuilder;
pub use xelis_common::{api::DataElement, crypto::Address};
use xelis_wallet::storage::TransactionFilterOptions;

use crate::api::{error::NativeXelisError, models::address_dtos::NativeXelisDataElement};

#[frb]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum BroadcastTransactionOutcome {
    Submitted,
    Retryable,
    Rejected,
    LocalFailure,
    SubmittedNeedsResync,
}

/// Exact fee policy used by the stable prepared-transaction API.
///
/// `10_000` basis points represents the automatically estimated fee (1x).
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeTransactionFeePolicy {
    pub basis_points: u32,
}

#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeTransactionTransferRequest {
    pub amount: u64,
    pub destination: String,
    pub asset: String,
    pub extra_data: Option<String>,
    pub encrypt_extra_data: bool,
}

/// Safe projection of a prepared transfer. The extra-data payload is
/// intentionally never returned across the public bridge.
#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativePreparedTransfer {
    pub amount: u64,
    pub destination: String,
    pub asset: String,
    pub has_extra_data: bool,
    pub encrypt_extra_data: bool,
}

/// Origin of the effective extra data retained for explicit prepared review.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativePreparedExtraDataSource {
    IntegratedAddress,
    Explicit,
}

/// Capability-bound detail for one prepared transfer's effective extra data.
///
/// This value is never embedded in the standard prepared projection. It is
/// returned only after the caller proves ownership of the exact native
/// preparation generation and transaction hash.
#[derive(Clone, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativePreparedTransferExtraData {
    pub data: NativeXelisDataElement,
    pub source: NativePreparedExtraDataSource,
    pub encrypted: bool,
}

impl fmt::Debug for NativePreparedTransferExtraData {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativePreparedTransferExtraData")
            .field("data", &"<redacted>")
            .field("source", &self.source)
            .field("encrypted", &self.encrypted)
            .finish()
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub enum NativePreparedTransactionKind {
    Transfers {
        transfers: Vec<NativePreparedTransfer>,
    },
    Burn {
        asset: String,
        amount: u64,
    },
    MultisigSetup {
        threshold: u8,
        participants: Vec<NativeMultisigParticipant>,
    },
    MultisigFinalized {
        transaction: NativeMultisigSigningTransaction,
    },
}

/// Opaque capability describing the exact transaction currently stored in the
/// native prepared slot.
#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativePreparedTransaction {
    pub hash: String,
    pub preparation_id: u64,
    pub fee: u64,
    pub transaction: NativePreparedTransactionKind,
}

#[frb]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum NativePreparedTransactionBroadcastOutcome {
    Submitted,
    Retryable { failure: NativeXelisError },
    Rejected { failure: NativeXelisError },
    LocalFailure { failure: NativeXelisError },
    SubmittedNeedsResync { failure: NativeXelisError },
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct SummaryTransaction {
    pub hash: String,
    pub fee: u64,
    pub transaction_type: TransactionTypeBuilder,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct Transfer {
    pub float_amount: f64,
    pub str_address: String,
    pub asset_hash: String,
    pub extra_data: Option<String>,
    pub encrypt_extra_data: Option<bool>,
}

#[derive(Serialize, Deserialize, Clone, Debug, Eq, PartialEq)]
#[serde(rename_all = "snake_case")]
#[frb(dart_metadata=("freezed"))]
pub enum NativeMultisigSigningTransaction {
    Transfers {
        transfers: Vec<NativeMultisigSigningTransfer>,
    },
    Burn {
        asset: String,
        amount: u64,
    },
    DeleteMultisig,
}

#[derive(Serialize, Deserialize, Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeMultisigSigningTransfer {
    pub amount: u64,
    pub asset: String,
    pub destination: String,
    pub has_extra_data: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeMultisigSigningRequest {
    /// Native generation of a source-wallet request retained for finalization.
    /// Participant-side inspected requests do not own a pending source slot.
    pub request_id: Option<u64>,
    /// Canonical request envelope to share with each participant.
    pub encoded: String,
    /// Hash recomputed from the canonical unsigned transaction and signed by participants.
    pub signing_hash: String,
    pub source: String,
    pub network: String,
    pub fee: u64,
    pub fee_limit: u64,
    pub nonce: u64,
    pub reference_topoheight: u64,
    pub threshold: u8,
    pub participants: Vec<NativeMultisigParticipant>,
    /// Present when the currently opened wallet is an authorized signer.
    pub signer_id: Option<u8>,
    pub transaction: NativeMultisigSigningTransaction,
}

#[derive(Serialize, Deserialize, Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeMultisigSignatureShare {
    /// Canonical signature envelope to return to the request creator.
    pub encoded: String,
    /// Hash of the canonical unsigned transaction that the participant signed.
    pub signing_hash: String,
    pub signer_id: u8,
    pub signature: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeMultisigState {
    pub threshold: u8,
    pub participants: Vec<NativeMultisigParticipant>,
    pub topoheight: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeMultisigParticipant {
    pub id: u8,
    pub address: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct IntegratedAddress {
    pub address: Address,
    pub data: Option<DataElement>,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct HistoryPageFilter {
    pub page: usize,
    pub limit: Option<usize>,
    pub asset_hash: Option<String>,
    pub address: Option<String>,
    pub min_topoheight: Option<u64>,
    pub max_topoheight: Option<u64>,
    pub accept_incoming: bool,
    pub accept_outgoing: bool,
    pub accept_coinbase: bool,
    pub accept_burn: bool,
    pub accept_blob: bool,
    pub min_timestamp: Option<u64>,
    pub max_timestamp: Option<u64>,
}

/// Native-only exact destination retained after parsing an integrated address.
///
/// Deliberately has no `Debug` implementation: integrated data may be useful
/// in an explicit local diagnostic, but it must not leak through routine
/// bridge diagnostics or filter formatting.
pub(crate) struct ExactIntegratedHistoryDestination {
    public_key: PublicKey,
    serialized_data: Vec<u8>,
}

impl ExactIntegratedHistoryDestination {
    pub(crate) fn matches(&self, public_key: &PublicKey, data: Option<&DataElement>) -> bool {
        public_key == &self.public_key
            && data.is_some_and(|data| data.to_bytes() == self.serialized_data)
    }

    pub(crate) fn matches_wallet(&self, wallet_public_key: &PublicKey) -> bool {
        wallet_public_key == &self.public_key
    }
}

pub(crate) struct PreparedHistoryFilter<'a> {
    pub(crate) options: TransactionFilterOptions<'a>,
    pub(crate) exact_integrated_destination: Option<ExactIntegratedHistoryDestination>,
}

impl HistoryPageFilter {
    pub fn options<'a>(&'a self) -> Result<TransactionFilterOptions<'a>> {
        Ok(self.prepare()?.options)
    }

    pub(crate) fn prepare<'a>(&'a self) -> Result<PreparedHistoryFilter<'a>> {
        ensure!(self.page > 0, "Page must be at least 1");
        if let Some(limit) = self.limit {
            ensure!(limit > 0, "Limit cannot be 0");
        }

        let (address, exact_integrated_destination) = match self.address.as_ref() {
            Some(address) => {
                let address = Address::from_string(&address).context("Invalid address")?;
                let (integrated_data, base_address) = address.extract_data();
                let public_key = base_address.to_public_key();

                match integrated_data {
                    Some(data) => (
                        None,
                        Some(ExactIntegratedHistoryDestination {
                            public_key,
                            serialized_data: data.to_bytes(),
                        }),
                    ),
                    None => (Some(Cow::Owned(public_key)), None),
                }
            }
            None => (None, None),
        };

        let asset = match self.asset_hash.as_ref() {
            Some(asset_hash) => Some(Cow::Owned(
                Hash::from_hex(&asset_hash).context("Invalid asset")?,
            )),
            None => None,
        };

        Ok(PreparedHistoryFilter {
            options: TransactionFilterOptions {
                address,
                asset,
                contract: None, // TODO: Add contract filter to the API
                min_topoheight: self.min_topoheight,
                // The locked upstream storage computes `max_topoheight + 1`
                // without a checked addition. `u64::MAX` is equivalent to no
                // upper bound, so normalize it before crossing that boundary.
                max_topoheight: self.max_topoheight.filter(|max| *max != u64::MAX),
                accept_incoming: self.accept_incoming,
                accept_outgoing: self.accept_outgoing,
                accept_coinbase: match self.address {
                    Some(_) => false,
                    None => self.accept_coinbase,
                },
                accept_blob: self.accept_blob
                    && self.address.is_none()
                    && self.asset_hash.is_none(),
                accept_burn: match self.address {
                    Some(_) => false,
                    None => self.accept_burn,
                },
                min_timestamp: self.min_timestamp,
                max_timestamp: self.max_timestamp,
                skip: match self.limit {
                    Some(limit) => Some(
                        self.page
                            .checked_sub(1)
                            .and_then(|page| page.checked_mul(limit))
                            .context("Pagination offset is too large")?,
                    ),
                    None => None,
                },
                limit: self.limit,
                query: None,
            },
            exact_integrated_destination,
        })
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
#[frb(dart_metadata=("freezed"))]
pub enum XelisMaxSupplyMode {
    None,
    Fixed(u64),
    Mintable(u64),
}

impl From<MaxSupplyMode> for XelisMaxSupplyMode {
    fn from(value: MaxSupplyMode) -> Self {
        match value {
            MaxSupplyMode::None => Self::None,
            MaxSupplyMode::Fixed(max_supply) => Self::Fixed(max_supply),
            MaxSupplyMode::Mintable(max_supply) => Self::Mintable(max_supply),
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
#[frb(dart_metadata=("freezed"))]
pub enum XelisAssetOwner {
    None,
    Creator {
        contract: String,
        id: u64,
    },
    Owner {
        origin: String,
        origin_id: u64,
        owner: String,
    },
}

impl From<&AssetOwner> for XelisAssetOwner {
    fn from(value: &AssetOwner) -> Self {
        match value {
            AssetOwner::None => Self::None,
            AssetOwner::Creator { contract, id } => Self::Creator {
                contract: contract.to_hex(),
                id: *id,
            },
            AssetOwner::Owner {
                origin,
                origin_id,
                owner,
            } => Self::Owner {
                origin: origin.to_hex(),
                origin_id: *origin_id,
                owner: owner.to_hex(),
            },
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct XelisAssetMetadata {
    pub name: String,
    pub ticker: String,
    pub decimals: u8,
    pub max_supply: XelisMaxSupplyMode,
    pub owner: XelisAssetOwner,
}
