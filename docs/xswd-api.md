# XSWD API

This guide is for Flutter applications integrating XSWD through the authored
`XelisXswd*` contract exported by the root library. Generated Flutter Rust
Bridge request, application, permission, decision, and relayer types remain
private implementation details.

## Lifecycle and ownership

One opened `XelisWallet` owns its local XSWD server and relayer sessions.

- `startXswd` starts the local server and is idempotent while it is running.
- `addXswdRelayer` adds a parsed relay session and works independently of local
  server availability.
- `getXswdState` returns the current running flag and connected applications.
- `closeXswdApplicationSession` closes exactly one application session.
- `updateXswdApplicationPermissions` replaces policies for an application.
- `stopXswd` stops both the local server and relay sessions and is idempotent
  while stopped.

Consumers own orchestration across wallet-session replacement. Stop XSWD and
await completion before closing or disposing the wallet handle.

## Permission identifiers

`XelisXswdApplication.permissions`, permission updates, and relayer permission
lists use unprefixed wallet RPC method names, for example `get_balance`.

A permission name beginning with `wallet.` is invalid and fails before the
native call with `input.invalid / XSWD_PERMISSION_NAME_INVALID`. Permission
names are never ignored or normalized silently.

## Callback boundary

`XelisXswdCallbacks` is an authored callback bundle. The package privately
converts generated requests before invoking it and converts decisions back to
the bridge contract. A callback exception or timeout never crosses into Rust.
Notification callbacks are abandoned and decision callbacks fail closed with
`XelisXswdDecision.reject`.

Only one native XSWD event handler exists at a time. If a handler already
exists, a newly added relayer uses that handler's callbacks.

## RPC payload and redaction

`XelisXswdRequest.payloadJson` is an opaque RPC payload present only for
permission and prefetch-permission requests. RPC DTOs and interpretation remain
the responsibility of the consuming application and `xelis-dart-sdk`; the
wallet package does not define daemon or wallet RPC DTOs.

Treat relay QR, paste, and deep-link data plus request payload JSON as untrusted
and potentially sensitive. Never place complete payloads, encryption keys, or
callback exceptions in standard logs, support references, analytics, crash
reports, or toasts. The authored request, relayer, encryption, application, and
state `toString()` implementations omit those values.

## Errors and diagnostics

Every façade operation maps bridge failures to `XelisWalletException` with its
exact `wallet.xswd.*` operation. Typed native failures keep their structured
classification. Untyped native failures use the documented conservative
`operation.failed` adapter fallback without parsing exception prose.

Invalid relayer encryption keys fail before the native call as structured
`input.invalid` errors. Consumers must make recovery and presentation decisions
from structured fields and must never show `diagnosticMessage` or caught
exception text. Follow [`error-handling.md`](error-handling.md) for exception
handling and [`logging.md`](logging.md) for diagnostic retention.
