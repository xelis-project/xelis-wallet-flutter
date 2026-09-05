# Wallet event subscriptions

This guide is for Flutter applications projecting wallet state from two
authored, pull-driven subscriptions. The runtime channel is connection-scoped;
the business channel is session-scoped. Both contracts are independent from
generated Flutter Rust Bridge classes and upstream Rust payloads.

## Public events

The runtime contract contains:

| Event | Meaning | Consumer action |
| --- | --- | --- |
| `XelisWalletOnline` | The current native network handler is online | Complete the matching connection transition only |
| `XelisWalletOffline` | The current native network handler is offline | Follow the reconnect owner selected for this connection |
| `XelisWalletSyncIssue` | Upstream synchronization reported a non-terminal issue | Record safe support metadata; wait for `Offline` before reconnecting |
| `XelisWalletTopoheightChanged` | A new wallet topoheight was observed | Update the matching runtime projection |
| `XelisWalletRescanStarted` | A user action or DAG reorganization started a rescan | Mark the same generation as rescanning |
| `XelisWalletHistorySynced` | History synchronization reached a topoheight | Clear rescanning state and invalidate history projections |
| `XelisWalletEventStreamDegraded` | The bounded upstream channel lost events | Coalesce one authoritative reconciliation; do not reconnect solely for lag |
| `XelisWalletEventStreamClosed` | The active upstream channel closed unexpectedly | Move to a safe offline/failed state and retain its support reference |

The business contract contains:

| Event | Meaning | Consumer action |
| --- | --- | --- |
| `XelisWalletNewTransaction` | A confirmed transaction was stored | Update transaction-derived state and history |
| `XelisWalletNewPendingTransaction` | A pending transaction was stored | Update pending state, balances, and history |
| `XelisWalletBalanceChanged` | One tracked asset balance changed | Re-read authoritative balances as needed |
| `XelisWalletNewAsset` | New asset metadata was observed | Update or re-read asset metadata |
| `XelisWalletAssetTracked` / `XelisWalletAssetUntracked` | Wallet tracking changed | Reconcile tracked assets and balances |
| `XelisWalletBusinessEventStreamDegraded` | The upstream receiver lagged; relevant business-event loss cannot be excluded | Coalesce one wallet-state reconciliation; do not change network state |
| `XelisWalletBusinessEventStreamClosed` | The active session channel closed unexpectedly | Preserve its support reference and degrade business notifications only |

## Data flow and backpressure

```text
xelis-wallet bounded broadcast receiver
                 |
                 v
opaque Rust subscription -- nextEvent() --> private Dart adapter
          ^                                  |
          | cancel signal + awaited drain    v
          +------------------------- authored single-subscription Stream
```

The native receiver is registered before either subscribe future completes.
Dart then requests exactly one frame at a time. Pausing a Dart listener may
leave the current native read in flight and buffer at most its one returned
frame; the adapter does not start another read until the listener resumes.

Each frame contains:

- `contractVersion`, currently `1`;
- `generation`, a native `u64` exposed as lossless `BigInt`;
- `sequence`, a native `u64` exposed as lossless `BigInt` and starting at one;
- one authored event.

The adapter validates version, generation, and exact sequence continuity. A
violation is a terminal `bridge.failed` error because accepting ambiguous
ordering would make application state unreliable.

## Connection rotation

For every connection or reconnection, use this order:

1. Invalidate the application's current event-generation token.
2. Call and await `cancel()` on the old package subscription.
3. Call and await `wallet.setOffline()`.
4. Call and await `wallet.subscribeRuntimeEvents()`.
5. Start listening and capture wallet identity, request ID, and subscription
   generation in every handler.
6. Call and await `wallet.setOnline()`. Application-managed reconnection and a
   20-second timeout are the defaults; upstream-managed reconnection is an
   explicit experimental option.
7. After every asynchronous handler step, recheck all captured identities
   before mutating application state.

