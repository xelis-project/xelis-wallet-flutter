use anyhow::Error;
use parking_lot::RwLock;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::crypto::{Address, AddressType, Hash, KeyPair};
use xelis_common::rpc::client::JsonRPCError;
use xelis_common::transaction::builder::TransactionTypeBuilder;
use xelis_wallet::error::WalletError;

use crate::api::error::NativeXelisErrorCode;
use crate::api::models::wallet_dtos::{
    BroadcastTransactionOutcome, NativePreparedTransactionBroadcastOutcome,
    NativePreparedTransactionKind,
};

use super::builders::{build_burn_type, project_prepared_transfer};
use super::prepared::{
    PreparedTransactionGuard, PreparedTransactionState, PreparedTransactionStore,
};
use super::submission::{ensure_wallet_online, resolve_submission, SubmissionResolution};
use super::{build_and_store_prepared, offline_prepared_transaction_outcome};

fn daemon_rejection() -> WalletError {
    WalletError::from(Error::new(JsonRPCError::ServerError {
        code: -32_000,
        message: "rejected".to_owned(),
        data: None,
    }))
}

fn prepared_store<T>(hash: Hash, transaction: T) -> RwLock<PreparedTransactionStore<T>> {
    let mut store = PreparedTransactionStore::default();
    store.replace(hash, transaction).unwrap();
    RwLock::new(store)
}

#[test]
fn transfer_all_projection_redacts_integrated_address_data() {
    let key_pair = KeyPair::new();
    let normal_destination = key_pair.get_public_key().to_address(false);
    let secret_payload = "transfer-all integrated payload";
    let integrated_destination = Address::new(
        false,
        AddressType::Data(DataElement::Value(DataValue::String(
            secret_payload.to_owned(),
        ))),
        key_pair.get_public_key().compress(),
    );
    let integrated_address = integrated_destination.to_string();

    let (prepared_transfer, review_extra_data) = project_prepared_transfer(
        &integrated_destination,
        &Hash::new([52; 32]),
        123,
        None,
        true,
    )
    .unwrap();
    let projection = NativePreparedTransactionKind::Transfers {
        transfers: vec![prepared_transfer],
    };

    let NativePreparedTransactionKind::Transfers { transfers } = projection else {
        panic!("expected a transfer projection");
    };
    assert_eq!(transfers[0].destination, normal_destination.to_string());
    assert_ne!(transfers[0].destination, integrated_address);
    assert!(transfers[0].has_extra_data);
    assert!(transfers[0].encrypt_extra_data);

    let projected_debug = format!("{transfers:?}");
    assert!(!projected_debug.contains(secret_payload));
    assert!(!projected_debug.contains(&integrated_address));
    assert!(review_extra_data.is_some());
}

fn ready_transaction<'a, T>(
    store: &'a PreparedTransactionStore<T>,
    expected_hash: &Hash,
) -> Option<&'a T> {
    match &store.state {
        PreparedTransactionState::Ready {
            hash, transaction, ..
        } if hash == expected_hash => Some(transaction),
        _ => None,
    }
}

fn is_empty<T>(store: &PreparedTransactionStore<T>) -> bool {
    matches!(store.state, PreparedTransactionState::Empty)
}

fn ready_generation<T>(store: &PreparedTransactionStore<T>, expected_hash: &Hash) -> Option<u64> {
    match &store.state {
        PreparedTransactionState::Ready {
            generation, hash, ..
        } if hash == expected_hash => Some(*generation),
        _ => None,
    }
}

#[tokio::test]
async fn failed_transaction_construction_preserves_the_prepared_slot() {
    let existing = Hash::new([32; 32]);
    let prepared = prepared_store(existing.clone(), "existing");
    let result = build_and_store_prepared(
        &prepared,
        build_burn_type(Hash::new([33; 32]), 42),
        |_| async { Err::<(Hash, u64, &'static str), _>(anyhow::anyhow!("construction failed")) },
    )
    .await;

    assert_eq!(result.unwrap_err().to_string(), "construction failed");
    assert_eq!(
        ready_transaction(&prepared.read(), &existing),
        Some(&"existing")
    );
}

#[tokio::test]
async fn successful_construction_stores_the_exact_builder_and_summary() {
    let existing = Hash::new([34; 32]);
    let replacement = Hash::new([35; 32]);
    let returned_hash = replacement.clone();
    let prepared = prepared_store(existing.clone(), "existing");
    let summary = build_and_store_prepared(
        &prepared,
        build_burn_type(Hash::new([36; 32]), 42),
        |transaction_type| async move {
            let TransactionTypeBuilder::Burn(payload) = transaction_type else {
                panic!("expected the burn builder passed to construction");
            };
            assert_eq!(payload.asset, Hash::new([36; 32]));
            assert_eq!(payload.amount, 42);

            Ok((returned_hash, 7, "replacement"))
        },
    )
    .await
    .unwrap();
    let summary: serde_json::Value = serde_json::from_str(&summary).unwrap();

    assert_eq!(ready_transaction(&prepared.read(), &existing), None);
    assert_eq!(
        ready_transaction(&prepared.read(), &replacement),
        Some(&"replacement")
    );
    assert_eq!(summary["hash"], replacement.to_hex());
    assert_eq!(summary["fee"], 7);
    assert_eq!(summary["transaction_type"]["burn"]["amount"], 42);
}

#[test]
fn offline_wallet_is_rejected_without_touching_the_prepared_transaction() {
    let hash = Hash::new([5; 32]);
    let prepared = prepared_store(hash.clone(), "transaction");

    assert_eq!(
        ensure_wallet_online(false).unwrap_err().to_string(),
        "Wallet is offline, transaction cannot be submitted"
    );
    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"transaction")
    );

    ensure_wallet_online(true).unwrap();
}

