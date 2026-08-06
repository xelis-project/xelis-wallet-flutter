# Changelog

## 0.1.2

- Added the `xelis_wallet_flutter:build_web` executable so consumers can build
  the shared-memory Web package from the XWF revision resolved by Pub.

## 0.1.1

- Updated the native XELIS crates to a pinned 1.24.0 development revision,
  including post-release WebSocket session fixes.
- No public Dart API changes.

## 0.1.0

Initial development release of the shared Flutter integration for the native
XELIS wallet runtime.

- Authored Dart façade for runtime initialization, wallet creation, recovery,
  opening, authentication, network lifecycle, rescan, and deterministic
  close/dispose handling.
- Lossless address parsing and integrated-address creation with typed
  `DataElement` values, exact unsigned integers, ordered fields, and immutable
  blobs.
- Destination-first address book with canonical integrated destinations,
  deterministic identities, exact/base/ambiguous matching, and non-destructive
  migration of existing entries.
- Typed wallet reads and pull-driven runtime and business-event subscriptions
  for balances, assets, history, pending transactions, synchronization, and
  lifecycle changes.
- Capability-bound ordinary and multisig transaction preparation, inspection,
  signing, cancellation, and broadcast with atomic `BigInt` amounts and typed
  prepared-slot outcomes.
- Versioned structured failure contract with stable operations, codes, support
  identifiers, audited native discriminants, preserved stack traces, and
  privileged diagnostics separated from UI and standard logs.
- Package-owned native logging and XSWD contracts with explicit lifecycle,
  callback, relayer, redaction, and standard/diagnostic policies.
- Flutter plugin packaging for Android, iOS, Linux, macOS, Windows, and a
  dedicated shared-memory Web build pipeline.
