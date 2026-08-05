use std::str::FromStr;

use flutter_rust_bridge::frb;
use indexmap::IndexMap;
use xelis_common::{
    api::{DataElement, DataValue},
    crypto::Hash,
};

use crate::api::error::{NativeXelisError, NativeXelisErrorCode};

const DATA_ELEMENT_COLLECTION_LIMIT: usize = u8::MAX as usize;
const DATA_ELEMENT_BLOB_LIMIT: usize = u16::MAX as usize;

/// Lossless native projection of a parsed XELIS address.
///
/// `encoded_address` preserves the complete address supplied to a transaction,
/// while `base_address` is the normal address for the same public key.
#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeXelisAddressDescriptor {
    pub encoded_address: String,
    pub base_address: String,
    pub is_mainnet: bool,
    pub integrated_data: Option<NativeXelisDataElement>,
}

/// Explicit tagged wire for `xelis_common::api::DataElement`.
///
/// The upstream JSON representation is deliberately untagged and therefore
/// cannot preserve the exact integer width or distinguish every value shape.
#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub enum NativeXelisDataElement {
    Value { value: NativeXelisDataValue },
    Array { values: Vec<NativeXelisDataElement> },
    Fields { fields: Vec<NativeXelisDataField> },
}

/// Ordered key/value entry used by the `Fields` data-element variant.
///
/// A list is intentional: XELIS accepts non-string keys and preserves field
/// insertion order, which a JSON object cannot represent losslessly.
#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeXelisDataField {
    pub key: NativeXelisDataValue,
    pub value: NativeXelisDataElement,
}

/// Width of an unsigned integer in the XELIS data-element protocol.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NativeXelisUnsignedIntegerType {
    U8,
    U16,
    U32,
    U64,
    U128,
}

/// Explicit tagged wire for `xelis_common::api::DataValue`.
///
/// Unsigned integers use canonical base-10 strings to preserve `u128` exactly
/// on native and Web targets alike.
#[derive(Clone, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub enum NativeXelisDataValue {
    BoolValue {
        value: bool,
    },
    StringValue {
        value: String,
    },
    UnsignedInteger {
        integer_type: NativeXelisUnsignedIntegerType,
        decimal_value: String,
    },
    HashValue {
        hex_value: String,
    },
    BlobValue {
        bytes: Vec<u8>,
    },
}

impl NativeXelisDataElement {
    pub(crate) fn from_xelis(value: DataElement) -> Self {
        match value {
            DataElement::Value(value) => Self::Value {
                value: NativeXelisDataValue::from_xelis(value),
            },
            DataElement::Array(values) => Self::Array {
                values: values.into_iter().map(Self::from_xelis).collect(),
            },
            DataElement::Fields(fields) => Self::Fields {
                fields: fields
                    .into_iter()
                    .map(|(key, value)| NativeXelisDataField {
                        key: NativeXelisDataValue::from_xelis(key),
                        value: Self::from_xelis(value),
                    })
                    .collect(),
            },
        }
    }

    pub(crate) fn into_xelis(self) -> Result<DataElement, NativeXelisError> {
        match self {
            Self::Value { value } => Ok(DataElement::Value(value.into_xelis()?)),
            Self::Array { values } => {
                ensure_collection_limit(values.len(), "array")?;
                values
                    .into_iter()
                    .map(Self::into_xelis)
                    .collect::<Result<Vec<_>, _>>()
                    .map(DataElement::Array)
            }
            Self::Fields { fields } => {
                ensure_collection_limit(fields.len(), "fields")?;

                let mut converted = IndexMap::with_capacity(fields.len());
                for field in fields {
                    let key = field.key.into_xelis()?;
                    if converted.contains_key(&key) {
                        return Err(NativeXelisError::xelis_wallet_flutter(
                            NativeXelisErrorCode::InvalidInput,
                            "DATA_ELEMENT_FIELD_DUPLICATE",
                            "Data-element fields contain a duplicate key",
                        ));
                    }

                    converted.insert(key, field.value.into_xelis()?);
                }

                Ok(DataElement::Fields(converted))
            }
        }
    }
}