#[test]
fn successful_submission_consumes_the_prepared_transaction() {
    let hash = Hash::new([9; 32]);
    let prepared = prepared_store(hash.clone(), "submitted");
    let guard = PreparedTransactionGuard::take(&prepared, hash).unwrap();

    let resolution = resolve_submission(Ok(()));

    assert!(matches!(resolution, SubmissionResolution::Submitted));
    assert_eq!(guard.finish().unwrap(), "submitted");
    assert!(is_empty(&prepared.read()));
}

#[test]
fn retryable_failure_restores_the_exact_prepared_transaction() {
    let hash = Hash::new([11; 32]);
    let prepared = prepared_store(hash.clone(), "retry");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    let resolution = resolve_submission(Err(WalletError::NotOnlineMode));

    assert!(matches!(
        resolution,
        SubmissionResolution::Retryable(WalletError::NotOnlineMode)
    ));
    guard.restore().unwrap();
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&"retry"));
}

#[test]
fn daemon_rejection_discards_the_submitted_transaction() {
    let hash = Hash::new([13; 32]);
    let prepared = prepared_store(hash.clone(), "rejected");
    let guard = PreparedTransactionGuard::take(&prepared, hash).unwrap();

    let resolution = resolve_submission(Err(daemon_rejection()));

    assert!(matches!(
        resolution,
        SubmissionResolution::DaemonRejected(_)
    ));
    assert_eq!(guard.finish().unwrap(), "rejected");
    assert!(is_empty(&prepared.read()));
}

#[test]
fn a_post_submit_apply_failure_does_not_make_the_transaction_retryable() {
    let hash = Hash::new([15; 32]);
    let prepared = prepared_store(hash.clone(), "submitted");
    let guard = PreparedTransactionGuard::take(&prepared, hash).unwrap();

    let resolution = resolve_submission(Ok(()));
    let SubmissionResolution::Submitted = resolution else {
        panic!("successful submission must enter the submitted state");
    };
    let _submitted = guard.finish().unwrap();
    let apply_result = Err::<(), _>(anyhow::anyhow!("local apply failed"));

    assert!(apply_result.is_err());
    assert!(is_empty(&prepared.read()));
    assert_ne!(
        BroadcastTransactionOutcome::SubmittedNeedsResync,
        BroadcastTransactionOutcome::Retryable
    );
}

#[test]
fn offline_exact_capability_is_retryable_without_touching_the_slot() {
    let hash = Hash::new([50; 32]);
    let prepared = prepared_store(hash.clone(), "offline");
    let generation = ready_generation(&prepared.read(), &hash).unwrap();

    let outcome = offline_prepared_transaction_outcome(&prepared, generation, &hash).unwrap();
    let NativePreparedTransactionBroadcastOutcome::Retryable { failure } = outcome else {
        panic!("offline exact capability must be retryable");
    };

    assert_eq!(failure.code, NativeXelisErrorCode::Offline);
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&"offline"));
    assert_eq!(ready_generation(&prepared.read(), &hash), Some(generation));
}

#[test]
fn offline_stale_capability_is_rejected_without_touching_the_current_slot() {
    let hash = Hash::new([51; 32]);
    let prepared = prepared_store(hash.clone(), "current");
    let generation = ready_generation(&prepared.read(), &hash).unwrap();

    let error = offline_prepared_transaction_outcome(&prepared, generation + 1, &hash).unwrap_err();

    assert_eq!(error.code, NativeXelisErrorCode::NotFound);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("PREPARED_TRANSACTION_NOT_FOUND")
    );
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&"current"));
    assert_eq!(ready_generation(&prepared.read(), &hash), Some(generation));
}
