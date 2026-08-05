use flutter_rust_bridge::frb;
use xelis_common::{
    crypto::{Address, AddressType},
    network::Network,
    serializer::Serializer,
    transaction::EXTRA_DATA_LIMIT_SIZE,
};

use super::error::{NativeXelisError, NativeXelisErrorCode};
use super::models::address_dtos::{NativeXelisAddressDescriptor, NativeXelisDataElement};

// Check if the given address is valid
#[frb(sync)]
pub fn is_address_valid(str_address: String, network: Network) -> bool {
    match Address::from_string(&str_address) {
        Ok(address) => match network {
            Network::Mainnet => address.is_mainnet(),
            Network::Testnet => !address.is_mainnet(),
            Network::Devnet => !address.is_mainnet(),
            Network::Stagenet => !address.is_mainnet(),
        },
        Err(_) => false,
    }
}

/// Parse a standard or integrated address into a stable, lossless descriptor.
#[frb(sync)]
pub fn parse_address(address: String) -> Result<NativeXelisAddressDescriptor, NativeXelisError> {
    parse_xelis_address(&address).map(address_descriptor)
}

/// Create an integrated address locally from a normal address and typed data.
///
/// This operation is pure and does not contact a daemon. An already integrated
/// address is rejected so that callers cannot accidentally replace hidden data.
#[frb(sync)]
pub fn make_integrated_address(
    base_address: String,
    integrated_data: NativeXelisDataElement,
) -> Result<NativeXelisAddressDescriptor, NativeXelisError> {
    let base_address = parse_xelis_address(&base_address)?;
    if !base_address.is_normal() {
        return Err(NativeXelisError::xelis_common(
            NativeXelisErrorCode::InvalidInput,
            "ADDRESS_NOT_NORMAL",
            "An integrated address cannot be used as the base of another integrated address",
        ));
    }

    let is_mainnet = base_address.is_mainnet();
    let public_key = base_address.to_public_key();
    let integrated_data = integrated_data.into_xelis()?;
    let serialized_size = integrated_data.size();
    if serialized_size > EXTRA_DATA_LIMIT_SIZE {
        return Err(NativeXelisError::xelis_common(
            NativeXelisErrorCode::InvalidInput,
            "INTEGRATED_ADDRESS_DATA_TOO_LARGE",
            format!(
                "Integrated-address data serializes to {serialized_size} bytes; the protocol limit is {EXTRA_DATA_LIMIT_SIZE}"
            ),
        ));
    }

    Ok(address_descriptor(Address::new(
        is_mainnet,
        AddressType::Data(integrated_data),
        public_key,
    )))
}

fn parse_xelis_address(address: &str) -> Result<Address, NativeXelisError> {
    Address::from_string(address).map_err(|error| {
        NativeXelisError::xelis_common(
            NativeXelisErrorCode::InvalidInput,
            "ADDRESS_INVALID",
            error.to_string(),
        )
    })
}