Creating the receiver after `setOffline()` prevents old queued `Offline`
events from being relabeled as part of a new generation. Creating and listening
before `setOnline()` ensures immediate `Online`, `SyncIssue`, or `Offline`
events cannot be missed.

Choose exactly one reconnect owner for each connection. With the default
`applicationManaged` policy, an `Offline` event is the application's signal to
schedule its own retry for the same wallet generation. With
`upstreamManagedExperimental`, the native handler owns retries; the application
must project `Offline` state but must not start a competing `setOnline()` loop.
Changing owner requires the full connection-rotation sequence above.

The configured timeout bounds only connection establishment. `setOffline()`
and `close()` always await native handler shutdown, including an upstream retry
that is already sleeping, so their completion is a reliable lifecycle barrier.

Create `subscribeBusinessEvents()` once after opening the wallet, before normal
session work begins. Do not rotate it on connect, reconnect, disconnect, or
offline mode: local pending, transaction, balance, and asset events remain
meaningful without a daemon connection. Session replacement and close must
invalidate and await both channels. The authored wallet defensively cancels all
tracked subscriptions before calling the native wallet close operation.

## Lag, synchronization issues, and closure

`XelisWalletEventStreamDegraded` and
`XelisWalletBusinessEventStreamDegraded` report the exact count supplied by the
upstream broadcast receiver. Each receiver observes the unfiltered wallet event
feed before its channel-specific mapping, so this count includes skipped events
that may belong to the other channel; it is not a count of lost typed events.
Relevant loss cannot be excluded. The marker is therefore non-terminal and
requires one conservative, coalesced reconciliation for the active generation,
but does not itself prove a network failure.

`XelisWalletSyncIssue` is also non-terminal. Current upstream XELIS code has
already flattened several possible causes into one string. The package neither
parses that string nor claims a deeper source. It exposes stable safe metadata
and retains the text only as privileged diagnostics. Wait for typed connection
state before retrying.

The corresponding typed `...StreamClosed` event is emitted exactly once when an
upstream channel closes while its subscription is active. The stream then
completes. A runtime closure is connection-terminal; a business closure does
not itself prove that the wallet is offline. Explicit
`cancel()` instead wakes the pending poll, completes quietly, waits for the poll
to settle, and disposes the private opaque handle. Repeated cancellation is
idempotent.

Not every stream completion is preceded by `XelisWalletEventStreamClosed`.
Polling errors, native error-contract mismatches, and frame validation failures
are delivered through the Dart stream error channel with their original stack
trace and are then followed by `onDone`. A consumer must install both handlers.
An `onDone` for the still-active generation is terminal; an `onDone` observed
after that generation was invalidated and `cancel()` was requested is expected
and must not create a second failure or support ID.

## Errors and diagnostics

`SyncIssue` and both channels' degraded/closed events carry a structured
`XelisWalletException`. Standard UI and logs may use its contract version,
source, operation, code, support ID, native kind, and native numeric code.
`diagnosticMessage` remains privileged and is excluded from exception
`toString()`.

Do not attach daemon URLs, credentials, filesystem paths, amounts, complete
hashes, transaction payloads, or upstream prose to standard event logs. An
explicit local diagnostic workflow may retain reviewed operational context as
described in [`error-handling.md`](error-handling.md) and
[`logging.md`](logging.md), but must still exclude seeds, keys, passwords,
tokens, and signing material.

The subscription fixes its extra-data disclosure for its full lifetime:
`redacted` (default) exposes flag and presence, `metadata` also exposes the
top-level kind, and `detailed` exposes the complete typed payload. Detailed
events are active sensitive data and require explicit consumer handling.

All transaction, balance, topology, timestamp, fee, nonce, gas, supply, and
asset-owner `u64` values cross FFI directly and remain `BigInt`.
`PlaintextExtraData.shared_key` never enters the public contract at any
disclosure level.
