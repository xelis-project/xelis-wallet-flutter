use std::sync::{Arc, Barrier};
use std::thread;

use parking_lot::RwLock;
use xelis_common::crypto::Hash;

use super::*;

fn prepared_store<T>(hash: Hash, transaction: T) -> RwLock<PreparedTransactionStore<T>> {
    let mut store = PreparedTransactionStore::default();
    store.replace(hash, transaction).unwrap();
    RwLock::new(store)
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

fn is_in_flight<T>(store: &PreparedTransactionStore<T>, expected_hash: &Hash) -> bool {
    matches!(
        &store.state,
        PreparedTransactionState::InFlight { hash, .. } if hash == expected_hash
    )
}

#[test]
fn prepared_replacement_is_explicitly_single_transaction() {
    let first = Hash::new([6; 32]);
    let second = Hash::new([7; 32]);
    let mut prepared = PreparedTransactionStore::default();

    prepared.replace(first.clone(), "first").unwrap();
    prepared.replace(second.clone(), "second").unwrap();

    assert_eq!(ready_transaction(&prepared, &first), None);
    assert_eq!(ready_transaction(&prepared, &second), Some(&"second"));
}

#[test]
fn taking_an_unknown_hash_preserves_the_prepared_transaction() {
    let existing = Hash::new([16; 32]);
    let missing = Hash::new([17; 32]);
    let mut prepared = PreparedTransactionStore::default();
    prepared.replace(existing.clone(), "existing").unwrap();

    assert_eq!(
        prepared
            .take_for_submission(&missing)
            .unwrap_err()
            .to_string(),
        "Cannot find prepared transaction"
    );
    assert_eq!(ready_transaction(&prepared, &existing), Some(&"existing"));
    assert_eq!(ready_transaction(&prepared, &missing), None);
}

#[test]
fn concurrent_prepared_takes_allow_only_one_broadcast() {
    let hash = Hash::new([8; 32]);
    let prepared = Arc::new(prepared_store(hash.clone(), 42));
    let barrier = Arc::new(Barrier::new(3));
    let mut handles = Vec::new();

    for _ in 0..2 {
        let prepared = Arc::clone(&prepared);
        let barrier = Arc::clone(&barrier);
        let hash = hash.clone();
        handles.push(thread::spawn(move || {
            barrier.wait();
            let guard = PreparedTransactionGuard::take(&prepared, hash);
            barrier.wait();
            guard.is_ok()
        }));
    }

    barrier.wait();
    barrier.wait();
    let successful_takes = handles
        .into_iter()
        .map(|handle| handle.join().unwrap())
        .filter(|successful| *successful)
        .count();

    assert_eq!(successful_takes, 1);
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&42));
}

#[test]
fn interrupted_submission_guard_restores_the_prepared_transaction_on_drop() {
    let hash = Hash::new([18; 32]);
    let prepared = prepared_store(hash.clone(), "interrupted");

    {
        let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();
        assert_eq!(guard.transaction().unwrap(), &"interrupted");
        assert!(is_in_flight(&prepared.read(), &hash));
    }

    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"interrupted")
    );
}

#[test]
fn replacement_is_rejected_while_a_transaction_is_in_flight() {
    let hash = Hash::new([19; 32]);
    let replacement = Hash::new([20; 32]);
    let prepared = prepared_store(hash.clone(), "original");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    assert_eq!(
        prepared
            .write()
            .replace(replacement.clone(), "replacement")
            .unwrap_err()
            .to_string(),
        "Cannot replace a prepared transaction while another transaction is being submitted"
    );
    drop(guard);

    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"original")
    );
    assert_eq!(ready_transaction(&prepared.read(), &replacement), None);
}

#[test]
fn cancellation_is_rejected_while_a_transaction_is_in_flight() {
    let hash = Hash::new([21; 32]);
    let prepared = prepared_store(hash.clone(), "original");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    assert_eq!(
        prepared.write().cancel(&hash).unwrap_err().to_string(),
        "Cannot cancel a transaction while it is being submitted"
    );
    drop(guard);

    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"original")
    );
}

