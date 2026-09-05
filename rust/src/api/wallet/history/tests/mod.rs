use xelis_common::{
    api::{DataElement, DataValue},
    crypto::{Address, AddressType, Hash, KeyPair, PublicKey},
    network::Network,
    transaction::extra_data::{PlaintextExtraData, PlaintextFlag},
};
use xelis_wallet::{
    config::SALT_SIZE,
    entry::{EntryData, TransactionEntry, TransferIn, TransferOut},
    storage::{EncryptedStorage, Storage},
};

#[cfg(not(target_arch = "wasm32"))]
use std::{fs, io::Write, path::Path};
#[cfg(not(target_arch = "wasm32"))]
use tempfile::tempdir;

use super::{
    apply_exact_integrated_destination, classify_history_error, ensure_transactions_to_export,
    ExtraDataProjection, FilteredPagination,
};
#[cfg(not(target_arch = "wasm32"))]
use super::{create_temporary_csv_file, csv_path_error, persist_csv_file};
use crate::api::{
    error::{NativeXelisErrorCode, NativeXelisErrorSource},
    models::{
        business_event_dtos::NativeWalletExtraDataDisclosure, wallet_dtos::HistoryPageFilter,
    },
};

#[test]
fn read_disclosure_maps_all_public_variants_without_collapsing_redacted() {
    assert_eq!(
        ExtraDataProjection::from_disclosure(NativeWalletExtraDataDisclosure::Redacted),
        ExtraDataProjection::Redacted,
    );
    assert_eq!(
        ExtraDataProjection::from_disclosure(NativeWalletExtraDataDisclosure::Metadata),
        ExtraDataProjection::Metadata,
    );
    assert_eq!(
        ExtraDataProjection::from_disclosure(NativeWalletExtraDataDisclosure::Detailed),
        ExtraDataProjection::Detailed,
    );
}

fn filter() -> HistoryPageFilter {
    HistoryPageFilter {
        page: 1,
        limit: Some(10),
        asset_hash: None,
        address: None,
        min_topoheight: None,
        max_topoheight: None,
        accept_incoming: true,
        accept_outgoing: true,
        accept_coinbase: true,
        accept_burn: true,
        accept_blob: true,
        min_timestamp: None,
        max_timestamp: None,
    }
}

struct TestStorage {
    storage: EncryptedStorage,
    _directory: tempfile::TempDir,
}

fn create_test_storage() -> TestStorage {
    let directory = tempfile::tempdir().unwrap();
    let path = directory.path().join("wallet");
    let storage = Storage::new(path.to_str().unwrap()).unwrap();
    let storage =
        EncryptedStorage::new(storage, &[42u8; 32], [0u8; SALT_SIZE], Network::Testnet).unwrap();

    TestStorage {
        storage,
        _directory: directory,
    }
}

fn integrated_address(public_key: &PublicKey, data: DataElement) -> String {
    Address::new(false, AddressType::Data(data), public_key.clone()).to_string()
}

fn extra_data(data: DataElement) -> PlaintextExtraData {
    PlaintextExtraData::new(None, Some(data), PlaintextFlag::Public)
}

fn exact_destination_page(
    storage: &EncryptedStorage,
    address: String,
    wallet_public_key: &PublicKey,
    page: usize,
) -> Vec<Hash> {
    let mut filtered = filter();
    filtered.page = page;
    filtered.limit = Some(1);
    filtered.address = Some(address);

    let prepared = filtered.prepare().unwrap();
    let mut options = prepared.options;
    let pagination = FilteredPagination::prepare(&mut options).unwrap();
    let destination = prepared.exact_integrated_destination.unwrap();

    // An upstream prefix cannot be used before the exact payload filter.
    options.limit = None;
    pagination
        .apply(apply_exact_integrated_destination(
            storage.get_filtered_transactions(options).unwrap(),
            &destination,
            wallet_public_key,
        ))
        .into_iter()
        .map(|entry| entry.get_hash().clone())
        .collect()
}

fn burn_page(storage: &EncryptedStorage, page: usize) -> Vec<Hash> {
    let mut filtered = filter();
    filtered.page = page;
    filtered.limit = Some(2);
    filtered.accept_coinbase = false;
    filtered.accept_burn = true;

    let mut options = filtered.options().unwrap();
    let pagination = FilteredPagination::prepare(&mut options).unwrap();
    assert_eq!(options.skip, None);

    pagination
        .apply(storage.get_filtered_transactions(options).unwrap())
        .into_iter()
        .map(|entry| entry.get_hash().clone())
        .collect()
}

mod csv;
mod errors;
mod filtering;
mod pagination;
