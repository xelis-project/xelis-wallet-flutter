import 'xelis_wallet_business_event.dart';

/// Session-scoped, single-listener business-event subscription.
abstract interface class XelisWalletBusinessEventSubscription {
  BigInt get generation;

  Stream<XelisWalletBusinessEventFrame> get events;

  bool get isCancelled;

  /// Cancels native delivery, wakes an in-flight read, and releases the
  /// subscription handle. Repeated calls share the same operation.
  Future<void> cancel();
}
