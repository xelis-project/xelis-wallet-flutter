use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Address, AddressType, Hash, KeyPair};
use xelis_common::transaction::builder::{TransactionTypeBuilder, TransferBuilder};

use crate::api::error::NativeXelisErrorCode;
use crate::api::models::wallet_dtos::{
    NativePreparedTransactionKind, NativeTransactionFeePolicy, NativeTransactionTransferRequest,
    Transfer,
};

use super::*;

fn transfer_input(
    float_amount: f64,
    destination: String,
    asset: &Hash,
    extra_data: Option<&str>,
    encrypt_extra_data: Option<bool>,
) -> Transfer {
    Transfer {
        float_amount,
        str_address: destination,
        asset_hash: asset.to_hex(),
        extra_data: extra_data.map(str::to_owned),
        encrypt_extra_data,
    }
}

fn transfers_from(transaction_type: TransactionTypeBuilder) -> Vec<TransferBuilder> {
    let TransactionTypeBuilder::Transfers(transfers) = transaction_type else {
        panic!("expected a transfers transaction type");
    };

    transfers
}

mod burn;
mod fees;
mod policy;
mod projection;
mod transfers;
