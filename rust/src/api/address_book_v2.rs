use std::collections::HashMap;

use indexmap::IndexMap;
use xelis_common::{
    api::{DataElement, DataValue},
    crypto::{hash_multiple, Address, AddressType},
};
use xelis_wallet::storage::EncryptedStorage;

use super::{
    error::{NativeXelisError, NativeXelisErrorCode},
    models::{
        address_book_v2::{
            NativeAddressBookEntry, NativeAddressBookMatch, NativeAddressBookMatchKind,
            NativeAddressBookMigrationResult, NativeAddressBookPage, NativeIntegratedDataKind,
            NativeSavedDestination, NativeSavedDestinationKind,
        },
        address_dtos::NativeXelisDataElement,
    },
    wallet::XelisWallet,
};

const LEGACY_TREE: &str = "address_book";
const ADDRESS_BOOK_V2_TREE: &str = "address_book_v2";
const MIGRATION_MARKER_KEY: &str = "_meta:migration_v1_complete";
const ENTRY_KEY_PREFIX: &str = "entry:";
const SCHEMA_VERSION: u8 = 2;
const ENTRY_ID_DOMAIN: &[u8] = b"xelis-wallet-flutter:address-book-entry:v2";
const MAX_ADDRESS_BYTES: usize = 8_192;
const MAX_DISPLAY_NAME_CHARS: usize = 128;
const MAX_DESTINATION_LABEL_CHARS: usize = 128;
const MAX_NOTE_CHARS: usize = 2_048;
const MAX_QUERY_CHARS: usize = 256;
const MAX_PAGE_SIZE: u32 = 500;

#[derive(Clone)]
struct CanonicalDestination {
    address: String,
    base_address: String,
    integrated_data: Option<DataElement>,
    integrated_data_kind: Option<NativeIntegratedDataKind>,
}

impl CanonicalDestination {
    fn to_native(&self) -> NativeSavedDestination {
        NativeSavedDestination {
            address: self.address.clone(),
            base_address: self.base_address.clone(),
            kind: if self.integrated_data.is_some() {
                NativeSavedDestinationKind::Integrated
            } else {
                NativeSavedDestinationKind::Standard
            },
            integrated_data_kind: self.integrated_data_kind,
        }
    }
}

fn address_book_error(
    code: NativeXelisErrorCode,
    native_kind: &'static str,
    diagnostic_message: &'static str,
) -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(code, native_kind, diagnostic_message)
}

fn storage_error(error: anyhow::Error, native_kind: &'static str) -> NativeXelisError {
    NativeXelisError::from_wallet_storage_operation(error, native_kind)
}

fn canonical_destination(
    address: &str,
    expected_mainnet: bool,
) -> Result<CanonicalDestination, NativeXelisError> {
    let address = address.trim();
    if address.is_empty() || address.len() > MAX_ADDRESS_BYTES {
        return Err(address_book_error(
            NativeXelisErrorCode::InvalidInput,
            "ADDRESS_BOOK_ADDRESS_INVALID",
            "Address-book destination is empty or exceeds the supported size",
        ));
    }

    let parsed = Address::from_string(address).map_err(|_| {
        address_book_error(
            NativeXelisErrorCode::InvalidInput,
            "ADDRESS_BOOK_ADDRESS_INVALID",
            "Address-book destination is not a valid XELIS address",
        )
    })?;
    if parsed.is_mainnet() != expected_mainnet {
        return Err(address_book_error(
            NativeXelisErrorCode::NetworkMismatch,
            "ADDRESS_BOOK_ADDRESS_NETWORK_MISMATCH",
            "Address-book destination belongs to a different network",
        ));
    }

    let canonical_address = parsed.to_string();
    let (integrated_data, base) = parsed.extract_data();
    let integrated_data_kind = integrated_data.as_ref().map(data_kind);

    Ok(CanonicalDestination {
        address: canonical_address,
        base_address: base.to_string(),
        integrated_data,
        integrated_data_kind,
    })
}