fn address_descriptor(address: Address) -> NativeXelisAddressDescriptor {
    let encoded_address = address.to_string();
    let is_mainnet = address.is_mainnet();
    let (integrated_data, base_address) = address.extract_data();

    NativeXelisAddressDescriptor {
        encoded_address,
        base_address: base_address.to_string(),
        is_mainnet,
        integrated_data: integrated_data.map(NativeXelisDataElement::from_xelis),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use xelis_common::{
        api::{DataElement, DataValue},
        crypto::{AddressType, KeyPair},
    };

    #[test]
    fn parse_address_describes_standard_and_integrated_addresses() {
        let key_pair = KeyPair::new();
        let base_address = key_pair.get_public_key().to_address(false);
        let base_string = base_address.to_string();

        let standard = parse_address(base_string.clone()).unwrap();
        assert_eq!(standard.encoded_address, base_string);
        assert_eq!(standard.base_address, standard.encoded_address);
        assert!(!standard.is_mainnet);
        assert!(standard.integrated_data.is_none());

        let integrated = Address::new(
            false,
            AddressType::Data(DataElement::Value(DataValue::U128(u128::MAX))),
            key_pair.get_public_key().compress(),
        );
        let integrated_string = integrated.to_string();
        let descriptor = parse_address(integrated_string.clone()).unwrap();

        assert_eq!(descriptor.encoded_address, integrated_string);
        assert_eq!(descriptor.base_address, standard.base_address);
        assert!(matches!(
            descriptor.integrated_data,
            Some(NativeXelisDataElement::Value {
                value: super::super::models::address_dtos::NativeXelisDataValue::UnsignedInteger {
                    integer_type: super::super::models::address_dtos::NativeXelisUnsignedIntegerType::U128,
                    decimal_value,
                }
            }) if decimal_value == u128::MAX.to_string()
        ));
    }

    #[test]
    fn make_integrated_address_round_trips_losslessly() {
        let key_pair = KeyPair::new();
        let base_address = key_pair.get_public_key().to_address(true).to_string();
        let data = NativeXelisDataElement::Fields {
            fields: vec![
                super::super::models::address_dtos::NativeXelisDataField {
                    key: super::super::models::address_dtos::NativeXelisDataValue::StringValue {
                        value: "payment_id".to_owned(),
                    },
                    value: NativeXelisDataElement::Value {
                        value: super::super::models::address_dtos::NativeXelisDataValue::UnsignedInteger {
                            integer_type: super::super::models::address_dtos::NativeXelisUnsignedIntegerType::U64,
                            decimal_value: u64::MAX.to_string(),
                        },
                    },
                },
            ],
        };

        let descriptor = make_integrated_address(base_address.clone(), data.clone()).unwrap();
        assert_eq!(descriptor.base_address, base_address);
        assert!(descriptor.is_mainnet);
        assert_eq!(descriptor.integrated_data, Some(data));

        let reparsed = parse_address(descriptor.encoded_address.clone()).unwrap();
        assert_eq!(reparsed, descriptor);
    }

    #[test]
    fn make_integrated_address_rejects_an_integrated_base() {
        let key_pair = KeyPair::new();
        let integrated = Address::new(
            false,
            AddressType::Data(DataElement::Value(DataValue::Bool(true))),
            key_pair.get_public_key().compress(),
        );

        let error = make_integrated_address(
            integrated.to_string(),
            NativeXelisDataElement::Value {
                value: super::super::models::address_dtos::NativeXelisDataValue::BoolValue {
                    value: false,
                },
            },
        )
        .unwrap_err();

        assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
        assert_eq!(error.native_kind.as_deref(), Some("ADDRESS_NOT_NORMAL"));
    }

    #[test]
    fn make_integrated_address_rejects_data_above_the_protocol_limit() {
        let key_pair = KeyPair::new();
        let base_address = key_pair.get_public_key().to_address(false).to_string();
        let error = make_integrated_address(
            base_address,
            NativeXelisDataElement::Value {
                value: super::super::models::address_dtos::NativeXelisDataValue::BlobValue {
                    bytes: vec![0; EXTRA_DATA_LIMIT_SIZE],
                },
            },
        )
        .unwrap_err();

        assert_eq!(error.code, NativeXelisErrorCode::InvalidInput);
        assert_eq!(
            error.native_kind.as_deref(),
            Some("INTEGRATED_ADDRESS_DATA_TOO_LARGE")
        );
    }

    #[test]
    fn make_integrated_address_accepts_the_exact_protocol_limit() {
        let key_pair = KeyPair::new();
        let base_address = key_pair.get_public_key().to_address(false).to_string();

        // DataElement::Value marker + DataValue::Blob tag + u16 length prefix.
        let payload_length = EXTRA_DATA_LIMIT_SIZE - 4;
        let descriptor = make_integrated_address(
            base_address,
            NativeXelisDataElement::Value {
                value: super::super::models::address_dtos::NativeXelisDataValue::BlobValue {
                    bytes: vec![0; payload_length],
                },
            },
        )
        .unwrap();

        assert!(descriptor.integrated_data.is_some());
        assert!(parse_address(descriptor.encoded_address).is_ok());
    }
}
