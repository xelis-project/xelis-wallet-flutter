use std::future::Future;

use anyhow::{Context, Result};
use serde_json::json;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Address, Hash};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{TransactionTypeBuilder, TransferBuilder};
use xelis_common::transaction::BurnPayload;

use crate::api::error::{NativeXelisError, NativeXelisErrorCode};
use crate::api::models::address_dtos::NativeXelisDataElement;
use crate::api::models::wallet_dtos::{
    NativePreparedExtraDataSource, NativePreparedTransactionKind, NativePreparedTransfer,
    NativePreparedTransferExtraData, NativeTransactionFeePolicy, NativeTransactionTransferRequest,
    SummaryTransaction, Transfer,
};

use super::super::{amounts, XelisWallet};

const FEE_BASIS_POINTS_SCALE: u128 = 10_000;
const MAX_FEE_BASIS_POINTS: u32 = 100_000;

fn invalid_transaction_input(
    native_kind: &'static str,
    diagnostic_message: impl Into<String>,
) -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        NativeXelisErrorCode::InvalidInput,
        native_kind,
        diagnostic_message,
    )
}

pub(in crate::api::wallet) fn apply_fee_policy(
    base_fee: u64,
    policy: NativeTransactionFeePolicy,
) -> std::result::Result<u64, NativeXelisError> {
    if u128::from(policy.basis_points) < FEE_BASIS_POINTS_SCALE
        || policy.basis_points > MAX_FEE_BASIS_POINTS
    {
        return Err(invalid_transaction_input(
            "TRANSACTION_FEE_POLICY_INVALID",
            "Fee basis points must be between 10000 and 100000",
        ));
    }

    let numerator = u128::from(base_fee)
        .checked_mul(u128::from(policy.basis_points))
        .and_then(|value| value.checked_add(FEE_BASIS_POINTS_SCALE - 1))
        .ok_or_else(|| {
            invalid_transaction_input(
                "TRANSACTION_FEE_OVERFLOW",
                "Adjusted transaction fee exceeds the supported range",
            )
        })?;
    let adjusted = numerator / FEE_BASIS_POINTS_SCALE;

    u64::try_from(adjusted).map_err(|_| {
        invalid_transaction_input(
            "TRANSACTION_FEE_OVERFLOW",
            "Adjusted transaction fee exceeds the supported range",
        )
    })
}

pub(in crate::api::wallet) fn parse_transaction_asset(
    asset: &str,
) -> std::result::Result<Hash, NativeXelisError> {
    Hash::from_hex(asset).map_err(|_| {
        invalid_transaction_input(
            "TRANSACTION_ASSET_INVALID",
            "Transaction asset is not a valid hash",
        )
    })
}

pub(in crate::api::wallet) fn parse_transaction_destination(
    destination: &str,
) -> std::result::Result<Address, NativeXelisError> {
    Address::from_string(destination).map_err(|_| {
        invalid_transaction_input(
            "TRANSACTION_DESTINATION_INVALID",
            "Transaction destination is not a valid address",
        )
    })
}

pub(super) fn project_prepared_transfer(
    destination: &Address,
    asset: &Hash,
    amount: u64,
    explicit_extra_data: Option<&str>,
    encrypt_extra_data: bool,
) -> std::result::Result<
    (
        NativePreparedTransfer,
        Option<NativePreparedTransferExtraData>,
    ),
    NativeXelisError,
> {
    let (integrated_extra_data, public_destination) = destination.clone().extract_data();

    if explicit_extra_data.is_some() && integrated_extra_data.is_some() {
        return Err(invalid_transaction_input(
            "TRANSACTION_EXTRA_DATA_CONFLICT",
            "Explicit extra data cannot be combined with an integrated address",
        ));
    }

    let effective_extra_data = explicit_extra_data
        .map(|value| {
            (
                DataElement::Value(DataValue::String(value.to_owned())),
                NativePreparedExtraDataSource::Explicit,
            )
        })
        .or_else(|| {
            integrated_extra_data
                .map(|value| (value, NativePreparedExtraDataSource::IntegratedAddress))
        })
        .map(|(data, source)| NativePreparedTransferExtraData {
            data: NativeXelisDataElement::from_xelis(data),
            source,
            encrypted: encrypt_extra_data,
        });

    Ok((
        NativePreparedTransfer {
            amount,
            destination: public_destination.to_string(),
            asset: asset.to_hex(),
            has_extra_data: effective_extra_data.is_some(),
            encrypt_extra_data,
        },
        effective_extra_data,
    ))
}

pub(in crate::api::wallet) fn build_atomic_transfers(
    transfers: Vec<NativeTransactionTransferRequest>,
) -> std::result::Result<
    (
        TransactionTypeBuilder,
        NativePreparedTransactionKind,
        Vec<Option<NativePreparedTransferExtraData>>,
    ),
    NativeXelisError,