fn canonical_destination_from_parts(
    base_address: &str,
    integrated_data: Option<NativeXelisDataElement>,
    expected_mainnet: bool,
) -> Result<CanonicalDestination, NativeXelisError> {
    let base = canonical_destination(base_address, expected_mainnet)?;
    if base.integrated_data.is_some() {
        return Err(address_book_error(
            NativeXelisErrorCode::InvalidInput,
            "ADDRESS_BOOK_BASE_ADDRESS_INTEGRATED",
            "Address-book base address must not contain integrated data",
        ));
    }

    let Some(integrated_data) = integrated_data else {
        return Ok(base);
    };
    let integrated_data = integrated_data.into_xelis()?;
    let address = Address::new(
        expected_mainnet,
        AddressType::Data(integrated_data),
        Address::from_string(&base.address)
            .map_err(|_| {
                address_book_error(
                    NativeXelisErrorCode::Internal,
                    "ADDRESS_BOOK_BASE_ADDRESS_INCONSISTENT",
                    "Canonical address-book base address could not be reconstructed",
                )
            })?
            .to_public_key(),
    );
    canonical_destination(&address.to_string(), expected_mainnet)
}

fn data_kind(value: &DataElement) -> NativeIntegratedDataKind {
    match value {
        DataElement::Value(DataValue::Bool(_)) => NativeIntegratedDataKind::BoolValue,
        DataElement::Value(DataValue::String(_)) => NativeIntegratedDataKind::String,
        DataElement::Value(DataValue::U8(_)) => NativeIntegratedDataKind::U8,
        DataElement::Value(DataValue::U16(_)) => NativeIntegratedDataKind::U16,
        DataElement::Value(DataValue::U32(_)) => NativeIntegratedDataKind::U32,
        DataElement::Value(DataValue::U64(_)) => NativeIntegratedDataKind::U64,
        DataElement::Value(DataValue::U128(_)) => NativeIntegratedDataKind::U128,
        DataElement::Value(DataValue::Hash(_)) => NativeIntegratedDataKind::Hash,
        DataElement::Value(DataValue::Blob(_)) => NativeIntegratedDataKind::Blob,
        DataElement::Array(_) => NativeIntegratedDataKind::Array,
        DataElement::Fields(_) => NativeIntegratedDataKind::Fields,
    }
}

fn normalize_required(
    value: String,
    max_chars: usize,
    native_kind: &'static str,
    diagnostic_message: &'static str,
) -> Result<String, NativeXelisError> {
    let value = value.trim().to_owned();
    if value.is_empty() || value.chars().count() > max_chars {
        return Err(address_book_error(
            NativeXelisErrorCode::InvalidInput,
            native_kind,
            diagnostic_message,
        ));
    }
    Ok(value)
}

fn normalize_optional(
    value: Option<String>,
    max_chars: usize,
    native_kind: &'static str,
    diagnostic_message: &'static str,
) -> Result<Option<String>, NativeXelisError> {
    let Some(value) = value else {
        return Ok(None);
    };
    let value = value.trim().to_owned();
    if value.is_empty() {
        return Ok(None);
    }
    if value.chars().count() > max_chars {
        return Err(address_book_error(
            NativeXelisErrorCode::InvalidInput,
            native_kind,
            diagnostic_message,
        ));
    }
    Ok(Some(value))
}

fn entry_id(address: &str) -> String {
    hash_multiple(&[ENTRY_ID_DOMAIN, address.as_bytes()]).to_hex()
}

fn entry_key(id: &str) -> DataValue {
    DataValue::String(format!("{ENTRY_KEY_PREFIX}{id}"))
}

fn validate_entry_id(id: &str) -> Result<(), NativeXelisError> {
    if id.len() != 64
        || !id
            .bytes()
            .all(|value| value.is_ascii_digit() || (b'a'..=b'f').contains(&value))
    {
        return Err(address_book_error(
            NativeXelisErrorCode::InvalidInput,
            "ADDRESS_BOOK_ENTRY_ID_INVALID",
            "Address-book entry identifier is invalid",
        ));
    }
    Ok(())
}

