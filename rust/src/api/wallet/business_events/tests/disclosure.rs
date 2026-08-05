use super::*;
use crate::api::models::address_dtos::NativeXelisDataElement;

#[test]
fn payload_kind_maps_all_current_data_element_variants() {
    let hash = Hash::new([7; 32]);
    let mut fields = IndexMap::new();
    fields.insert(
        DataValue::String("key".to_owned()),
        DataElement::Value(DataValue::Bool(true)),
    );
    let cases = vec![
        (
            DataElement::Value(DataValue::Bool(true)),
            NativeWalletExtraDataPayloadKind::BoolValue,
        ),
        (
            DataElement::Value(DataValue::String("value".to_owned())),
            NativeWalletExtraDataPayloadKind::String,
        ),
        (
            DataElement::Value(DataValue::U8(1)),
            NativeWalletExtraDataPayloadKind::U8,
        ),
        (
            DataElement::Value(DataValue::U16(2)),
            NativeWalletExtraDataPayloadKind::U16,
        ),
        (
            DataElement::Value(DataValue::U32(3)),
            NativeWalletExtraDataPayloadKind::U32,
        ),
        (
            DataElement::Value(DataValue::U64(4)),
            NativeWalletExtraDataPayloadKind::U64,
        ),
        (
            DataElement::Value(DataValue::U128(5)),
            NativeWalletExtraDataPayloadKind::U128,
        ),
        (
            DataElement::Value(DataValue::Hash(hash)),
            NativeWalletExtraDataPayloadKind::Hash,
        ),
        (
            DataElement::Value(DataValue::Blob(vec![1, 2])),
            NativeWalletExtraDataPayloadKind::Blob,
        ),
        (
            DataElement::Array(vec![DataElement::Value(DataValue::U8(1))]),
            NativeWalletExtraDataPayloadKind::Array,
        ),
        (
            DataElement::Fields(fields),
            NativeWalletExtraDataPayloadKind::Fields,
        ),
    ];

    for (payload, expected) in cases {
        assert_eq!(extra_data_payload_kind(&payload), expected);
    }
}

#[test]
fn detailed_kind_distinguishes_blob_from_array() {
    let blob = PlaintextExtraData::new(
        None,
        Some(DataElement::Value(DataValue::Blob(vec![1, 2]))),
        PlaintextFlag::Public,
    );
    let array = PlaintextExtraData::new(
        None,
        Some(DataElement::Array(vec![
            DataElement::Value(DataValue::U8(1)),
            DataElement::Value(DataValue::U8(2)),
        ])),
        PlaintextFlag::Public,
    );

    let blob = extra_data(&blob, ExtraDataProjection::Detailed).unwrap();
    let array = extra_data(&array, ExtraDataProjection::Detailed).unwrap();

    assert_ne!(blob.payload, array.payload);
    assert_eq!(
        blob.payload_kind,
        Some(NativeWalletExtraDataPayloadKind::Blob)
    );
    assert_eq!(
        array.payload_kind,
        Some(NativeWalletExtraDataPayloadKind::Array)
    );
}

#[test]
fn detailed_u128_max_payload_remains_lossless() {
    let plaintext = PlaintextExtraData::new(
        None,
        Some(DataElement::Value(DataValue::U128(u128::MAX))),
        PlaintextFlag::Public,
    );

    let detailed = extra_data(&plaintext, ExtraDataProjection::Detailed).unwrap();

    assert!(matches!(
        detailed.payload,
        Some(NativeXelisDataElement::Value {
            value: crate::api::models::address_dtos::NativeXelisDataValue::UnsignedInteger {
                integer_type: crate::api::models::address_dtos::NativeXelisUnsignedIntegerType::U128,
                ref decimal_value,
            }
        }) if decimal_value == "340282366920938463463374607431768211455"
    ));
    assert_eq!(
        detailed.payload_kind,
        Some(NativeWalletExtraDataPayloadKind::U128)
    );
}
