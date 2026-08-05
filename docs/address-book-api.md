# Address book API

This guide is for Flutter applications that store, list, and match reusable
XELIS destinations through an opened `XelisWallet`. The address book accepts
complete standard and integrated addresses; its custom tree is encrypted with
that wallet's storage.

## Destination invariant

`XelisAddressBookEntry.destination.address` is the complete canonical value and
is the only authority for send and copy operations. For an integrated address,
`baseAddress` identifies the same public key but deliberately omits data. Use it
only for grouping or ambiguity detection.

Several entries may share one base address. This is required for exchange
deposit addresses where each customer or account receives different integrated
data. Entries are keyed by a deterministic opaque ID derived from the complete
canonical address, not by the base address.

```dart
final saved = await wallet.upsertAddressBookEntry(
  address: exchangeIntegratedAddress,
  displayName: 'Exchange',
  destinationLabel: 'Trading account',
);

await send(destination: saved.destination.address);
```

`destinationLabel` describes one destination under a person or service. `note`
is application-owned local context. Neither should be written to ordinary logs.

## Legacy migration

Every v2 operation first calls the idempotent migration. Applications may call
`migrateAddressBook()` explicitly to show migration progress, but normally do
not need to.

The migration:

1. reads every entry from the legacy encrypted `address_book` tree;
2. validates the key, stored address, network, and fields;
3. writes canonical entries into the separate `address_book_v2` tree;
4. writes a completion marker only after every entry succeeds.

It never changes or deletes the legacy tree. If execution stops after some v2
entries were written, the next run verifies and reuses identical entries before
continuing. Conflicting, corrupt, or network-mismatched legacy values fail with
a structured error instead of being skipped or overwritten.

The completion marker establishes a cutover for that wallet file: later v2
writes are authoritative and are not mirrored back to the legacy tree.

## Matching

`matchAddressBookAddress(address:)` canonicalizes a complete standard or
integrated address. `matchAddressBookDestination(baseAddress:integratedData:)`
supports transaction history, where XELIS stores the base destination and
decrypted extra data separately.

Both return one exhaustive result:

- `XelisAddressBookExactMatch`: complete address and typed data match;
- `XelisAddressBookBaseOnlyMatch`: only one saved entry shares the base;
- `XelisAddressBookAmbiguousMatch`: two or more entries share the base;
- `XelisAddressBookNoMatch`: no saved destination shares it.

Only `ExactMatch` is a certain destination identity. A UI may display a
`BaseOnlyMatch` as a hint, but it must not substitute that entry's full address.
An ambiguous result must never be resolved by list order.

For history, load detailed extra data by transaction hash only when the detail
screen is opened, then pass its lossless `XelisDataElement` payload to
`matchAddressBookDestination`. A failed or unavailable payload cannot produce
an exact integrated-address match.

Filtering a contact's complete history is a separate native operation. Parse
the saved full address and pass the resulting descriptor to
`XelisWalletHistoryFilter.destination`. Rust then compares the base and exact
protocol data before pagination without returning that data to the list:

```dart
final destination = XelisWalletFlutter.parseAddress(
  address: saved.destination.address,
);
final filter = XelisWalletHistoryFilter(
  page: BigInt.one,
  destination: destination,
);
```

Never build this filter from `baseAddress`; doing so intentionally changes the
request to base/counterparty semantics and can mix several saved destinations.

## Listing and pagination

`addressBookEntries()` returns immutable pages sorted by display name and then
opaque entry ID. `skip` is zero-based. `take`, when present, is between 1 and
500. Search is case-insensitive across display name, destination label, and the
complete address. A page exposes `total` and `hasMore`; consumers must retain
entry identity by `id`, not by list position or base address.

## UI vocabulary

The recommended user model is:

> Every XELIS address identifies a wallet. Some addresses also include data
> required by the recipient.

Detect the address kind automatically. Prefer “address with integrated data” in
the AddressBook and “attached data” in transaction review/history. Do not label
arbitrary data as a payment ID unless its application schema proves that
meaning. Lists should show only a data badge; reveal typed content on demand.

## Errors and diagnostics

Operations use `wallet.address_book.migrate`, `.list`, `.upsert`, `.remove`,
`.find`, and `.match`. Invalid input, network mismatch, storage failure,
serialization failure, conflict, and not-found states retain their stable
`XelisWalletException` classification and support reference.

Authored model `toString()` methods redact addresses, names, labels, and notes.
Diagnostic logging may include those values only in an explicit privileged
development mode under the application's own logging policy. Follow
[`error-handling.md`](error-handling.md) for support metadata and
[`logging.md`](logging.md) for diagnostic retention.