fn normalize_entry(
    address: String,
    display_name: String,
    destination_label: Option<String>,
    note: Option<String>,
    mainnet: bool,
) -> Result<NativeAddressBookEntry, NativeXelisError> {
    let destination = canonical_destination(&address, mainnet)?;
    let display_name = normalize_required(
        display_name,
        MAX_DISPLAY_NAME_CHARS,
        "ADDRESS_BOOK_DISPLAY_NAME_INVALID",
        "Address-book display name is empty or exceeds the supported size",
    )?;
    let destination_label = normalize_optional(
        destination_label,
        MAX_DESTINATION_LABEL_CHARS,
        "ADDRESS_BOOK_DESTINATION_LABEL_INVALID",
        "Address-book destination label exceeds the supported size",
    )?;
    let note = normalize_optional(
        note,
        MAX_NOTE_CHARS,
        "ADDRESS_BOOK_NOTE_INVALID",
        "Address-book note exceeds the supported size",
    )?;

    Ok(NativeAddressBookEntry {
        id: entry_id(&destination.address),
        display_name,
        destination_label,
        note,
        destination: destination.to_native(),
    })
}

fn string_field(
    fields: &IndexMap<DataValue, DataElement>,
    name: &'static str,
    required: bool,
) -> Result<Option<String>, NativeXelisError> {
    let key = DataValue::String(name.to_owned());
    let Some(value) = fields.get(&key) else {
        if required {
            return Err(address_book_error(
                NativeXelisErrorCode::Serialization,
                "ADDRESS_BOOK_ENTRY_SCHEMA_INVALID",
                "Address-book entry is missing a required field",
            ));
        }
        return Ok(None);
    };
    match value {
        DataElement::Value(DataValue::String(value)) => Ok(Some(value.clone())),
        _ => Err(address_book_error(
            NativeXelisErrorCode::Serialization,
            "ADDRESS_BOOK_ENTRY_SCHEMA_INVALID",
            "Address-book entry contains an invalid field type",
        )),
    }
}

fn encode_entry(entry: &NativeAddressBookEntry) -> DataElement {
    let mut fields = IndexMap::new();
    fields.insert(
        DataValue::String("schema_version".to_owned()),
        DataElement::Value(DataValue::U8(SCHEMA_VERSION)),
    );
    fields.insert(
        DataValue::String("id".to_owned()),
        DataElement::Value(DataValue::String(entry.id.clone())),
    );
    fields.insert(
        DataValue::String("display_name".to_owned()),
        DataElement::Value(DataValue::String(entry.display_name.clone())),
    );
    if let Some(value) = &entry.destination_label {
        fields.insert(
            DataValue::String("destination_label".to_owned()),
            DataElement::Value(DataValue::String(value.clone())),
        );
    }
    if let Some(value) = &entry.note {
        fields.insert(
            DataValue::String("note".to_owned()),
            DataElement::Value(DataValue::String(value.clone())),
        );
    }
    fields.insert(
        DataValue::String("address".to_owned()),
        DataElement::Value(DataValue::String(entry.destination.address.clone())),
    );
    DataElement::Fields(fields)
}