> {
    if transfers.is_empty() {
        return Err(invalid_transaction_input(
            "TRANSACTION_TRANSFERS_EMPTY",
            "At least one transfer is required",
        ));
    }

    let mut builders = Vec::with_capacity(transfers.len());
    let mut projection = Vec::with_capacity(transfers.len());
    let mut review_extra_data = Vec::with_capacity(transfers.len());
    for (index, transfer) in transfers.into_iter().enumerate() {
        if transfer.amount == 0 {
            return Err(invalid_transaction_input(
                "TRANSACTION_AMOUNT_INVALID",
                format!("Transfer amount at index {index} must be greater than zero"),
            ));
        }

        let asset = parse_transaction_asset(&transfer.asset)?;
        let destination = parse_transaction_destination(&transfer.destination)?;
        let (prepared_transfer, prepared_extra_data) = project_prepared_transfer(
            &destination,
            &asset,
            transfer.amount,
            transfer.extra_data.as_deref(),
            transfer.encrypt_extra_data,
        )?;
        projection.push(prepared_transfer);
        review_extra_data.push(prepared_extra_data);
        builders.push(build_transfer(
            destination,
            transfer.amount,
            asset,
            transfer.extra_data,
            Some(transfer.encrypt_extra_data),
        ));
    }

    Ok((
        TransactionTypeBuilder::Transfers(builders),
        NativePreparedTransactionKind::Transfers {
            transfers: projection,
        },
        review_extra_data,
    ))
}

pub(super) fn encrypt_extra_data_or_default(value: Option<bool>) -> bool {
    value.unwrap_or(true)
}

pub(in crate::api::wallet) fn amount_after_fee(
    amount: u64,
    fee: u64,
    asset: &Hash,
    insufficient_funds_context: &'static str,
) -> Result<u64> {
    let amount = if asset == &XELIS_ASSET {
        amount
            .checked_sub(fee)
            .context(insufficient_funds_context)?
    } else {
        amount
    };

    (amount > 0)
        .then_some(amount)
        .context(insufficient_funds_context)
}

pub(in crate::api::wallet) fn build_transfer(
    destination: Address,
    amount: u64,
    asset: Hash,
    extra_data: Option<String>,
    encrypt_extra_data: Option<bool>,
) -> TransferBuilder {
    TransferBuilder {
        destination,
        amount,
        asset,
        extra_data: extra_data.map(|value| DataElement::Value(DataValue::String(value))),
        encrypt_extra_data: encrypt_extra_data_or_default(encrypt_extra_data),
    }
}

pub(super) fn build_transfer_from_input(
    transfer: Transfer,
    asset: Hash,
    decimals: u8,
) -> Result<TransferBuilder> {
    let amount = amounts::checked_atomic_amount(transfer.float_amount, decimals)
        .context("Error while converting amount to atomic format")?;
    let destination = Address::from_string(&transfer.str_address).context("Invalid address")?;

    Ok(build_transfer(
        destination,
        amount,
        asset,
        transfer.extra_data,
        transfer.encrypt_extra_data,
    ))
}

pub(in crate::api::wallet) fn build_transfer_all_type(
    destination: Address,
    balance: u64,
    fee: u64,
    asset: Hash,
    extra_data: Option<String>,
    encrypt_extra_data: Option<bool>,
) -> Result<TransactionTypeBuilder> {
    let amount = amount_after_fee(balance, fee, &asset, "Insufficient balance for fees")?;
    let transfer = build_transfer(destination, amount, asset, extra_data, encrypt_extra_data);

    Ok(TransactionTypeBuilder::Transfers(vec![transfer]))
}

pub(in crate::api::wallet) fn build_burn_type(asset: Hash, amount: u64) -> TransactionTypeBuilder {
    TransactionTypeBuilder::Burn(BurnPayload { amount, asset })
}

pub(in crate::api::wallet) fn build_burn_all_type(
    asset: Hash,
    balance: u64,
    fee: u64,
) -> Result<TransactionTypeBuilder> {
    let amount = amount_after_fee(
        balance,
        fee,
        &asset,
        "Insufficient balance to pay burn transaction fees",
    )?;

    Ok(build_burn_type(asset, amount))
}

pub(super) fn transaction_summary_json(
    hash: &Hash,
    fee: u64,
    transaction_type: TransactionTypeBuilder,
) -> String {
    json!(SummaryTransaction {
        hash: hash.to_hex(),
        fee,
        transaction_type,
    })
    .to_string()
}

pub(in crate::api::wallet) async fn create_transfers(
    wallet: &XelisWallet,
    transfers: Vec<Transfer>,
) -> Result<TransactionTypeBuilder> {
    create_transfers_with_decimals(transfers, |asset| async move {
        let storage = wallet.wallet.get_storage().read().await;
        Ok(storage.get_asset(&asset).await?.get_decimals())
    })
    .await
}

pub(super) async fn create_transfers_with_decimals<LoadDecimals, LoadDecimalsFuture>(
    transfers: Vec<Transfer>,
    mut load_decimals: LoadDecimals,
) -> Result<TransactionTypeBuilder>
where
    LoadDecimals: FnMut(Hash) -> LoadDecimalsFuture,
    LoadDecimalsFuture: Future<Output = Result<u8>>,
{
    let mut builders = Vec::new();

    for transfer in transfers {
        let asset = Hash::from_hex(&transfer.asset_hash).context("Invalid asset")?;
        let decimals = load_decimals(asset.clone())
            .await
            .context("Error while converting amount to atomic format")?;
        let transfer_builder = build_transfer_from_input(transfer, asset, decimals)?;

        builders.push(transfer_builder);
    }

    Ok(TransactionTypeBuilder::Transfers(builders))
}

#[cfg(test)]
mod tests;