impl NativeXelisDataValue {
    fn from_xelis(value: DataValue) -> Self {
        match value {
            DataValue::Bool(value) => Self::BoolValue { value },
            DataValue::String(value) => Self::StringValue { value },
            DataValue::U8(value) => Self::unsigned(NativeXelisUnsignedIntegerType::U8, value),
            DataValue::U16(value) => Self::unsigned(NativeXelisUnsignedIntegerType::U16, value),
            DataValue::U32(value) => Self::unsigned(NativeXelisUnsignedIntegerType::U32, value),
            DataValue::U64(value) => Self::unsigned(NativeXelisUnsignedIntegerType::U64, value),
            DataValue::U128(value) => Self::unsigned(NativeXelisUnsignedIntegerType::U128, value),
            DataValue::Hash(value) => Self::HashValue {
                hex_value: value.to_hex(),
            },
            DataValue::Blob(bytes) => Self::BlobValue { bytes },
        }
    }

    fn unsigned(integer_type: NativeXelisUnsignedIntegerType, value: impl ToString) -> Self {
        Self::UnsignedInteger {
            integer_type,
            decimal_value: value.to_string(),
        }
    }

    fn into_xelis(self) -> Result<DataValue, NativeXelisError> {
        match self {
            Self::BoolValue { value } => Ok(DataValue::Bool(value)),
            Self::StringValue { value } => Ok(DataValue::String(value)),
            Self::UnsignedInteger {
                integer_type,
                decimal_value,
            } => parse_unsigned(integer_type, &decimal_value),
            Self::HashValue { hex_value } => Hash::from_str(&hex_value)
                .map(DataValue::Hash)
                .map_err(|error| {
                    NativeXelisError::xelis_wallet_flutter(
                        NativeXelisErrorCode::InvalidInput,
                        "DATA_ELEMENT_HASH_INVALID",
                        error,
                    )
                }),
            Self::BlobValue { bytes } => {
                if bytes.len() > DATA_ELEMENT_BLOB_LIMIT {
                    return Err(NativeXelisError::xelis_wallet_flutter(
                        NativeXelisErrorCode::InvalidInput,
                        "DATA_ELEMENT_BLOB_TOO_LARGE",
                        format!(
                            "Data-element blob contains {} bytes; the protocol limit is {}",
                            bytes.len(),
                            DATA_ELEMENT_BLOB_LIMIT
                        ),
                    ));
                }

                Ok(DataValue::Blob(bytes))
            }
        }
    }
}

fn ensure_collection_limit(length: usize, collection: &str) -> Result<(), NativeXelisError> {
    if length > DATA_ELEMENT_COLLECTION_LIMIT {
        return Err(NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "DATA_ELEMENT_COLLECTION_TOO_LARGE",
            format!(
                "Data-element {collection} contains {length} entries; the protocol limit is {DATA_ELEMENT_COLLECTION_LIMIT}"
            ),
        ));
    }

    Ok(())
}