fn decode_entry(
    key_id: &str,
    value: DataElement,
    mainnet: bool,
) -> Result<NativeAddressBookEntry, NativeXelisError> {
    let DataElement::Fields(fields) = value else {
        return Err(address_book_error(
            NativeXelisErrorCode::Serialization,
            "ADDRESS_BOOK_ENTRY_SCHEMA_INVALID",
            "Address-book entry is not a fields element",
        ));
    };
    match fields.get(&DataValue::String("schema_version".to_owned())) {
        Some(DataElement::Value(DataValue::U8(SCHEMA_VERSION))) => {}
        _ => {
            return Err(address_book_error(
                NativeXelisErrorCode::Unsupported,
                "ADDRESS_BOOK_SCHEMA_VERSION_UNSUPPORTED",
                "Address-book entry schema version is unsupported",
            ));
        }
    }

    let stored_id = string_field(&fields, "id", true)?.expect("required field checked");
    let display_name =
        string_field(&fields, "display_name", true)?.expect("required field checked");
    let address = string_field(&fields, "address", true)?.expect("required field checked");
    let destination_label = string_field(&fields, "destination_label", false)?;
    let note = string_field(&fields, "note", false)?;
    let normalized = normalize_entry(address, display_name, destination_label, note, mainnet)?;

    if stored_id != key_id || normalized.id != key_id {
        return Err(address_book_error(
            NativeXelisErrorCode::Serialization,
            "ADDRESS_BOOK_ENTRY_ID_MISMATCH",
            "Address-book entry identifier does not match its canonical destination",
        ));
    }
    Ok(normalized)
}

fn encode_marker(migrated_entries: u32) -> DataElement {
    DataElement::Fields(IndexMap::from([
        (
            DataValue::String("schema_version".to_owned()),
            DataElement::Value(DataValue::U8(SCHEMA_VERSION)),
        ),
        (
            DataValue::String("migrated_entries".to_owned()),
            DataElement::Value(DataValue::U32(migrated_entries)),
        ),
    ]))
}

fn decode_marker(value: DataElement) -> Result<u32, NativeXelisError> {
    let DataElement::Fields(fields) = value else {
        return Err(address_book_error(
            NativeXelisErrorCode::Serialization,
            "ADDRESS_BOOK_MIGRATION_MARKER_INVALID",
            "Address-book migration marker is invalid",
        ));
    };
    match (
        fields.get(&DataValue::String("schema_version".to_owned())),
        fields.get(&DataValue::String("migrated_entries".to_owned())),
    ) {
        (
            Some(DataElement::Value(DataValue::U8(SCHEMA_VERSION))),
            Some(DataElement::Value(DataValue::U32(count))),
        ) => Ok(*count),
        _ => Err(address_book_error(
            NativeXelisErrorCode::Serialization,
            "ADDRESS_BOOK_MIGRATION_MARKER_INVALID",
            "Address-book migration marker is invalid",
        )),
    }
}

fn read_v2_entries(
    storage: &EncryptedStorage,
    mainnet: bool,
) -> Result<Vec<NativeAddressBookEntry>, NativeXelisError> {
    let values = storage
        .query_db(ADDRESS_BOOK_V2_TREE, None, None, None, None)
        .map_err(|error| storage_error(error, "ADDRESS_BOOK_LIST_FAILED"))?;
    let mut entries = Vec::new();
    for (key, value) in values.entries {
        let DataValue::String(key) = key else {
            return Err(address_book_error(
                NativeXelisErrorCode::Serialization,
                "ADDRESS_BOOK_ENTRY_KEY_INVALID",
                "Address-book v2 contains an invalid key",
            ));
        };
        if key == MIGRATION_MARKER_KEY {
            continue;
        }
        let Some(id) = key.strip_prefix(ENTRY_KEY_PREFIX) else {
            return Err(address_book_error(
                NativeXelisErrorCode::Serialization,
                "ADDRESS_BOOK_ENTRY_KEY_INVALID",
                "Address-book v2 contains an unknown key",
            ));
        };
        validate_entry_id(id)?;
        entries.push(decode_entry(id, value, mainnet)?);
    }
    entries.sort_by(|left, right| {
        left.display_name
            .to_lowercase()
            .cmp(&right.display_name.to_lowercase())
            .then_with(|| left.id.cmp(&right.id))
    });
    Ok(entries)
}

