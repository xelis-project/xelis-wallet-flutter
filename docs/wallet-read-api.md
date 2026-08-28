# Wallet read API

This guide is for Flutter applications reading lossless wallet state through
the authored `XelisWallet` façade. The public contracts are independent from
generated Flutter Rust Bridge types and `xelis-dart-sdk` RPC DTOs.

## Public operations

| Dart API | Result | Error operation |
| --- | --- | --- |
| `getXelisBalance()` | Native XELIS balance in atomic `BigInt` units | `wallet.balance.xelis.read` |
| `getTrackedBalances()` | Unmodifiable `Map<String, BigInt>` keyed by asset hash | `wallet.balances.tracked.read` |
| `getKnownAssets()` | Unmodifiable typed asset metadata map | `wallet.assets.known.read` |
| `getAssetMetadata(asset:)` | `XelisWalletAssetMetadata` | `wallet.asset.metadata.read` |
| `trackAsset(asset:)` | Whether the tracked set changed | `wallet.asset.track` |
| `untrackAsset(asset:)` | Whether the tracked set changed | `wallet.asset.untrack` |
| `getHistoryCount()` | Lossless confirmed-transaction count | `wallet.history.count.read` |
| `history(filter:)` | Unmodifiable confirmed list; extra-data metadata by default | `wallet.history.read` |
| `convertTransactionsToCsv(filter:)` | UTF-8 CSV text on native and Web | `wallet.history.csv.convert` |
| `exportTransactionsToCsvFile(filePath:, filter:)` | Atomic native file export; unsupported on Web | `wallet.history.csv.export` |
| `pendingTransactions()` | Unmodifiable pending list; extra-data metadata by default | `wallet.transactions.pending.read` |
| `transactionByHash(hash:)` | One confirmed detail; typed payload by default | `wallet.history.transaction.read` |
| `pendingTransactionByHash(hash:)` | One pending detail; typed payload by default | `wallet.transactions.pending.transaction.read` |

Amounts, balances, topoheights, timestamps, nonces, gas values, supplies, and
other Rust `u64` values cross the Dart boundary as `BigInt`. Applications must
retain those atomic values in state and format them only at the presentation
boundary using the asset's decimal precision.

A missing balance is represented as zero. A failed existence check or balance
read is not zero: it is a structured `XelisWalletException` with
`storage.failed`. This distinction prevents storage corruption or I/O failures
from being presented as an empty wallet.

## Assets

`XelisWalletAssetMetadata` is the package-owned wallet projection. It retains
the name, ticker, decimals, maximum-supply mode, and exhaustive ownership state.
It is not an RPC response DTO and should not be converted to a
`xelis-dart-sdk` asset model merely to store wallet state.

Known assets come from wallet storage. `getAssetMetadata` first uses the
wallet cache and can resolve a missing asset through the connected daemon. An
invalid hexadecimal asset hash is `input.invalid`; typed offline, network, and
storage causes retain their native classification. Untyped cache, persistence,
tracking, and untracking failures conservatively fall back to `storage.failed`
instead of `internal.failed`. Contract execution logs are a daemon RPC concern,
not wallet state. Consumers should use the authored invocation projection here;
log inspection belongs in a separate daemon client with typed RPC DTOs.

## History filter

`XelisWalletHistoryFilter` uses one-based pagination. `page` and optional
`limit` are `BigInt` so the same contract is lossless on native and Web builds.
A page or limit of zero, an overflowing pagination offset, an invalid address,
or an invalid asset hash is reported as `input.invalid` with native kind
`WALLET_HISTORY_FILTER_INVALID`.

`minTimestampMillis` and `maxTimestampMillis` are Unix timestamps in
milliseconds. Supply the lossless `destination` field with a
`XelisAddressDescriptor` returned by `XelisWalletFlutter.parseAddress`.

```dart
final destination = XelisWalletFlutter.parseAddress(
  address: savedDestination.address,
);
final filter = XelisWalletHistoryFilter(
  page: BigInt.one,
  destination: destination,
);
```

A standard destination preserves the native wallet's historical counterparty
semantics: incoming entries match their sender, outgoing transfers match their
destination, and multisig entries match a participant. An integrated
destination instead matches the exact canonical destination:

- outgoing transfers require the same base public key and protocol-serialized
  `DataElement`;
- an incoming entry has no stored destination because the current wallet is
  implicit, so it can match only when the integrated base is the current
  wallet's public key and one of its transfers has the exact `DataElement`;
- entries without matching transfer data do not match, even when their base
  address is identical.

History storage cannot prove whether matching effective data originally came
from an integrated address or from an explicit transfer-data input. Exact
matching therefore means the reconstructible `base + DataElement` destination,
not provenance of how the transaction was built.

Address filtering excludes global coinbase, burn, and blob entries. Asset
filtering excludes blob entries. Pagination is applied after every native
filter, including the exact integrated-data comparison, so two integrated
destinations that share a base cannot consume each other's pages. Adjacent
pages cannot repeat or overlap because of non-matching transactions. The
implementation requests only the filtered prefix needed for a standard-address
page. An integrated destination may require scanning all base candidates
because the locked wallet storage API exposes neither an integrated-data filter
nor a filtered cursor. An out-of-range page returns an empty list.
`maxTopoheight` equal to the maximum unsigned 64-bit value is normalized to no
upper bound, avoiding an unchecked `max + 1` in the locked upstream storage
while preserving the same semantics.

## CSV export

Both CSV operations accept the same authored `XelisWalletHistoryFilter` as
`history(filter:)`; generated `HistoryPageFilter` and Flutter Rust Bridge types
remain private implementation details. Filtering, exact integrated-destination
matching, and pagination therefore have the same semantics as an explicit
history read. A consumer that wants every matching transaction uses page one
with no limit.

