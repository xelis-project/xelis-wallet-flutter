use super::*;

#[test]
fn burn_builders_preserve_asset_and_apply_all_fee_rules() {
    let token = Hash::new([29; 32]);
    let TransactionTypeBuilder::Burn(requested) = build_burn_type(token.clone(), 42) else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(requested.asset, token);
    assert_eq!(requested.amount, 42);

    let TransactionTypeBuilder::Burn(xelis_all) =
        build_burn_all_type(XELIS_ASSET, 100, 25).unwrap()
    else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(xelis_all.asset, XELIS_ASSET);
    assert_eq!(xelis_all.amount, 75);

    let TransactionTypeBuilder::Burn(token_all) =
        build_burn_all_type(token.clone(), 100, 1_000).unwrap()
    else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(token_all.asset, token);
    assert_eq!(token_all.amount, 100);
}

#[test]
fn burn_all_rejects_a_zero_post_fee_amount() {
    let error = build_burn_all_type(XELIS_ASSET, 25, 25).unwrap_err();

    assert_eq!(
        error.to_string(),
        "Insufficient balance to pay burn transaction fees"
    );
}
