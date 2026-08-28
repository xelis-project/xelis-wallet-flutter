# Logging

This guide is for Flutter applications consuming the optional native diagnostic
stream. Logging is independent from the exception channel: a Rust operation can
return an error without emitting a record, and a log record never throws by
itself.

## Lifecycle and flow

```text
xelis-wallet-flutter / xelis-wallet / xelis-common / Rust dependencies
                              |
                         log::Record
                              |
                    package-owned Rust logger
                              |
                 Flutter Rust Bridge stream sink
                              |
                       XelisLogEntry
                              |
                 consumer logger / support tooling
```

The native logger is process-wide. A consumer must initialize it once, create
one stream, retain one subscription, and cancel that subscription when the
application shuts down. Recreating the stream replaces the native sink; this is
supported for development hot reload, but it should not be used as a broadcast
mechanism.

## Log scopes

Initialization requires a deliberate policy:

```dart
await XelisWalletFlutter.initializeRustLogger(
  minimumLevel: XelisLogLevel.warn,
  scope: XelisNativeLogScope.standard,
);

final subscription = XelisWalletFlutter.createRustLogStream().listen(
  handleNativeLog,
);
```

The first successful logger configuration is immutable for the lifetime of the
process. Calls with the same configuration are idempotent and concurrent calls
share one initialization. A later call with different values fails explicitly.

| Scope | Records forwarded | Intended use |
| --- | --- | --- |
| `standard` | Exact package-owned `xelis_wallet_flutter` target | Production-safe support events |
| `packageDiagnostic` | Standard plus `xelis_wallet_flutter::*` module targets | Local package debugging |
| `unsafeUpstreamDiagnostic` | Package targets plus `xelis_wallet::*` and `xelis_common::*` | Explicit local upstream diagnosis only |

Standard mode does not attempt to redact arbitrary strings from dependencies.
It excludes them before they cross the bridge. This is safer than parsing a
formatted message after its structure has already been lost.

Package diagnostic scope can include local paths, addresses, amounts, balances, asset or
transaction hashes, and daemon failures emitted by this package's audited Rust
wrapper. Those values can be essential when reproducing a problem, but they
must not be retained, exported, or displayed to users by default.

Free-form records from `xelis_wallet` and `xelis_common` cross the bridge only
in `unsafeUpstreamDiagnostic`; other dependencies remain excluded. Upstream
debug messages can contain a
complete signed transaction, signature material, encryption context, or raw
payload. Their layer and error category must cross a structured error/support
contract instead of the free-form log stream.

XWF makes no redaction promise for the unsafe upstream scope. The following
data must never be deliberately logged by package or consumer code:

- seed words or mnemonic candidates;
- private keys, passwords, tokens, credentials, or encryption keys;
- signature material or complete signing payloads;
- raw QR, XSWD, clipboard, deep-link, RPC, WebSocket, or transaction payloads;
- authenticated URLs, headers, or complete external JSON.

## Public log model

`XelisLogEntry` is authored Dart API and does not expose Flutter Rust Bridge
types. It contains:

- `level`: `XelisLogLevel` severity;
- `source`: stable high-level provenance (`xelisWalletFlutter`, `xelisWallet`,
  `xelisCommon`, `flutterRustBridge`, or `dependency`); an available source value
  does not imply that free-form records from that layer are forwarded;
- `target`: the Rust target/module identifier;
- `message`: the native diagnostic text.

`source` is classified from the Rust target, never from message text. It is
suitable for finding the responsible layer. A detailed diagnostic target is
not a versioned API and may change as upstream modules are reorganized.

The free-form `message` is not UI-safe. Even `warn` and `error` messages can
contain externally supplied or operational data. Applications must not use log
wording for retry decisions, error categories, or localized messages.

## Consumer responsibilities

A production consumer should:

1. keep the `standard` scope;
2. disable console output unless explicitly required;
3. bound any in-memory history;
4. accept only package-authored support events;
5. keep Riverpod/application state values out of logs;
6. show localized UI text instead of native messages.

A debug consumer may enable `packageDiagnostic` and a lower minimum level. It
should make that policy obvious at its integration point and still sanitize
endpoints and externally controlled payloads. `unsafeUpstreamDiagnostic` must
be an obvious, temporary local-only choice and never broadens the allowlist
beyond the two selected XELIS crates.

Stable error codes, operations, and support correlation identifiers belong to
the structured exception contract described in
[`error-handling.md`](error-handling.md). They complement this stream; they do
not turn arbitrary native log messages into an application error API.