fn ready_generation<T>(store: &PreparedTransactionStore<T>, expected_hash: &Hash) -> Option<u64> {
    match &store.state {
        PreparedTransactionState::Ready {
            generation, hash, ..
        } if hash == expected_hash => Some(*generation),
        _ => None,
    }
}

#[test]
fn every_replacement_advances_generation_and_invalidates_the_old_capability() {
    let hash = Hash::new([41; 32]);
    let mut prepared = PreparedTransactionStore::default();
    prepared.replace(hash.clone(), "first").unwrap();
    let first_generation = ready_generation(&prepared, &hash).unwrap();

    prepared.replace(hash.clone(), "second").unwrap();
    let second_generation = ready_generation(&prepared, &hash).unwrap();

    assert!(second_generation > first_generation);
    assert_eq!(
        prepared
            .ensure_ready_exact(first_generation, &hash)
            .unwrap_err(),
        PreparedTransactionError::NotFound
    );
    prepared
        .ensure_ready_exact(second_generation, &hash)
        .unwrap();
    assert_eq!(ready_transaction(&prepared, &hash), Some(&"second"));
}

#[test]
fn concurrent_stable_preparations_are_rejected_without_losing_the_existing_slot() {
    let existing_hash = Hash::new([42; 32]);
    let prepared = prepared_store(existing_hash.clone(), "existing");
    let existing_generation = ready_generation(&prepared.read(), &existing_hash).unwrap();

    let preparation = PreparedTransactionPreparationGuard::begin(&prepared).unwrap();
    let concurrent_error = PreparedTransactionPreparationGuard::begin(&prepared)
        .err()
        .expect("concurrent preparation must fail");
    assert_eq!(
        concurrent_error.to_string(),
        "Cannot replace a prepared transaction while another preparation is in progress"
    );
    drop(preparation);

    prepared
        .read()
        .ensure_ready_exact(existing_generation, &existing_hash)
        .unwrap();
    assert_eq!(
        ready_transaction(&prepared.read(), &existing_hash),
        Some(&"existing")
    );
}

#[test]
fn stable_commit_publishes_generation_and_exact_identity() {
    let hash = Hash::new([43; 32]);
    let wrong_hash = Hash::new([44; 32]);
    let prepared = RwLock::new(PreparedTransactionStore::default());
    let preparation = PreparedTransactionPreparationGuard::begin(&prepared).unwrap();
    let generation = preparation.commit(hash.clone(), "prepared").unwrap();

    prepared
        .read()
        .ensure_ready_exact(generation, &hash)
        .unwrap();
    assert_eq!(
        prepared
            .read()
            .ensure_ready_exact(generation, &wrong_hash)
            .unwrap_err(),
        PreparedTransactionError::NotFound
    );
    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"prepared")
    );
}

#[test]
fn exact_retry_restore_keeps_generation_and_hash() {
    let hash = Hash::new([45; 32]);
    let prepared = prepared_store(hash.clone(), "retry");
    let generation = ready_generation(&prepared.read(), &hash).unwrap();
    let guard = PreparedTransactionGuard::take_exact(&prepared, generation, hash.clone()).unwrap();

    guard.restore().unwrap();

    prepared
        .read()
        .ensure_ready_exact(generation, &hash)
        .unwrap();
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&"retry"));
}

#[test]
fn exact_cancellation_rejects_stale_generation_without_consuming_slot() {
    let hash = Hash::new([46; 32]);
    let mut prepared = PreparedTransactionStore::default();
    prepared.replace(hash.clone(), "keep").unwrap();
    let generation = ready_generation(&prepared, &hash).unwrap();

    assert_eq!(
        prepared.cancel_exact(generation + 1, &hash).unwrap_err(),
        PreparedTransactionError::NotFound
    );
    prepared.ensure_ready_exact(generation, &hash).unwrap();
    assert_eq!(ready_transaction(&prepared, &hash), Some(&"keep"));
}