fn match_destination(
    entries: Vec<NativeAddressBookEntry>,
    destination: &CanonicalDestination,
) -> NativeAddressBookMatch {
    if let Some(entry) = entries
        .iter()
        .find(|entry| entry.destination.address == destination.address)
        .cloned()
    {
        return NativeAddressBookMatch {
            kind: NativeAddressBookMatchKind::Exact,
            entries: vec![entry],
        };
    }

    let base_matches = entries
        .into_iter()
        .filter(|entry| entry.destination.base_address == destination.base_address)
        .collect::<Vec<_>>();
    let kind = match base_matches.len() {
        0 => NativeAddressBookMatchKind::None,
        1 => NativeAddressBookMatchKind::BaseOnly,
        _ => NativeAddressBookMatchKind::Ambiguous,
    };
    NativeAddressBookMatch {
        kind,
        entries: base_matches,
    }
}

impl XelisWallet {
    pub async fn migrate_address_book_v2(
        &self,
    ) -> Result<NativeAddressBookMigrationResult, NativeXelisError> {
        let mainnet = self.get_wallet().get_network().is_mainnet();
        let mut storage = self.get_wallet().get_storage().write().await;
        let marker_key = DataValue::String(MIGRATION_MARKER_KEY.to_owned());
        if storage
            .has_custom_data(ADDRESS_BOOK_V2_TREE, &marker_key)
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_MIGRATION_MARKER_READ_FAILED"))?
        {
            let count = storage
                .get_custom_data(ADDRESS_BOOK_V2_TREE, &marker_key)
                .map_err(|error| storage_error(error, "ADDRESS_BOOK_MIGRATION_MARKER_READ_FAILED"))
                .and_then(decode_marker)?;
            return Ok(NativeAddressBookMigrationResult {
                migrated_entries: count,
                already_complete: true,
            });
        }

        let legacy = storage
            .query_db(LEGACY_TREE, None, None, None, None)
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_MIGRATION_LEGACY_READ_FAILED"))?;
        let mut migrated = HashMap::<String, NativeAddressBookEntry>::new();
        for (key, value) in legacy.entries {
            let DataValue::String(key_address) = key else {
                return Err(address_book_error(
                    NativeXelisErrorCode::Serialization,
                    "ADDRESS_BOOK_LEGACY_KEY_INVALID",
                    "Legacy address-book entry contains an invalid key",
                ));
            };
            let DataElement::Fields(fields) = value else {
                return Err(address_book_error(
                    NativeXelisErrorCode::Serialization,
                    "ADDRESS_BOOK_LEGACY_ENTRY_INVALID",
                    "Legacy address-book entry has an invalid schema",
                ));
            };
            let display_name =
                string_field(&fields, "name", true)?.expect("required field checked");
            let field_address =
                string_field(&fields, "address", true)?.expect("required field checked");
            let note = string_field(&fields, "note", false)?;
            let canonical_key = canonical_destination(&key_address, mainnet)?;
            let entry = normalize_entry(field_address, display_name, None, note, mainnet)?;
            if entry.destination.address != canonical_key.address {
                return Err(address_book_error(
                    NativeXelisErrorCode::Serialization,
                    "ADDRESS_BOOK_LEGACY_ADDRESS_MISMATCH",
                    "Legacy address-book key and stored destination do not match",
                ));
            }
            if let Some(previous) = migrated.insert(entry.id.clone(), entry.clone()) {
                if previous != entry {
                    return Err(address_book_error(
                        NativeXelisErrorCode::Conflict,
                        "ADDRESS_BOOK_MIGRATION_DUPLICATE",
                        "Legacy address-book entries conflict after canonicalization",
                    ));
                }
            }
        }

        for entry in migrated.values() {
            let key = entry_key(&entry.id);
            if storage
                .has_custom_data(ADDRESS_BOOK_V2_TREE, &key)
                .map_err(|error| storage_error(error, "ADDRESS_BOOK_MIGRATION_ENTRY_READ_FAILED"))?
            {
                let existing = storage
                    .get_custom_data(ADDRESS_BOOK_V2_TREE, &key)
                    .map_err(|error| {
                        storage_error(error, "ADDRESS_BOOK_MIGRATION_ENTRY_READ_FAILED")
                    })
                    .and_then(|value| decode_entry(&entry.id, value, mainnet))?;
                if existing != *entry {
                    return Err(address_book_error(
                        NativeXelisErrorCode::Conflict,
                        "ADDRESS_BOOK_MIGRATION_ENTRY_CONFLICT",
                        "Existing address-book v2 entry conflicts with legacy data",
                    ));
                }
            } else {
                storage
                    .set_custom_data(ADDRESS_BOOK_V2_TREE, &key, &encode_entry(entry))
                    .map_err(|error| {
                        storage_error(error, "ADDRESS_BOOK_MIGRATION_ENTRY_WRITE_FAILED")
                    })?;
            }
        }

        let migrated_entries = u32::try_from(migrated.len()).map_err(|_| {
            address_book_error(
                NativeXelisErrorCode::Internal,
                "ADDRESS_BOOK_ENTRY_COUNT_OVERFLOW",
                "Address-book entry count exceeds the supported range",
            )
        })?;
        storage
            .set_custom_data(
                ADDRESS_BOOK_V2_TREE,
                &marker_key,
                &encode_marker(migrated_entries),
            )
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_MIGRATION_MARKER_WRITE_FAILED"))?;

        Ok(NativeAddressBookMigrationResult {
            migrated_entries,
            already_complete: false,
        })
    }

