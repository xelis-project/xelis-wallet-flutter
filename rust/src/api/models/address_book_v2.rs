use std::fmt;

use flutter_rust_bridge::frb;

/// Package-owned classification of a stored XELIS destination.
#[derive(Clone, Copy, Eq, PartialEq)]
pub enum NativeSavedDestinationKind {
    Standard,
    Integrated,
}

/// Shape of the data embedded in an integrated address.
///
/// The value itself deliberately never crosses this bridge contract. This is
/// enough for UI labeling and diagnostics without duplicating or exposing the
/// protocol payload stored in the canonical address.
#[derive(Clone, Copy, Eq, PartialEq)]
pub enum NativeIntegratedDataKind {
    BoolValue,
    String,
    U8,
    U16,
    U32,
    U64,
    U128,
    Hash,
    Blob,
    Array,
    Fields,
}

/// Canonical destination owned by one address-book entry.
#[derive(Clone, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeSavedDestination {
    /// Full canonical address. For an integrated address this remains the sole
    /// authoritative value to send or copy.
    pub address: String,
    /// Canonical address for the same public key without integrated data.
    pub base_address: String,
    pub kind: NativeSavedDestinationKind,
    pub integrated_data_kind: Option<NativeIntegratedDataKind>,
}

/// One destination-first address-book record.
#[derive(Clone, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeAddressBookEntry {
    /// Deterministic opaque identifier derived from the canonical full address.
    pub id: String,
    pub display_name: String,
    pub destination_label: Option<String>,
    pub note: Option<String>,
    pub destination: NativeSavedDestination,
}

#[derive(Clone, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeAddressBookPage {
    pub entries: Vec<NativeAddressBookEntry>,
    pub total: u32,
    pub has_more: bool,
}

#[derive(Clone, Copy, Eq, PartialEq)]
pub enum NativeAddressBookMatchKind {
    Exact,
    BaseOnly,
    Ambiguous,
    None,
}

/// Result of matching a standard or integrated address against saved entries.
///
/// `Exact` and `BaseOnly` contain one entry, `Ambiguous` contains at least two
/// entries sharing a base address, and `None` contains no entry.
#[derive(Clone, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeAddressBookMatch {
    pub kind: NativeAddressBookMatchKind,
    pub entries: Vec<NativeAddressBookEntry>,
}

#[derive(Clone, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub struct NativeAddressBookMigrationResult {
    pub migrated_entries: u32,
    pub already_complete: bool,
}

impl fmt::Debug for NativeSavedDestinationKind {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::Standard => "Standard",
            Self::Integrated => "Integrated",
        })
    }
}

impl fmt::Debug for NativeIntegratedDataKind {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::BoolValue => "BoolValue",
            Self::String => "String",
            Self::U8 => "U8",
            Self::U16 => "U16",
            Self::U32 => "U32",
            Self::U64 => "U64",
            Self::U128 => "U128",
            Self::Hash => "Hash",
            Self::Blob => "Blob",
            Self::Array => "Array",
            Self::Fields => "Fields",
        })
    }
}

impl fmt::Debug for NativeSavedDestination {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeSavedDestination")
            .field("address", &"<redacted>")
            .field("base_address", &"<redacted>")
            .field("kind", &self.kind)
            .field("integrated_data_kind", &self.integrated_data_kind)
            .finish()
    }
}

impl fmt::Debug for NativeAddressBookEntry {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeAddressBookEntry")
            .field("id", &"<opaque>")
            .field("display_name", &"<redacted>")
            .field("destination_label", &"<redacted>")
            .field("note", &"<redacted>")
            .field("destination", &self.destination)
            .finish()
    }
}

impl fmt::Debug for NativeAddressBookPage {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeAddressBookPage")
            .field("entries", &format_args!("<{} entries>", self.entries.len()))
            .field("total", &self.total)
            .field("has_more", &self.has_more)
            .finish()
    }
}

impl fmt::Debug for NativeAddressBookMatchKind {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::Exact => "Exact",
            Self::BaseOnly => "BaseOnly",
            Self::Ambiguous => "Ambiguous",
            Self::None => "None",
        })
    }
}

impl fmt::Debug for NativeAddressBookMatch {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeAddressBookMatch")
            .field("kind", &self.kind)
            .field("entries", &format_args!("<{} entries>", self.entries.len()))
            .finish()
    }
}

impl fmt::Debug for NativeAddressBookMigrationResult {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeAddressBookMigrationResult")
            .field("migrated_entries", &self.migrated_entries)
            .field("already_complete", &self.already_complete)
            .finish()
    }
}