fn parse_unsigned(
    integer_type: NativeXelisUnsignedIntegerType,
    decimal_value: &str,
) -> Result<DataValue, NativeXelisError> {
    fn parse<T>(decimal_value: &str) -> Result<T, NativeXelisError>
    where
        T: FromStr + ToString,
    {
        let value = decimal_value.parse::<T>().map_err(|_| {
            NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "DATA_ELEMENT_UNSIGNED_INVALID",
                "Data-element unsigned integer is invalid or outside its declared width",
            )
        })?;

        if value.to_string() != decimal_value {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "DATA_ELEMENT_UNSIGNED_NON_CANONICAL",
                "Data-element unsigned integer must use canonical base-10 notation",
            ));
        }

        Ok(value)
    }

    match integer_type {
        NativeXelisUnsignedIntegerType::U8 => parse(decimal_value).map(DataValue::U8),
        NativeXelisUnsignedIntegerType::U16 => parse(decimal_value).map(DataValue::U16),
        NativeXelisUnsignedIntegerType::U32 => parse(decimal_value).map(DataValue::U32),
        NativeXelisUnsignedIntegerType::U64 => parse(decimal_value).map(DataValue::U64),
        NativeXelisUnsignedIntegerType::U128 => parse(decimal_value).map(DataValue::U128),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_preserves_all_value_types_and_field_order() {
        let max_u128 = u128::MAX.to_string();
        let wire = NativeXelisDataElement::Fields {
            fields: vec![
                NativeXelisDataField {
                    key: NativeXelisDataValue::StringValue {
                        value: "payment_id".to_owned(),
                    },
                    value: NativeXelisDataElement::Value {
                        value: NativeXelisDataValue::UnsignedInteger {
                            integer_type: NativeXelisUnsignedIntegerType::U128,
                            decimal_value: max_u128,
                        },
                    },
                },
                NativeXelisDataField {
                    key: NativeXelisDataValue::UnsignedInteger {
                        integer_type: NativeXelisUnsignedIntegerType::U8,
                        decimal_value: "7".to_owned(),
                    },
                    value: NativeXelisDataElement::Array {
                        values: vec![
                            NativeXelisDataElement::Value {
                                value: NativeXelisDataValue::BoolValue { value: true },
                            },
                            NativeXelisDataElement::Value {
                                value: NativeXelisDataValue::HashValue {
                                    hex_value: Hash::zero().to_hex(),
                                },
                            },
                            NativeXelisDataElement::Value {
                                value: NativeXelisDataValue::BlobValue {
                                    bytes: vec![0, 1, 255],
                                },
                            },
                        ],
                    },
                },
            ],
        };

        let xelis = wire.clone().into_xelis().unwrap();
        assert_eq!(NativeXelisDataElement::from_xelis(xelis), wire);
    }

    #[test]
    fn rejects_non_canonical_and_out_of_range_unsigned_values() {
        let non_canonical = NativeXelisDataValue::UnsignedInteger {
            integer_type: NativeXelisUnsignedIntegerType::U8,
            decimal_value: "01".to_owned(),
        }
        .into_xelis()
        .unwrap_err();
        assert_eq!(
            non_canonical.native_kind.as_deref(),
            Some("DATA_ELEMENT_UNSIGNED_NON_CANONICAL")
        );

        let out_of_range = NativeXelisDataValue::UnsignedInteger {
            integer_type: NativeXelisUnsignedIntegerType::U8,
            decimal_value: "256".to_owned(),
        }
        .into_xelis()
        .unwrap_err();
        assert_eq!(
            out_of_range.native_kind.as_deref(),
            Some("DATA_ELEMENT_UNSIGNED_INVALID")
        );
    }

    #[test]
    fn rejects_duplicate_fields_and_oversized_collections() {
        let duplicate_key = NativeXelisDataValue::StringValue {
            value: "id".to_owned(),
        };
        let value = NativeXelisDataElement::Value {
            value: NativeXelisDataValue::BoolValue { value: true },
        };
        let duplicate = NativeXelisDataElement::Fields {
            fields: vec![
                NativeXelisDataField {
                    key: duplicate_key.clone(),
                    value: value.clone(),
                },
                NativeXelisDataField {
                    key: duplicate_key,
                    value,
                },
            ],
        }
        .into_xelis()
        .unwrap_err();
        assert_eq!(
            duplicate.native_kind.as_deref(),
            Some("DATA_ELEMENT_FIELD_DUPLICATE")
        );

        let oversized = NativeXelisDataElement::Array {
            values: vec![
                NativeXelisDataElement::Value {
                    value: NativeXelisDataValue::BoolValue { value: false },
                };
                DATA_ELEMENT_COLLECTION_LIMIT + 1
            ],
        }
        .into_xelis()
        .unwrap_err();
        assert_eq!(
            oversized.native_kind.as_deref(),
            Some("DATA_ELEMENT_COLLECTION_TOO_LARGE")
        );
    }
}
