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
fn basis_point_fee_policy_is_exact_ceil_and_bounded_to_ten_times() {
    assert_eq!(
        apply_fee_policy(
            101,
            NativeTransactionFeePolicy {
                basis_points: 10_000,
            },
        )
        .unwrap(),
        101
    );
    assert_eq!(
        apply_fee_policy(
            101,
            NativeTransactionFeePolicy {
                basis_points: 15_000,
            },
        )
        .unwrap(),
        152
    );
    assert_eq!(
        apply_fee_policy(
            1,
            NativeTransactionFeePolicy {
                basis_points: 10_001,
            },
        )
        .unwrap(),
        2
    );
    assert_eq!(
        apply_fee_policy(
            7,
            NativeTransactionFeePolicy {
                basis_points: 100_000,
            },
        )
        .unwrap(),
        70
    );

    for basis_points in [9_999, 100_001] {
        let error = apply_fee_policy(100, NativeTransactionFeePolicy { basis_points }).unwrap_err();
        assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
        assert_eq!(
            error.native_kind.as_deref(),
            Some("TRANSACTION_FEE_POLICY_INVALID")
        );
    }
}
