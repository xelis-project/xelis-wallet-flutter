use super::*;

#[test]
fn encryption_defaults_to_enabled_and_respects_explicit_values() {
    assert!(encrypt_extra_data_or_default(None));
    assert!(encrypt_extra_data_or_default(Some(true)));
    assert!(!encrypt_extra_data_or_default(Some(false)));
}

#[test]
fn transfer_builder_maps_extra_data_and_encryption() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([3; 32]);
    let transfer = build_transfer(
        destination.clone(),
        42,
        asset.clone(),
        Some("memo".to_owned()),
        None,
    );

    assert_eq!(transfer.destination, destination);
    assert_eq!(transfer.amount, 42);
    assert_eq!(transfer.asset, asset);
    assert!(transfer.encrypt_extra_data);
    assert!(matches!(
        transfer.extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "memo"
    ));
}

#[test]
fn transfer_builder_preserves_absent_extra_data_and_explicit_public_flag() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transfer = build_transfer(destination, 7, Hash::new([22; 32]), None, Some(false));

    assert!(transfer.extra_data.is_none());
    assert!(!transfer.encrypt_extra_data);
}

#[test]
fn transfer_input_uses_asset_precision_and_validates_the_destination() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([23; 32]);
    let transfer = build_transfer_from_input(
        transfer_input(
            1.25,
            destination.to_string(),
            &asset,
            Some("asset memo"),
            Some(false),
        ),
        asset.clone(),
        2,
    )
    .unwrap();

    assert_eq!(transfer.destination, destination);
    assert_eq!(transfer.asset, asset);
    assert_eq!(transfer.amount, 125);
    assert!(!transfer.encrypt_extra_data);
    assert!(matches!(
        transfer.extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "asset memo"
    ));

    let error = build_transfer_from_input(
        transfer_input(1.0, "invalid".to_owned(), &Hash::new([24; 32]), None, None),
        Hash::new([24; 32]),
        8,
    )
    .unwrap_err();

    assert!(error.to_string().starts_with("Invalid address"));
}

#[test]
fn transfer_input_rejects_amounts_that_do_not_match_asset_precision() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([25; 32]);
    let error = build_transfer_from_input(
        transfer_input(1.234, destination.to_string(), &asset, None, None),
        asset,
        2,
    )
    .unwrap_err();

    assert!(error
        .to_string()
        .starts_with("Error while converting amount to atomic format"));
}

#[tokio::test]
async fn multi_asset_transfers_preserve_order_amounts_and_independent_options() {
    let first_destination = KeyPair::new().get_public_key().to_address(false);
    let second_destination = KeyPair::new().get_public_key().to_address(false);
    let token = Hash::new([26; 32]);

    let transaction_type = create_transfers_with_decimals(
        vec![
            transfer_input(
                1.25,
                first_destination.to_string(),
                &XELIS_ASSET,
                Some("private"),
                None,
            ),
            transfer_input(
                2.5,
                second_destination.to_string(),
                &token,
                None,
                Some(false),
            ),
        ],
        |asset| async move {
            if asset == XELIS_ASSET {
                Ok(8)
            } else {
                Ok(2)
            }
        },
    )
    .await
    .unwrap();
    let transfers = transfers_from(transaction_type);

    assert_eq!(transfers.len(), 2);
    assert_eq!(transfers[0].destination, first_destination);
    assert_eq!(transfers[0].asset, XELIS_ASSET);
    assert_eq!(transfers[0].amount, 125_000_000);
    assert!(transfers[0].encrypt_extra_data);
    assert!(transfers[0].extra_data.is_some());
    assert_eq!(transfers[1].destination, second_destination);
    assert_eq!(transfers[1].asset, token);
    assert_eq!(transfers[1].amount, 250);
    assert!(!transfers[1].encrypt_extra_data);
    assert!(transfers[1].extra_data.is_none());
}

#[tokio::test]
async fn transfer_collection_stops_on_asset_metadata_failure() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([31; 32]);
    let error = create_transfers_with_decimals(
        vec![transfer_input(
            1.25,
            destination.to_string(),
            &asset,
            None,
            None,
        )],
        |_| async { Err(anyhow::anyhow!("asset metadata missing")) },
    )
    .await
    .unwrap_err();

    assert!(error
        .to_string()
        .starts_with("Error while converting amount to atomic format"));
}