    pub async fn list_address_book_entries_v2(
        &self,
        query: Option<String>,
        skip: u32,
        take: Option<u32>,
    ) -> Result<NativeAddressBookPage, NativeXelisError> {
        self.migrate_address_book_v2().await?;
        if take.is_some_and(|value| value == 0 || value > MAX_PAGE_SIZE) {
            return Err(address_book_error(
                NativeXelisErrorCode::InvalidInput,
                "ADDRESS_BOOK_PAGE_SIZE_INVALID",
                "Address-book page size is outside the supported range",
            ));
        }
        let query = normalize_optional(
            query,
            MAX_QUERY_CHARS,
            "ADDRESS_BOOK_QUERY_INVALID",
            "Address-book query exceeds the supported size",
        )?
        .map(|value| value.to_lowercase());
        let storage = self.get_wallet().get_storage().read().await;
        let mut entries = read_v2_entries(&storage, self.get_wallet().get_network().is_mainnet())?;
        if let Some(query) = query {
            entries.retain(|entry| {
                entry.display_name.to_lowercase().contains(&query)
                    || entry
                        .destination_label
                        .as_ref()
                        .is_some_and(|value| value.to_lowercase().contains(&query))
                    || entry.destination.address.to_lowercase().contains(&query)
            });
        }
        let total = u32::try_from(entries.len()).map_err(|_| {
            address_book_error(
                NativeXelisErrorCode::Internal,
                "ADDRESS_BOOK_ENTRY_COUNT_OVERFLOW",
                "Address-book entry count exceeds the supported range",
            )
        })?;
        let skip = usize::try_from(skip).map_err(|_| {
            address_book_error(
                NativeXelisErrorCode::InvalidInput,
                "ADDRESS_BOOK_PAGE_OFFSET_INVALID",
                "Address-book page offset exceeds the supported range",
            )
        })?;
        let take = take.map(|value| value as usize);
        let page: Vec<NativeAddressBookEntry> = match take {
            Some(take) => entries.into_iter().skip(skip).take(take).collect(),
            None => entries.into_iter().skip(skip).collect(),
        };
        let returned = u32::try_from(page.len()).unwrap_or(u32::MAX);
        let has_more = skip
            .checked_add(returned as usize)
            .is_some_and(|value| value < total as usize);

        Ok(NativeAddressBookPage {
            entries: page,
            total,
            has_more,
        })
    }

    pub async fn upsert_address_book_entry_v2(
        &self,
        address: String,
        display_name: String,
        destination_label: Option<String>,
        note: Option<String>,
    ) -> Result<NativeAddressBookEntry, NativeXelisError> {
        self.migrate_address_book_v2().await?;
        let entry = normalize_entry(
            address,
            display_name,
            destination_label,
            note,
            self.get_wallet().get_network().is_mainnet(),
        )?;
        self.get_wallet()
            .get_storage()
            .write()
            .await
            .set_custom_data(
                ADDRESS_BOOK_V2_TREE,
                &entry_key(&entry.id),
                &encode_entry(&entry),
            )
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_ENTRY_WRITE_FAILED"))?;
        Ok(entry)
    }

