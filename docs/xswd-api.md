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
the bridge contract. A callback exception or timeout never crosses into Rust
as an arbitrary Dart exception: XWF returns a static technical XSWD error.
`XelisXswdDecision.reject` is reserved for an explicit consumer decision.
`AppDisconnect` has no upstream response sender, so a failed notification is
abandoned with a static diagnostic only.

Only one native XSWD event handler exists at a time. The call that creates it
fixes callbacks, timeout, and projection limits until `stopXswd()`. Relayers
added later use that same handler configuration.

## Typed RPC payload

`XelisXswdRequest.payload` is the only authoritative callback projection. It is
an `XelisXswdObjectValue` for permission and prefetch-permission requests and is
absent for lifecycle notifications. XWF does not expose an intermediate JSON
string and does not define daemon or wallet RPC DTOs.

The sealed `XelisXswdValue` variants preserve nulls, booleans, strings,
floating-point values, arrays, objects, and integers. Native `i64` and `u64`
values cross the private bridge as canonical decimal strings and are exposed as
`XelisXswdIntegerValue.value` `BigInt`s. They never cross a JavaScript `Number`.
Genuine upstream `f64` values remain `XelisXswdFloatValue` `double`s, and
numeric primitives already encoded as strings remain strings.

The projection preserves values in the effective `RpcRequest` received by XWF;
it does not promise to recover the original JSON lexeme of a raw number larger
than `u64::MAX` if an upstream parser already represented that number as a
floating-point value.

Inspect only the fields required for the decision and reject unexpected value
kinds. For example:

```dart
final payload = request.payload;
if (payload is! XelisXswdObjectValue) {
  return XelisXswdDecision.reject;
}
final amount = payload.fields['amount'];
if (amount is! XelisXswdIntegerValue) {
  return XelisXswdDecision.reject;
}
// Review amount.value as a BigInt inside this callback only.
```

RPC payloads are active, untrusted, and potentially sensitive. Protocol-valid
requests may include explicit signer private keys. XWF projects those fields
faithfully but never includes scalar values or object keys in authored
`toString()` output. This redaction is protection against implicit rendering,
not a security barrier after code reads `.value`, `.values`, or `.fields`. An
explicit consent UI may display the exact fields needed for a decision.
Consumers must not log, retain automatically, attach to support references,
send to analytics, or include complete payloads in crash reports or toasts.

## Projection resource limits

The default `XelisXswdProjectionLimits` budget is:

- 64 levels of nesting;
- 65,536 private projection tokens;
- 4,096 members in one array or object;
- 4 MiB of UTF-8 in one string or object key;
- 8 MiB of cumulative UTF-8 string and key data.

Applications may choose other positive values up to the XWF technical ceilings:
depth 128, 262,144 tokens, 65,536 members, 8 MiB per text, and 16 MiB cumulative
text. The cumulative budget must be at least the per-text budget.

A projection failure sends no partial data to Dart, does not invoke the
consumer callback, and produces a static technical error. Only an explicit
prefetch rejection returns an empty permission table. These limits protect
projection, FRB and Dart from amplifying an already parsed payload; they do not
limit WebSocket reception, decryption, or upstream `RpcRequest` construction.

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
