import '../errors/xelis_wallet_exception.dart';

/// Versioning information for the stable wallet runtime-event contract.
abstract final class XelisWalletRuntimeEventContract {
  /// Current version of the event frame and payload contract.
  static const currentVersion = 1;
}

/// One lossless, ordered event from a generation-scoped subscription.
final class XelisWalletRuntimeEventFrame {
  const XelisWalletRuntimeEventFrame({
    required this.contractVersion,
    required this.generation,
    required this.sequence,
    required this.event,
  });

  final int contractVersion;

  /// Native subscription generation. This remains a [BigInt] so `u64` values
  /// are lossless on Flutter Web.
  final BigInt generation;

  /// Monotone sequence within [generation], starting at one.
  final BigInt sequence;

  final XelisWalletRuntimeEvent event;
}

/// Runtime and synchronization event independent from transaction/asset DTOs.
sealed class XelisWalletRuntimeEvent {
  const XelisWalletRuntimeEvent();
}

final class XelisWalletOnline extends XelisWalletRuntimeEvent {
  const XelisWalletOnline();
}

final class XelisWalletOffline extends XelisWalletRuntimeEvent {
  const XelisWalletOffline();
}

/// Non-terminal synchronization issue reported by `xelis-wallet`.
///
/// Upstream currently exposes only an unstructured message. [failure] therefore
/// uses a conservative `operation.failed` classification. Its
/// `diagnosticMessage` is privileged and must not be displayed or logged by
/// default. Consumers should wait for a subsequent offline event before
/// deciding to reconnect.
final class XelisWalletSyncIssue extends XelisWalletRuntimeEvent {
  const XelisWalletSyncIssue({required this.failure});

  final XelisWalletException failure;
}

final class XelisWalletTopoheightChanged extends XelisWalletRuntimeEvent {
  const XelisWalletTopoheightChanged({required this.topoheight});

  final BigInt topoheight;
}

final class XelisWalletRescanStarted extends XelisWalletRuntimeEvent {
  const XelisWalletRescanStarted({required this.startTopoheight});

  final BigInt startTopoheight;
}

final class XelisWalletHistorySynced extends XelisWalletRuntimeEvent {
  const XelisWalletHistorySynced({required this.topoheight});

  final BigInt topoheight;
}

/// Signals that upstream events were lost before this frame.
///
/// The stream remains usable. Consumers must treat derived state as stale and
/// perform one coalesced authoritative reconciliation for the same generation.
final class XelisWalletEventStreamDegraded extends XelisWalletRuntimeEvent {
  const XelisWalletEventStreamDegraded({
    required this.skippedEvents,
    required this.failure,
  });

  final BigInt skippedEvents;
  final XelisWalletException failure;
}

enum XelisWalletRuntimeStreamCloseReason { nativeChannelClosed }

/// Terminal event emitted once when the native upstream channel closes while
/// this subscription is still active.
///
/// Explicit [XelisWalletRuntimeEventSubscription.cancel] does not emit this
/// event. Consequently [failure] is suitable for support diagnostics when an
/// active consumer receives it.
final class XelisWalletEventStreamClosed extends XelisWalletRuntimeEvent {
  const XelisWalletEventStreamClosed({
    required this.reason,
    required this.failure,
  });

  final XelisWalletRuntimeStreamCloseReason reason;
  final XelisWalletException failure;
}
