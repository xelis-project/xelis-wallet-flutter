use super::*;

#[test]
fn summary_serializes_the_final_post_fee_builder() {
    let hash = Hash::new([30; 32]);
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transaction_type =
        build_transfer_all_type(destination, 100, 25, XELIS_ASSET, None, None).unwrap();
    let summary: serde_json::Value =
        serde_json::from_str(&transaction_summary_json(&hash, 25, transaction_type)).unwrap();

    assert_eq!(summary["hash"], hash.to_hex());
    assert_eq!(summary["fee"], 25);
    assert_eq!(summary["transaction_type"]["transfers"][0]["amount"], 75);
}

#[test]
fn every_fee_policy_is_exact_and_checked() {
    assert_eq!(
        apply_fee_policy(101, NativeTransactionFeePolicy::Automatic).unwrap(),
        101
    );
    assert_eq!(
        apply_fee_policy(101, NativeTransactionFeePolicy::Fixed(0)).unwrap(),
        0
    );
    assert_eq!(
        apply_fee_policy(101, NativeTransactionFeePolicy::Tip(0)).unwrap(),
        101
    );
    assert_eq!(
        apply_fee_policy(101, NativeTransactionFeePolicy::Tip(9)).unwrap(),
        110
    );
    assert_eq!(
        apply_fee_policy(101, NativeTransactionFeePolicy::Multiplier(10_000)).unwrap(),
        101
    );
    assert_eq!(
        apply_fee_policy(101, NativeTransactionFeePolicy::Multiplier(15_000)).unwrap(),
        152
    );
    assert_eq!(
        apply_fee_policy(1, NativeTransactionFeePolicy::Multiplier(10_001)).unwrap(),
        2
    );
    assert_eq!(
        apply_fee_policy(7, NativeTransactionFeePolicy::Multiplier(100_001)).unwrap(),
        71
    );
    assert_eq!(
        apply_fee_policy(7, NativeTransactionFeePolicy::Multiplier(1)).unwrap(),
        1
    );

    let zero_multiplier =
        apply_fee_policy(100, NativeTransactionFeePolicy::Multiplier(0)).unwrap_err();
    assert_eq!(zero_multiplier.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        zero_multiplier.native_kind.as_deref(),
        Some("TRANSACTION_FEE_POLICY_INVALID")
    );

    for policy in [
        NativeTransactionFeePolicy::Tip(1),
        NativeTransactionFeePolicy::Multiplier(u64::MAX),
    ] {
        let error = apply_fee_policy(u64::MAX, policy).unwrap_err();
        assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
        assert_eq!(
            error.native_kind.as_deref(),
            Some("TRANSACTION_FEE_OVERFLOW")
        );
    }

    assert_eq!(
        apply_fee_policy(7, NativeTransactionFeePolicy::Fixed(u64::MAX)).unwrap(),
        u64::MAX
    );
}