    pub async fn remove_address_book_entry_v2(
        &self,
        entry_id: String,
    ) -> Result<(), NativeXelisError> {
        self.migrate_address_book_v2().await?;
        validate_entry_id(&entry_id)?;
        let key = entry_key(&entry_id);
        let mut storage = self.get_wallet().get_storage().write().await;
        if !storage
            .has_custom_data(ADDRESS_BOOK_V2_TREE, &key)
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_ENTRY_READ_FAILED"))?
        {
            return Err(address_book_error(
                NativeXelisErrorCode::NotFound,
                "ADDRESS_BOOK_ENTRY_NOT_FOUND",
                "Address-book entry was not found",
            ));
        }
        storage
            .delete_custom_data(ADDRESS_BOOK_V2_TREE, &key)
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_ENTRY_DELETE_FAILED"))
    }

    pub async fn find_address_book_entry_v2(
        &self,
        entry_id: String,
    ) -> Result<NativeAddressBookEntry, NativeXelisError> {
        self.migrate_address_book_v2().await?;
        validate_entry_id(&entry_id)?;
        let storage = self.get_wallet().get_storage().read().await;
        let key = entry_key(&entry_id);
        if !storage
            .has_custom_data(ADDRESS_BOOK_V2_TREE, &key)
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_ENTRY_READ_FAILED"))?
        {
            return Err(address_book_error(
                NativeXelisErrorCode::NotFound,
                "ADDRESS_BOOK_ENTRY_NOT_FOUND",
                "Address-book entry was not found",
            ));
        }
        let value = storage
            .get_custom_data(ADDRESS_BOOK_V2_TREE, &key)
            .map_err(|error| storage_error(error, "ADDRESS_BOOK_ENTRY_READ_FAILED"))?;
        decode_entry(
            &entry_id,
            value,
            self.get_wallet().get_network().is_mainnet(),
        )
    }

    pub async fn match_address_book_address_v2(
        &self,
        address: String,
    ) -> Result<NativeAddressBookMatch, NativeXelisError> {
        self.migrate_address_book_v2().await?;
        let mainnet = self.get_wallet().get_network().is_mainnet();
        let destination = canonical_destination(&address, mainnet)?;
        let storage = self.get_wallet().get_storage().read().await;
        Ok(match_destination(
            read_v2_entries(&storage, mainnet)?,
            &destination,
        ))
    }