`convertTransactionsToCsv` returns UTF-8 text on every supported target. On
Web, consumers must use this method and perform an explicit browser download.
`exportTransactionsToCsvFile` always fails on Web with `operation.unsupported`
and native kind `WALLET_HISTORY_CSV_FILE_EXPORT_UNSUPPORTED`; it never attempts
to interpret a browser path as a native filesystem path.

On native targets, file export creates the temporary file in the destination
directory, writes the complete CSV, flushes it to storage, and only then
atomically replaces the destination. A filter, history read, serialization, or
sync failure drops the temporary file and leaves an existing destination
unchanged. The destination path may appear in `diagnosticMessage` to support an
explicit support/debug workflow. It never appears in `XelisWalletException`
`toString()`, a support ID, or another standard log/UI field.

Using integrated data as a filter does not opt into detailed disclosure. Rust
compares canonical protocol bytes inside the wallet process and the normal
metadata/detailed projection policy still comes exclusively from
`extraDataDisclosure`. The filter payload must not be logged or included in a
support reference.

The transaction DTOs are the same authored types used by the business-event
channel. `chunkId` follows the public XELIS transaction terminology.

## Extra-data boundary

`XelisWalletExtraData` has four fields:

- `flag`: native private/public/proprietary/failed classification;
- `hasPayload`: whether the native plaintext extra data contains a
  `DataElement`;
- `payload`: the lossless tagged `XelisDataElement`, or `null`;
- `payloadKind`: its stable top-level kind (`boolValue`, `string`, `u8`, `u16`,
  `u32`, `u64`, `u128`, `hash`, `blob`, `array`, or `fields`), or `unknown` for a
  future native kind.

List reads use `XelisWalletExtraDataDisclosure.metadata` by default. They
return the flag, presence, and top-level kind without the value. Detail reads by
hash use `detailed` by default and return `payload` when the native plaintext
contains data. A caller may override either default, but must
request detailed disclosure only for an explicit transaction-detail or local
diagnostic action.

Payload data is potentially sensitive application content and must not be
included in standard logs, analytics, crash reports, support references, or
navigation-state persistence. A deliberate detail flow may display or copy it
according to the consuming application's policy.

The lossless `payload` preserves every unsigned width,
`u128` decimal value, immutable blob byte, array order, and ordered non-string
field key. `payloadKind` lets consumers identify the top-level shape without
revealing or decoding the value.

Business events default to redacting `payload` and `payloadKind` to `null`.
Their subscription may opt into metadata or detailed typed payloads.
`hasPayload` can therefore be `true` while all detail fields are `null`. The
upstream `PlaintextExtraData.shared_key` never crosses either bridge boundary
and has no field in the authored Dart model.

## Errors and diagnostics

All operations above return native `NativeXelisError` failures through the
private bridge and are adapted to `XelisWalletException`. Important native
fallbacks include:

| Failure | Stable code | Representative native kind |
| --- | --- | --- |
| Wallet balance/storage read | `storage.failed` | `WALLET_XELIS_BALANCE_READ_FAILED` |
| Tracked balance read | `storage.failed` | `WALLET_TRACKED_BALANCES_READ_FAILED` |
| Known asset read | `storage.failed` | `WALLET_KNOWN_ASSETS_READ_FAILED` |
| Invalid asset hash | `input.invalid` | `WALLET_ASSET_HASH_INVALID` |
| Untyped asset metadata/cache/persistence failure | `storage.failed` | `WALLET_ASSET_METADATA_READ_FAILED` |
| Untyped asset tracking failure | `storage.failed` | `WALLET_ASSET_TRACK_FAILED` |
| Untyped asset untracking failure | `storage.failed` | `WALLET_ASSET_UNTRACK_FAILED` |
| Invalid history filter | `input.invalid` | `WALLET_HISTORY_FILTER_INVALID` |
| Invalid CSV history filter | `input.invalid` | `WALLET_HISTORY_CSV_FILTER_INVALID` |
| No matching CSV rows | `resource.not_found` | `WALLET_HISTORY_CSV_EMPTY` |
| CSV history read | `storage.failed` | `WALLET_HISTORY_CSV_READ_FAILED` |
| CSV serialization | `serialization.failed` | `WALLET_HISTORY_CSV_SERIALIZATION_FAILED` |
| Native CSV file I/O | `storage.failed` | `WALLET_HISTORY_CSV_TEMP_FILE_CREATE_FAILED` / `WALLET_HISTORY_CSV_SYNC_FAILED` / `WALLET_HISTORY_CSV_REPLACE_FAILED` |
| Web file export | `operation.unsupported` | `WALLET_HISTORY_CSV_FILE_EXPORT_UNSUPPORTED` |
| Missing confirmed hash | `resource.not_found` | `WALLET_HISTORY_TRANSACTION_NOT_FOUND` |
| Missing pending hash | `resource.not_found` | `WALLET_PENDING_TRANSACTION_NOT_FOUND` |
| History payload projection | `serialization.failed` | `WALLET_HISTORY_EXTRA_DATA_SERIALIZATION_FAILED` |
| Pending payload projection | `serialization.failed` | `WALLET_PENDING_EXTRA_DATA_SERIALIZATION_FAILED` |

Typed nested wallet, database, JSON-RPC, offline, and network errors take
precedence over these conservative fallbacks. Applications should record the
safe `source`, `operation`, `code`, `supportId`, `nativeKind`, and `nativeCode`
fields and follow [`error-handling.md`](error-handling.md). Diagnostic messages
and typed/JSON payloads remain separate privileged data.

When a consumer associates a transaction with a saved destination, it must use
the exact destination-first matching rules from
[`address-book-api.md`](address-book-api.md). A base-only match is a hint, not
identity; an ambiguous base match must never be guessed.
