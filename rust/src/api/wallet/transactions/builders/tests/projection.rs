use super::*;

#[test]
fn atomic_transfer_projection_never_contains_extra_data_payload() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([47; 32]);
    let secret_payload = "private transfer payload";
    let (transaction_type, projection, review_extra_data) =
        build_atomic_transfers(vec![NativeTransactionTransferRequest {
            amount: 42,
            destination: destination.to_string(),
            asset: asset.to_hex(),
            extra_data: Some(secret_payload.to_owned()),
            encrypt_extra_data: true,
        }])
        .unwrap();

    let transfers = transfers_from(transaction_type);
    assert!(matches!(
        &transfers[0].extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == secret_payload
    ));
    let NativePreparedTransactionKind::Transfers { transfers } = projection else {
        panic!("expected a transfer projection");
    };
    assert_eq!(transfers.len(), 1);
    assert_eq!(transfers[0].amount, 42);
    assert_eq!(transfers[0].destination, destination.to_string());
    assert_eq!(transfers[0].asset, asset.to_hex());
    assert!(transfers[0].has_extra_data);
    assert!(transfers[0].encrypt_extra_data);
    assert!(!format!("{transfers:?}").contains(secret_payload));
    assert_eq!(review_extra_data.len(), 1);
    assert!(review_extra_data[0].is_some());
}

#[test]
fn atomic_transfer_projection_redacts_integrated_address_data() {
    let key_pair = KeyPair::new();
    let normal_destination = key_pair.get_public_key().to_address(false);
    let secret_payload = "integrated private payload";
    let integrated_data = DataElement::Value(DataValue::String(secret_payload.to_owned()));
    let integrated_destination = Address::new(
        false,
        AddressType::Data(integrated_data.clone()),
        key_pair.get_public_key().compress(),
    );
    let integrated_address = integrated_destination.to_string();
    let asset = Hash::new([50; 32]);

    let (transaction_type, projection, review_extra_data) =
        build_atomic_transfers(vec![NativeTransactionTransferRequest {
            amount: 42,
            destination: integrated_address.clone(),
            asset: asset.to_hex(),
            extra_data: None,
            encrypt_extra_data: true,
        }])
        .unwrap();

    let transfers = transfers_from(transaction_type);
    assert_eq!(transfers[0].destination, integrated_destination);
    assert!(transfers[0].extra_data.is_none());

    let mut normalized_by_upstream = transfers[0].destination.clone();
    assert_eq!(
        normalized_by_upstream.extract_data_only(),
        Some(integrated_data)
    );
    assert_eq!(normalized_by_upstream, normal_destination);

    let NativePreparedTransactionKind::Transfers { transfers } = projection else {
        panic!("expected a transfer projection");
    };
    assert_eq!(transfers.len(), 1);
    assert_eq!(transfers[0].destination, normal_destination.to_string());
    assert_ne!(transfers[0].destination, integrated_address);
    assert!(transfers[0].has_extra_data);
    assert!(transfers[0].encrypt_extra_data);

    let projected_debug = format!("{transfers:?}");
    assert!(!projected_debug.contains(secret_payload));
    assert!(!projected_debug.contains(&integrated_address));
    assert_eq!(review_extra_data.len(), 1);
    assert!(review_extra_data[0].is_some());
}

#[test]
fn atomic_transfer_rejects_integrated_and_explicit_data_conflict() {
    let key_pair = KeyPair::new();
    let integrated_payload = "integrated payload";
    let explicit_payload = "explicit payload";
    let integrated_destination = Address::new(
        false,
        AddressType::Data(DataElement::Value(DataValue::String(
            integrated_payload.to_owned(),
        ))),
        key_pair.get_public_key().compress(),
    );

    let error = build_atomic_transfers(vec![NativeTransactionTransferRequest {
        amount: 7,
        destination: integrated_destination.to_string(),
        asset: Hash::new([51; 32]).to_hex(),
        extra_data: Some(explicit_payload.to_owned()),
        encrypt_extra_data: false,
    }])
    .unwrap_err();

    assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("TRANSACTION_EXTRA_DATA_CONFLICT")
    );
    assert!(!error.to_string().contains(integrated_payload));
    assert!(!error.to_string().contains(explicit_payload));
}

#[test]
fn atomic_transfer_input_rejects_empty_zero_and_unparseable_values() {
    let empty = build_atomic_transfers(Vec::new()).unwrap_err();
    assert_eq!(empty.code, NativeXelisErrorCode::InvalidInput);
    assert_eq!(
        empty.native_kind.as_deref(),
        Some("TRANSACTION_TRANSFERS_EMPTY")
    );

    let destination = KeyPair::new().get_public_key().to_address(false);
    let zero = build_atomic_transfers(vec![NativeTransactionTransferRequest {
        amount: 0,
        destination: destination.to_string(),
        asset: Hash::new([48; 32]).to_hex(),
        extra_data: None,
        encrypt_extra_data: true,
    }])
    .unwrap_err();
    assert_eq!(
        zero.native_kind.as_deref(),
        Some("TRANSACTION_AMOUNT_INVALID")
    );

    let invalid_destination = build_atomic_transfers(vec![NativeTransactionTransferRequest {
        amount: 1,
        destination: "not-an-address".to_owned(),
        asset: Hash::new([49; 32]).to_hex(),
        extra_data: None,
        encrypt_extra_data: false,
    }])
    .unwrap_err();
    assert_eq!(
        invalid_destination.native_kind.as_deref(),
        Some("TRANSACTION_DESTINATION_INVALID")
    );
}
