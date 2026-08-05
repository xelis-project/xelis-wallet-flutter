import '../assets/xelis_wallet_asset.dart';
import '../errors/xelis_wallet_exception.dart';
import '../transactions/xelis_wallet_transaction.dart';

/// Versioned contract for session-scoped wallet business events.
abstract final class XelisWalletBusinessEventContract {
  /// Version emitted by the current package implementation.
  static const currentVersion = 1;
}

/// Ordered event envelope emitted by one business-event subscription.
///
/// [generation] identifies the native subscription instance. [sequence] is a
/// strictly increasing, lossless identifier within that generation. Consumers
/// must discard results from an obsolete generation after asynchronous work.
final class XelisWalletBusinessEventFrame {
  const XelisWalletBusinessEventFrame({
    required this.contractVersion,
    required this.generation,
    required this.sequence,
    required this.event,
  });

  /// Wire-contract version used to decode [event].
  final int contractVersion;

  /// Lossless identifier of the native subscription instance.
  final BigInt generation;

  /// Lossless, strictly increasing identifier within [generation].
  final BigInt sequence;

  /// Typed wallet update carried by this frame.
  final XelisWalletBusinessEvent event;
}

/// Base type for wallet state updates emitted by the native wallet.
sealed class XelisWalletBusinessEvent {
  const XelisWalletBusinessEvent();
}

/// A transaction became confirmed and was added to wallet history.
final class XelisWalletNewTransaction extends XelisWalletBusinessEvent {
  const XelisWalletNewTransaction({required this.transaction});

  final XelisWalletTransactionEntry transaction;
}

/// A locally known transaction entered the pending set.
final class XelisWalletNewPendingTransaction extends XelisWalletBusinessEvent {
  const XelisWalletNewPendingTransaction({required this.transaction});

  final XelisWalletPendingTransaction transaction;
}

/// The wallet balance for one asset changed.
final class XelisWalletBalanceChanged extends XelisWalletBusinessEvent {
  const XelisWalletBalanceChanged({required this.asset, required this.balance});

  /// Canonical hexadecimal asset hash.
  final String asset;

  /// New balance in the asset's atomic units.
  final BigInt balance;
}

/// A complete asset description became available to the wallet.
final class XelisWalletNewAsset extends XelisWalletBusinessEvent {
  const XelisWalletNewAsset({required this.asset});

  final XelisWalletAsset asset;
}

/// The wallet started tracking an asset.
final class XelisWalletAssetTracked extends XelisWalletBusinessEvent {
  const XelisWalletAssetTracked({required this.asset});

  /// Canonical hexadecimal asset hash.
  final String asset;
}

/// The wallet stopped tracking an asset.
final class XelisWalletAssetUntracked extends XelisWalletBusinessEvent {
  const XelisWalletAssetUntracked({required this.asset});

  /// Canonical hexadecimal asset hash.
  final String asset;
}

/// Signals that the upstream receiver lagged before this frame.
///
/// [skippedEvents] counts the unfiltered upstream events skipped by this
/// receiver, not only business events. Relevant business-event loss cannot be
/// excluded, so consumers must coalesce one authoritative reconciliation of
/// balances, assets, pending state, and history. The stream remains usable.
final class XelisWalletBusinessEventStreamDegraded
    extends XelisWalletBusinessEvent {
  const XelisWalletBusinessEventStreamDegraded({
    required this.skippedEvents,
    required this.failure,
  });

  final BigInt skippedEvents;
  final XelisWalletException failure;
}

enum XelisWalletBusinessStreamCloseReason { nativeChannelClosed }

/// Terminal notification for an unexpectedly closed active native channel.
///
/// Explicit cancellation completes silently and does not emit this event.
final class XelisWalletBusinessEventStreamClosed
    extends XelisWalletBusinessEvent {
  const XelisWalletBusinessEventStreamClosed({
    required this.reason,
    required this.failure,
  });

  final XelisWalletBusinessStreamCloseReason reason;
  final XelisWalletException failure;
}
