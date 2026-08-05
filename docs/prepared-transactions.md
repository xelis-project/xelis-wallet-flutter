# Prepared transactions

This guide is for Flutter applications preparing, reviewing, cancelling, and
broadcasting ordinary transfers, burns, multisig setup, and finalized multisig
transactions. The authored contract is independent from generated Flutter Rust
Bridge classes and `xelis-dart-sdk` RPC DTOs.

## Exact amounts and fees

Every monetary value crossing the supported Dart API uses atomic units:

- Dart inputs and outputs use `BigInt`;
- Rust inputs and outputs use `u64`;
- decimal formatting and parsing remain the consuming application's UI
  responsibility;
- no supported transaction method converts through `double`, `f64`, or JSON.

`XelisWalletFeePolicy` expresses a multiplier in basis points. `10000` is 1x,
`15000` is 1.5x, and `20000` is 2x. The supported range is 1x through 10x. Rust
calculates the target fee with checked integer arithmetic and rounds upward.
The fee returned by `estimateTransferFees()` is advisory. A review screen must
always display `XelisWalletPreparedTransaction.feeAtomic`, which is the fee
encoded in the transaction that will actually be submitted.

## Preparation flow

The stable ordinary-transaction methods are:

| Method | Stable operation |
| --- | --- |
| `estimateTransferFees()` | `wallet.transaction.fees.estimate` |
| `prepareTransfers()` | `wallet.transaction.transfers.prepare` |
| `prepareTransferAll()` | `wallet.transaction.transfer_all.prepare` |
| `prepareBurn()` | `wallet.transaction.burn.prepare` |
| `prepareBurnAll()` | `wallet.transaction.burn_all.prepare` |
| `prepareMultisigSetup()` | `wallet.multisig.setup.prepare` |
| `finalizeMultisigTransaction()` | `wallet.multisig.finalize` |
| `inspectPreparedTransferExtraData()` | `wallet.transaction.prepared.inspect` |
| `discardPreparedTransaction()` | `wallet.transaction.prepared.cancel` |
| `broadcastPreparedTransaction()` | `wallet.transaction.broadcast` |

Multisig request and signature-share serialization is documented separately in
[`multisig-signing-protocol.md`](multisig-signing-protocol.md).

A successful preparation returns an immutable
`XelisWalletPreparedTransaction`. Its hash, actual fee, and typed transfer,
burn, multisig-setup, or finalized-multisig details are projected from the
values used by Rust to build the native
transaction. Transfer extra-data payloads are deliberately omitted from the
review projection; only presence and encryption metadata are retained. For an
integrated destination, the projection exposes the corresponding normal
address and marks extra data as present, so the integrated payload is not
re-encoded into the public review model.

An explicit review action may call `inspectPreparedTransferExtraData()` with
the exact prepared object and transfer index. The private Dart capability and
native `preparationId + hash` must both match the current ready slot. The result
contains a lossless `XelisDataElement`, its integrated-address or explicit
source, and the actual encryption choice. It shares the slot lifecycle: a
replacement, terminal submission, or cancellation makes the old inspection
capability invalid; a retryable broadcast restores it unchanged.

The authored result redacts its payload from `toString()`. Request it only when
the user opens an attached-data detail; do not prefetch it for lists, analytics,
or standard logs.

The native wallet intentionally owns one prepared-transaction slot. A new
successful preparation replaces the previous ready value, while a failed
preparation leaves the previous value intact. Preparation is rejected while a
submission is in flight.

Consumers must retain the exact prepared object through review. The private
adapter associates that object with the originating wallet instance and native
preparation generation. Reconstructing an equivalent Dart object, reusing an
object after replacement, or passing it to another wallet does not grant
submission authority. Rust verifies both the generation and canonical hash
before inspection, cancellation, or broadcast.

## Broadcast outcomes

`broadcastPreparedTransaction()` returns one of five exhaustive values:

| Result | Native prepared slot | Application action |
| --- | --- | --- |
| `XelisWalletBroadcastSubmitted` | consumed | Show success |
| `XelisWalletBroadcastRetryable` | restored unchanged | Keep the review and offer an explicit retry |
| `XelisWalletBroadcastRejected` | consumed | Record the failure and require a new preparation |
| `XelisWalletBroadcastLocalFailure` | consumed | Record the failure and require a new preparation |
| `XelisWalletBroadcastSubmittedNeedsResync` | consumed | Treat as submitted and reconcile wallet state |

The four non-clean outcomes contain a `XelisWalletException` created at the
`wallet.transaction.broadcast` boundary. Applications must preserve its
existing `XWF-...` support reference, source, stable code, native kind, and
native numeric code. They must not wrap it in a second application-generated
support reference.

Exceptions thrown directly by preparation, discard, or broadcast mean the
operation did not reach a state where one of the five submission outcomes can
be asserted. Examples include a stale or cross-wallet prepared object, malformed
bridge data, and an inconsistent native slot.

## Consumer review rules

Before submitting, a Flutter application should:

1. store the exact prepared object in its review state;
2. render its typed details and actual fee;
3. reveal attached data only after an explicit user action, using that exact
   prepared object and transfer index;
4. reset confirmation whenever that object changes;
5. after authentication or any other asynchronous pause, recheck the active
   wallet session and the same prepared object;
6. pass that object directly to `broadcastPreparedTransaction()`;
7. record any attached structured failure once and choose retry, recreation,
   or resynchronization from the result variant rather than native prose.

## Errors and diagnostics

Preparation, inspection, cancellation, and capability failures use the stable
`XelisWalletException` contract. Broadcast failures attached to an authored
outcome retain their original exception and support reference; consumers must
record that failure once rather than adapting it again.

Diagnostic messages may contain hashes, destinations, amounts, paths, or
dependency context. They remain privileged diagnostic data and must never be
shown by default in the UI. See [`error-handling.md`](error-handling.md) and
[`logging.md`](logging.md).
