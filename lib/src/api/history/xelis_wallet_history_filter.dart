import '../address/xelis_address_descriptor.dart';

/// Filters and paginates explicit wallet-history reads.
///
/// Pagination is one-based. Topoheights and timestamps remain lossless on all
/// Flutter targets. Timestamps are expressed in Unix milliseconds.
///
/// [destination] is the lossless address filter. A standard descriptor keeps
/// the historical counterparty semantics, while an integrated descriptor
/// matches the exact base address and integrated data.
final class XelisWalletHistoryFilter {
  XelisWalletHistoryFilter({
    required this.page,
    this.limit,
    this.assetHash,
    this.destination,
    this.minTopoheight,
    this.maxTopoheight,
    this.acceptIncoming = true,
    this.acceptOutgoing = true,
    this.acceptCoinbase = true,
    this.acceptBurn = true,
    this.acceptBlob = true,
    this.minTimestampMillis,
    this.maxTimestampMillis,
  });

  final BigInt page;
  final BigInt? limit;
  final String? assetHash;

  /// Complete standard or integrated address to match.
  ///
  /// For an integrated address, native history filtering compares the base
  /// address and exact protocol-serialized data before pagination. The payload
  /// is never returned merely because it participates in this filter.
  final XelisAddressDescriptor? destination;

  /// Complete encoded address forwarded to the private native bridge.
  String? get encodedAddress => destination?.encodedAddress;

  final BigInt? minTopoheight;
  final BigInt? maxTopoheight;
  final bool acceptIncoming;
  final bool acceptOutgoing;
  final bool acceptCoinbase;
  final bool acceptBurn;
  final bool acceptBlob;
  final BigInt? minTimestampMillis;
  final BigInt? maxTimestampMillis;
}
