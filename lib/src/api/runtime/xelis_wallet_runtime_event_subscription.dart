import 'xelis_wallet_runtime_event.dart';

/// One native, generation-scoped runtime-event subscription.
///
/// [events] is a single-subscription stream. Call and await [cancel] before a
/// connection rotation. Cancellation is idempotent, wakes an in-flight native
/// read, prevents later callbacks, and releases the private bridge handle.
abstract interface class XelisWalletRuntimeEventSubscription {
  BigInt get generation;

  Stream<XelisWalletRuntimeEventFrame> get events;

  bool get isCancelled;

  Future<void> cancel();
}
