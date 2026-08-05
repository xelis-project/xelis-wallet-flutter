/// Classification of a canonical destination stored in the address book.
enum XelisSavedDestinationKind { standard, integrated }

/// Top-level shape of the data encoded in an integrated address.
enum XelisIntegratedDataKind {
  boolValue,
  string,
  u8,
  u16,
  u32,
  u64,
  u128,
  hash,
  blob,
  array,
  fields,
}

/// Canonical destination owned by one address-book entry.
///
/// [address] is always the complete authority for send and copy operations.
/// [baseAddress] exists only for identity lookup and ambiguity detection; it
/// must never replace an integrated [address] during a transfer.
final class XelisSavedDestination {
  const XelisSavedDestination({
    required this.address,
    required this.baseAddress,
    required this.kind,
    required this.integratedDataKind,
  });

  final String address;
  final String baseAddress;
  final XelisSavedDestinationKind kind;
  final XelisIntegratedDataKind? integratedDataKind;

  bool get hasIntegratedData => kind == XelisSavedDestinationKind.integrated;

  @override
  String toString() =>
      'XelisSavedDestination(kind: $kind, '
      'integratedDataKind: $integratedDataKind, address: <redacted>)';
}

/// One destination-first address-book entry.
final class XelisAddressBookEntry {
  const XelisAddressBookEntry({
    required this.id,
    required this.displayName,
    required this.destination,
    this.destinationLabel,
    this.note,
  });

  final String id;
  final String displayName;
  final String? destinationLabel;
  final String? note;
  final XelisSavedDestination destination;

  @override
  String toString() =>
      'XelisAddressBookEntry(id: <opaque>, displayName: <redacted>, '
      'destinationLabel: <redacted>, note: <redacted>, '
      'destination: $destination)';
}

/// One immutable address-book result page.
final class XelisAddressBookPage {
  XelisAddressBookPage({
    required List<XelisAddressBookEntry> entries,
    required this.total,
    required this.hasMore,
  }) : entries = List.unmodifiable(entries);

  final List<XelisAddressBookEntry> entries;
  final int total;
  final bool hasMore;
}

/// Result of the one-time, non-destructive legacy migration.
final class XelisAddressBookMigrationResult {
  const XelisAddressBookMigrationResult({
    required this.migratedEntries,
    required this.alreadyComplete,
  });

  final int migratedEntries;
  final bool alreadyComplete;
}

/// Match between one exact destination and saved address-book entries.
sealed class XelisAddressBookMatch {
  const XelisAddressBookMatch();

  List<XelisAddressBookEntry> get entries;
}

/// Complete address and integrated data match exactly one entry.
final class XelisAddressBookExactMatch extends XelisAddressBookMatch {
  const XelisAddressBookExactMatch(this.entry);

  final XelisAddressBookEntry entry;

  @override
  List<XelisAddressBookEntry> get entries => List.unmodifiable([entry]);
}

/// Only the base address matches one saved destination.
///
/// Consumers may show the contact as a hint but must not silently substitute
/// its full destination for the value being reviewed.
final class XelisAddressBookBaseOnlyMatch extends XelisAddressBookMatch {
  const XelisAddressBookBaseOnlyMatch(this.entry);

  final XelisAddressBookEntry entry;

  @override
  List<XelisAddressBookEntry> get entries => List.unmodifiable([entry]);
}

/// Several saved destinations share the same base address.
///
/// Consumers must display ambiguity and must not guess one entry.
final class XelisAddressBookAmbiguousMatch extends XelisAddressBookMatch {
  XelisAddressBookAmbiguousMatch(List<XelisAddressBookEntry> entries)
    : entries = List.unmodifiable(_requireAmbiguous(entries));

  @override
  final List<XelisAddressBookEntry> entries;

  static List<XelisAddressBookEntry> _requireAmbiguous(
    List<XelisAddressBookEntry> entries,
  ) {
    if (entries.length < 2) {
      throw ArgumentError.value(
        entries,
        'entries',
        'An ambiguous match requires at least two entries.',
      );
    }
    return entries;
  }
}

/// No saved destination matches the full or base address.
final class XelisAddressBookNoMatch extends XelisAddressBookMatch {
  const XelisAddressBookNoMatch();

  @override
  List<XelisAddressBookEntry> get entries => const [];
}
