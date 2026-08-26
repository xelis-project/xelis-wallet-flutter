# Error handling

`xelis-wallet-flutter` owns the stable error boundary between the native XELIS
wallet runtime and Flutter applications. It classifies bridge failures,
attaches safe support metadata, and preserves privileged diagnostics and stack
traces.

Consuming applications own localization, user-facing copy, retry policy,
telemetry, and diagnostic-data retention.

## Supported boundary

This contract applies to every API exported by
`package:xelis_wallet_flutter/xelis_wallet_flutter.dart`. Generated Flutter Rust
Bridge types and lifecycle entrypoints are private implementation details.

Typed native operations transport `NativeXelisError` through the private
bridge. Operations backed by dependencies that expose only untyped failures,
including some XSWD paths, use the conservative bridge fallback described
below. The Dart adapters handle synchronous calls, futures, and streams while
preserving the original stack trace.

## Structured contract v1

Every `XelisWalletException` contains:

| Field | Meaning | Standard UI/log policy |
| --- | --- | --- |
| `contractVersion` | Metadata contract version; currently `1` | Safe to retain and log |
| `source` | Component that classified the failure | Safe to log; usually too technical for primary UI copy |
| `operation` | Stable package operation such as `wallet.open` | Safe for support and telemetry |
| `code` | Stable failure category such as `network.failed` | Safe for control flow, localization, and logs |
| `supportId` | Opaque identifier correlating a report with one recorded failure | Safe to show and log |
| `nativeKind` | Optional audited native discriminant | Safe to log; use for behavior only when documented |
| `nativeCode` | Optional numeric native code | Safe to log when its source semantics are known |
| `diagnosticMessage` | Full detail received from the failing layer | Privileged; never standard UI or logs |

`XelisWalletErrorContract.currentVersion` is the source of truth for the
contract version. `XelisWalletErrorCode` and `XelisWalletOperation` are value
classes rather than enums: their known constants are stable, but their sets are
non-exhaustive. Consumer mappings must always provide a fallback.

### Operations, codes, and sources

- An operation identifies the exact stable façade action, using a lowercase
  dot-delimited identifier such as `wallet.open` or
  `wallet.network.connect`.
- A code identifies the failure class, not the operation. Typed native
  classification and explicit package preconditions take priority; otherwise
  the adapter keeps `operation.failed` or `bridge.failed`.
- A source identifies the deepest component the classifier can prove. For an
  untyped failure it identifies the boundary that received the error, not
  necessarily the root cause.
- Adapters never infer a code, source, identifier, or retry policy from
  exception prose.

Consumers must compare the provided constants instead of reconstructing
identifiers from strings. Adding or renaming a package constant changes the
public support contract and requires focused mapping tests and documentation.

### Support identifiers

Each newly adapted failure receives an opaque identifier such as:

```text
XWF-1234-ABCD-5678-EF90-1234
```

It is generated independently from the error text and contains no wallet,
filesystem, network, or account data. Re-propagating an existing
`XelisWalletException` preserves the same object and support ID.

An application should record the support ID with the safe fields before showing
it to a user. An identifier that was never recorded cannot be correlated with a
later support report.

## Bridge mapping

The private adapter matches concrete types and boundary metadata only.
`NativeXelisError` is handled before generic Flutter Rust Bridge failures so its
structured fields cannot collapse into a bridge error.

| Incoming failure | Public result | Source and code |
| --- | --- | --- |
| `NativeXelisError` v1 | `XelisWalletOperationException` | Native fields mapped exactly |
| Unsupported `NativeXelisError` version | `XelisWalletBridgeException` | `flutterRustBridge` / `bridge.failed` |
| FRB `AnyhowException` | `XelisWalletOperationException` | Boundary source / `operation.failed` |
| FRB `PanicException` | `XelisWalletBridgeException` | `flutterRustBridge` / `bridge.native_panic` |
| FRB `PlatformMismatchException` | `XelisWalletBridgeException` | `platform` / `bridge.unsupported_platform` |
| Other FRB failure | `XelisWalletBridgeException` | `flutterRustBridge` / `bridge.failed` |
| Existing `XelisWalletException` | Same object | Existing metadata and support ID preserved |
| Unrelated Dart error | Same object | Not owned or reclassified by the package |

Package programming errors may remain ordinary Dart errors. Examples include
using the runtime before initialization or using an authored handle after
disposal. Consumers must not assume every precondition failure becomes a
`XelisWalletException`.

## Notable classifications

These mappings are part of the public behavior most likely to affect consumer
recovery:

- authenticated-decryption failures while opening a wallet or checking a
  password use `wallet.authentication_or_corrupt_data`; the package does not
  claim whether the password or encrypted data is wrong;
- malformed daemon origins use `input.invalid`, a daemon on another XELIS
  network uses `network.mismatch`, connection expiry uses `network.failed`, and
  an overlapping connection attempt uses `state.operation_in_progress`;
- transport failures remain `network.failed`, daemon RPC rejections remain
  `daemon.rejected`, and daemon reads without an active handler use
  `wallet.offline`;
