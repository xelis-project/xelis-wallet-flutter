use super::*;

#[test]
fn fee_is_deducted_only_from_the_native_asset() {
    assert_eq!(
        amount_after_fee(100, 25, &XELIS_ASSET, "insufficient").unwrap(),
        75
    );

    let token = Hash::new([4; 32]);
    assert_eq!(
        amount_after_fee(100, 200, &token, "insufficient").unwrap(),
        100
    );
}

#[test]
fn native_asset_fee_rejects_an_insufficient_balance() {
    for balance in [24, 25] {
        let error = amount_after_fee(balance, 25, &XELIS_ASSET, "insufficient").unwrap_err();

        assert_eq!(error.to_string(), "insufficient");
    }

    let token = Hash::new([27; 32]);
    assert_eq!(
        amount_after_fee(0, 25, &token, "insufficient")
            .unwrap_err()
            .to_string(),
        "insufficient"
    );
}

#[test]
fn transfer_all_uses_post_fee_xelis_amount_and_preserves_options() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transfers = transfers_from(
        build_transfer_all_type(
            destination.clone(),
            100,
            25,
            XELIS_ASSET,
            Some("all".to_owned()),
            Some(false),
        )
        .unwrap(),
    );

    assert_eq!(transfers.len(), 1);
    assert_eq!(transfers[0].destination, destination);
    assert_eq!(transfers[0].asset, XELIS_ASSET);
    assert_eq!(transfers[0].amount, 75);
    assert!(!transfers[0].encrypt_extra_data);
    assert!(matches!(
        &transfers[0].extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "all"
    ));
}

#[test]
fn transfer_all_keeps_the_full_token_amount_because_fees_use_xelis() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let token = Hash::new([28; 32]);
    let transfers = transfers_from(
        build_transfer_all_type(destination, 100, 1_000, token.clone(), None, None).unwrap(),
    );

    assert_eq!(transfers[0].asset, token);
    assert_eq!(transfers[0].amount, 100);
}

#[test]
fn transfer_all_rejects_a_zero_post_fee_amount() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let error = build_transfer_all_type(destination, 25, 25, XELIS_ASSET, None, None).unwrap_err();

    assert_eq!(error.to_string(), "Insufficient balance for fees");
}
