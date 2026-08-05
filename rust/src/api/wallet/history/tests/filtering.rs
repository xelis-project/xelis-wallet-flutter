use super::*;

#[test]
fn filtered_history_pages_are_disjoint_and_do_not_repeat_entries() {
    let mut fixture = create_test_storage();
    let burn_asset = Hash::new([99; 32]);

    for index in 0u8..6 {
        let hash = Hash::new([index; 32]);
        let entry = TransactionEntry::new(
            hash.clone(),
            u64::from(index),
            0,
            if index % 2 == 0 {
                EntryData::Coinbase { reward: 1 }
            } else {
                EntryData::Burn {
                    asset: burn_asset.clone(),
                    amount: 1,
                    fee: 0,
                    nonce: u64::from(index),
                }
            },
        );
        fixture.storage.save_transaction(&hash, &entry).unwrap();
    }

    let first = burn_page(&fixture.storage, 1);
    let second = burn_page(&fixture.storage, 2);
    let third = burn_page(&fixture.storage, 3);

    assert_eq!(first, vec![Hash::new([5; 32]), Hash::new([3; 32])]);
    assert_eq!(second, vec![Hash::new([1; 32])]);
    assert!(third.is_empty());
    assert!(first.iter().all(|hash| !second.contains(hash)));
}

#[test]
fn address_filter_disables_global_transaction_kinds() {
    let address = KeyPair::new().get_public_key().to_address(false);
    let mut filtered = filter();
    filtered.address = Some(address.to_string());

    let options = filtered.options().unwrap();

    assert!(options.address.is_some());
    assert!(!options.accept_coinbase);
    assert!(!options.accept_burn);
    assert!(!options.accept_blob);
}

#[test]
fn integrated_address_defers_base_and_data_matching_to_the_exact_filter() {
    let public_key = KeyPair::new().get_public_key().compress();
    let mut filtered = filter();
    filtered.address = Some(integrated_address(
        &public_key,
        DataElement::Value(DataValue::U8(7)),
    ));

    let prepared = filtered.prepare().unwrap();

    assert!(prepared.options.address.is_none());
    assert!(prepared.exact_integrated_destination.is_some());
    assert!(!prepared.options.accept_coinbase);
    assert!(!prepared.options.accept_burn);
    assert!(!prepared.options.accept_blob);
}

#[test]
fn integrated_address_filter_retains_exact_data_before_pagination() {
    let mut fixture = create_test_storage();
    let destination = KeyPair::new().get_public_key().compress();
    let wallet_public_key = KeyPair::new().get_public_key().compress();
    let asset = Hash::new([77; 32]);
    let first = DataElement::Value(DataValue::String("first".to_owned()));
    let second = DataElement::Value(DataValue::String("second".to_owned()));
    let encoded = integrated_address(&destination, first.clone());

    for (index, data) in [first.clone(), second, first].into_iter().enumerate() {
        let hash = Hash::new([index as u8; 32]);
        fixture
            .storage
            .save_transaction(
                &hash,
                &TransactionEntry::new(
                    hash.clone(),
                    index as u64,
                    0,
                    EntryData::Outgoing {
                        transfers: vec![TransferOut::new(
                            destination.clone(),
                            asset.clone(),
                            1,
                            Some(extra_data(data)),
                        )],
                        fee: 0,
                        nonce: index as u64,
                    },
                ),
            )
            .unwrap();
    }

    let first_page =
        exact_destination_page(&fixture.storage, encoded.clone(), &wallet_public_key, 1);
    let second_page = exact_destination_page(&fixture.storage, encoded, &wallet_public_key, 2);

    assert_eq!(first_page, vec![Hash::new([2; 32])]);
    assert_eq!(second_page, vec![Hash::new([0; 32])]);
    assert!(first_page.iter().all(|hash| !second_page.contains(hash)));
}

#[test]
fn integrated_incoming_destination_is_the_current_wallet_implicitly() {
    let wallet_public_key = KeyPair::new().get_public_key().compress();
    let other_public_key = KeyPair::new().get_public_key().compress();
    let sender = KeyPair::new().get_public_key().compress();
    let data = DataElement::Value(DataValue::U64(42));
    let asset = Hash::new([42; 32]);
    let transaction = TransactionEntry::new(
        Hash::new([8; 32]),
        1,
        0,
        EntryData::Incoming {
            from: sender,
            transfers: vec![TransferIn::new(asset, 1, Some(extra_data(data.clone())))],
        },
    );

    let mut own_filter = filter();
    own_filter.address = Some(integrated_address(&wallet_public_key, data.clone()));
    let own_destination = own_filter
        .prepare()
        .unwrap()
        .exact_integrated_destination
        .unwrap();
    assert_eq!(
        apply_exact_integrated_destination(
            vec![transaction.clone()],
            &own_destination,
            &wallet_public_key,
        )
        .len(),
        1
    );

    let mut other_filter = filter();
    other_filter.address = Some(integrated_address(&other_public_key, data));
    let other_destination = other_filter
        .prepare()
        .unwrap()
        .exact_integrated_destination
        .unwrap();
    assert!(apply_exact_integrated_destination(
        vec![transaction],
        &other_destination,
        &wallet_public_key,
    )
    .is_empty());
}

#[test]
fn asset_filter_disables_blob_but_preserves_other_requested_kinds() {
    let mut filtered = filter();
    filtered.asset_hash = Some(Hash::new([4; 32]).to_hex());

    let options = filtered.options().unwrap();

    assert!(options.asset.is_some());
    assert!(options.accept_coinbase);
    assert!(options.accept_burn);
    assert!(!options.accept_blob);
}

#[test]
fn history_rejects_invalid_address_and_asset_filters() {
    let mut invalid_address = filter();
    invalid_address.address = Some("invalid-address".to_owned());
    assert!(invalid_address
        .options()
        .unwrap_err()
        .to_string()
        .starts_with("Invalid address"));

    let mut invalid_asset = filter();
    invalid_asset.asset_hash = Some("invalid-asset".to_owned());
    assert!(invalid_asset
        .options()
        .unwrap_err()
        .to_string()
        .starts_with("Invalid asset"));
}