    pub async fn match_address_book_destination_v2(
        &self,
        base_address: String,
        integrated_data: Option<NativeXelisDataElement>,
    ) -> Result<NativeAddressBookMatch, NativeXelisError> {
        self.migrate_address_book_v2().await?;
        let mainnet = self.get_wallet().get_network().is_mainnet();
        let destination =
            canonical_destination_from_parts(&base_address, integrated_data, mainnet)?;
        let storage = self.get_wallet().get_storage().read().await;
        Ok(match_destination(
            read_v2_entries(&storage, mainnet)?,
            &destination,
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use xelis_common::crypto::KeyPair;

    fn address_with_data(data: Option<DataElement>) -> Address {
        let key_pair = KeyPair::new();
        Address::new(
            false,
            data.map(AddressType::Data).unwrap_or(AddressType::Normal),
            key_pair.get_public_key().compress(),
        )
    }

    #[test]
    fn entry_codec_preserves_full_integrated_destination() {
        let address = address_with_data(Some(DataElement::Value(DataValue::U64(42))));
        let entry = normalize_entry(
            address.to_string(),
            "Exchange".to_owned(),
            Some("Deposit 42".to_owned()),
            Some("Reusable destination".to_owned()),
            false,
        )
        .unwrap();
        let decoded = decode_entry(&entry.id, encode_entry(&entry), false).unwrap();

        assert_eq!(decoded, entry);
        assert_eq!(
            decoded.destination.kind,
            NativeSavedDestinationKind::Integrated
        );
        assert_eq!(
            decoded.destination.integrated_data_kind,
            Some(NativeIntegratedDataKind::U64)
        );
        assert_ne!(
            decoded.destination.address,
            decoded.destination.base_address
        );
    }

    #[test]
    fn matching_is_exact_before_base_only_or_ambiguous() {
        let key_pair = KeyPair::new();
        let base = key_pair.get_public_key().to_address(false);
        let first = Address::new(
            false,
            AddressType::Data(DataElement::Value(DataValue::String("first".to_owned()))),
            key_pair.get_public_key().compress(),
        );
        let second = Address::new(
            false,
            AddressType::Data(DataElement::Value(DataValue::String("second".to_owned()))),
            key_pair.get_public_key().compress(),
        );
        let first_entry = normalize_entry(
            first.to_string(),
            "Exchange".to_owned(),
            Some("First".to_owned()),
            None,
            false,
        )
        .unwrap();
        let second_entry = normalize_entry(
            second.to_string(),
            "Exchange".to_owned(),
            Some("Second".to_owned()),
            None,
            false,
        )
        .unwrap();
        assert_ne!(first_entry.id, second_entry.id);
        assert_eq!(
            first_entry.destination.base_address,
            second_entry.destination.base_address
        );

        let exact = match_destination(
            vec![first_entry.clone(), second_entry.clone()],
            &canonical_destination(&first.to_string(), false).unwrap(),
        );
        assert_eq!(exact.kind, NativeAddressBookMatchKind::Exact);
        assert_eq!(exact.entries, vec![first_entry.clone()]);

        let ambiguous = match_destination(
            vec![first_entry.clone(), second_entry],
            &canonical_destination(&base.to_string(), false).unwrap(),
        );
        assert_eq!(ambiguous.kind, NativeAddressBookMatchKind::Ambiguous);
        assert_eq!(ambiguous.entries.len(), 2);

        let base_only = match_destination(
            vec![first_entry.clone()],
            &canonical_destination(&base.to_string(), false).unwrap(),
        );
        assert_eq!(base_only.kind, NativeAddressBookMatchKind::BaseOnly);
        assert_eq!(base_only.entries, vec![first_entry]);
    }

    #[test]
    fn typed_destination_parts_reconstruct_the_exact_integrated_address() {
        let key_pair = KeyPair::new();
        let base = key_pair.get_public_key().to_address(false);
        let data = DataElement::Array(vec![
            DataElement::Value(DataValue::U8(7)),
            DataElement::Value(DataValue::String("memo".to_owned())),
        ]);
        let integrated = Address::new(
            false,
            AddressType::Data(data.clone()),
            key_pair.get_public_key().compress(),
        );
        let reconstructed = canonical_destination_from_parts(
            &base.to_string(),
            Some(NativeXelisDataElement::from_xelis(data)),
            false,
        )
        .unwrap();

        assert_eq!(reconstructed.address, integrated.to_string());
        assert_eq!(reconstructed.base_address, base.to_string());
    }

    #[test]
    fn validation_rejects_wrong_network_and_invalid_marker() {
        let mainnet_address = KeyPair::new().get_public_key().to_address(true);
        let error = match canonical_destination(&mainnet_address.to_string(), false) {
            Err(error) => error,
            Ok(_) => panic!("wrong-network destination should fail"),
        };
        assert_eq!(error.code, NativeXelisErrorCode::NetworkMismatch);
        assert_eq!(
            error.native_kind.as_deref(),
            Some("ADDRESS_BOOK_ADDRESS_NETWORK_MISMATCH")
        );

        let marker_error = decode_marker(DataElement::Value(DataValue::U8(2))).unwrap_err();
        assert_eq!(marker_error.code, NativeXelisErrorCode::Serialization);
    }
}