- a runtime or business-event lag uses `stream.lagged` and requires one
  coalesced authoritative reconciliation;
- an active native event channel closing unexpectedly uses
  `stream.closed_unexpectedly`; explicit cancellation is normal and emits no
  failure;
- an upstream `SyncError` uses the conservative `wallet.sync` /
  `operation.failed` mapping. Its text remains diagnostic-only; a subsequent
  typed `Offline` event controls recovery;
- invalid hashes, destinations, amounts, fee policies, or protocol envelopes
  use `input.invalid` when the package can prove the precondition;
- native hexadecimal inputs must encode exactly one value. Trailing bytes fail
  closed. Private-key failures use `PRIVATE_KEY_INVALID_ENCODING`; hashes,
  signatures, and multisig envelope fields use the domain-specific structured
  classification of their stable boundary;
- absent or stale native capabilities use `resource.not_found`, while
  reconstructed, cross-wallet, consumed, or replayed capabilities fail closed
  with `state.conflict`;
- broadcast result variants carry both the prepared-slot disposition and the
  original structured exception. Retryability must come from the result
  variant, not exception prose or code alone.

Detailed lifecycle and domain rules live in the corresponding guides:

| Domain | Guide |
| --- | --- |
| Address parsing and integrated data | [`address-api.md`](address-api.md) |
| Address-book storage and matching | [`address-book-api.md`](address-book-api.md) |
| Wallet reads and explicit extra-data disclosure | [`wallet-read-api.md`](wallet-read-api.md) |
| Prepared transactions and broadcast outcomes | [`prepared-transactions.md`](prepared-transactions.md) |
| Runtime and business event subscriptions | [`runtime-events.md`](runtime-events.md) |
| Native logging and diagnostic records | [`logging.md`](logging.md) |
| XSWD callbacks and redaction | [`xswd-api.md`](xswd-api.md) |

## Diagnostic separation

`diagnosticMessage` preserves the detail available at the failing boundary.
For typed native errors it may include a reviewed cause chain or RPC data. For
generic `anyhow` failures, Flutter Rust Bridge has already reduced the native
error to text, so Dart cannot safely recover its original type.

The diagnostic may contain paths, amounts, balances, addresses, hashes,
endpoint details, or values supplied by dependencies. It must not be used for
control flow, standard logs, analytics, retained production history, or UI.

`XelisWalletException.toString()` emits only safe metadata. It omits
`diagnosticMessage`, `nativeKind`, and `nativeCode`; consumers that retain the
latter audited fields must do so explicitly.

Never retain or display seeds, passwords, private keys, tokens, signing
material, authenticated URLs, complete RPC/XSWD/QR payloads, or other secrets,
even in diagnostic mode. See [`logging.md`](logging.md) for the complete native
logging policy.

## Flutter application handling

Catch a failure only at a layer that can retry, change application state, or
present an error. Record safe fields once, map the stable code to localized
copy, and show the support ID separately:

```dart
try {
  await XelisWalletFlutter.initializeConfiguration();
} on XelisWalletException catch (error, stackTrace) {
  diagnostics.recordWalletFailure(
    contractVersion: error.contractVersion,
    source: error.source.name,
    operation: error.operation.id,
    code: error.code.id,
    supportId: error.supportId,
    nativeKind: error.nativeKind,
    nativeCode: error.nativeCode,
    stackTrace: diagnostics.sanitizeStackTrace(stackTrace),
  );

  final message = switch (error.code) {
    XelisWalletErrorCode.invalidInput => 'Check the supplied information.',
    XelisWalletErrorCode.offline => 'Connect the wallet and try again.',
    XelisWalletErrorCode.networkFailure =>
      'The network is currently unavailable.',
    XelisWalletErrorCode.insufficientFunds =>
      'The available balance is insufficient.',
    _ => 'The wallet could not complete this request.',
  };

  showError(message: message, supportReference: error.supportId);
}
```

The strings and helper interfaces are illustrative and belong to the
application. Production copy must be localized. Never display
`diagnosticMessage`, interpolate an unknown native exception, or use native text
as fallback UI copy.

### Standard support records

A production support record may contain:

- `contractVersion`;
- the authored exception type;
- `source`, `operation`, and `code`;
- `supportId`;
- `nativeKind` and `nativeCode`, when present;
- a reviewed or sanitized Dart stack trace;
- explicitly audited, non-sensitive application context.

It must not contain `diagnosticMessage` by default. An explicitly enabled local
diagnostic workflow may record a reviewed or redacted diagnostic and full stack
trace in a channel isolated from standard output and production retention.

## Propagation rules

- Use `rethrow` when the current layer cannot recover or present the failure.
- Preserve an existing `XelisWalletException` and its original support ID.
- Preserve the original stack trace across synchronous, future, and stream
  boundaries.
- If an application error wraps the package failure, retain the original
  exception or all of its safe metadata.
- Do not convert unrelated Dart exceptions into wallet failures.
- Stream handlers must retain the supplied stack trace and cancellation
  behavior.
