import '../errors/xelis_wallet_exception.dart';

import '../data/xelis_data_element.dart';
import '../multisig/xelis_wallet_multisig.dart';

/// Exact fee policy used while estimating and preparing a transaction.
///
/// The multiplier is expressed in basis points so no floating-point value
/// crosses the public Dart API. One multiplier unit is one ten-thousandth:
/// `10000` is 1x, `15000` is 1.5x, and `20000` is 2x.
sealed class XelisWalletFeePolicy {
  const XelisWalletFeePolicy();

  /// Number of basis points representing the automatically calculated fee.
  static const basisPointsScale = 10000;

  /// Uses the native wallet's automatically calculated fee without a boost.
  static const automatic = XelisWalletAutomaticFeePolicy();

  /// Uses exactly [feeAtomic] atomic units as the transaction fee.
  factory XelisWalletFeePolicy.fixed({required BigInt feeAtomic}) {
    _requireUnsigned64FeeValue(feeAtomic, 'feeAtomic', allowZero: true);
    return XelisWalletFixedFeePolicy._(feeAtomic);
  }

  /// Adds [tipAtomic] atomic units to the native fee estimate.
  factory XelisWalletFeePolicy.tip({required BigInt tipAtomic}) {
    _requireUnsigned64FeeValue(tipAtomic, 'tipAtomic', allowZero: true);
    return XelisWalletTipFeePolicy._(tipAtomic);
  }

  /// Creates an exact fixed-point multiplier expressed in basis points.
  ///
  /// [basisPoints] must be between [minMultiplierBasisPoints] and
  /// [maxMultiplierBasisPoints], inclusive.
  factory XelisWalletFeePolicy.multiplier({required BigInt basisPoints}) {
    _requireUnsigned64FeeValue(basisPoints, 'basisPoints', allowZero: false);
    return XelisWalletMultiplierFeePolicy._(basisPoints);
  }
}

final _maximumUnsigned64 = (BigInt.one << 64) - BigInt.one;

void _requireUnsigned64FeeValue(
  BigInt value,
  String name, {
  required bool allowZero,
}) {
  final minimum = allowZero ? BigInt.zero : BigInt.one;
  if (value < minimum || value > _maximumUnsigned64) {
    throw RangeError(
      '$name must be between $minimum and $_maximumUnsigned64; received $value.',
    );
  }
}

final class XelisWalletAutomaticFeePolicy extends XelisWalletFeePolicy {
  const XelisWalletAutomaticFeePolicy();

  @override
  String toString() => 'XelisWalletFeePolicy.automatic';
}

final class XelisWalletFixedFeePolicy extends XelisWalletFeePolicy {
  const XelisWalletFixedFeePolicy._(this.feeAtomic);

  final BigInt feeAtomic;

  @override
  bool operator ==(Object other) =>
      other is XelisWalletFixedFeePolicy && other.feeAtomic == feeAtomic;

  @override
  int get hashCode => feeAtomic.hashCode;

  @override
  String toString() => 'XelisWalletFeePolicy.fixed(feeAtomic: $feeAtomic)';
}

final class XelisWalletTipFeePolicy extends XelisWalletFeePolicy {
  const XelisWalletTipFeePolicy._(this.tipAtomic);

  final BigInt tipAtomic;

  @override
  bool operator ==(Object other) =>
      other is XelisWalletTipFeePolicy && other.tipAtomic == tipAtomic;

  @override
  int get hashCode => tipAtomic.hashCode;

  @override
  String toString() => 'XelisWalletFeePolicy.tip(tipAtomic: $tipAtomic)';
}

final class XelisWalletMultiplierFeePolicy extends XelisWalletFeePolicy {
  const XelisWalletMultiplierFeePolicy._(this.basisPoints);

  /// Exact fixed-point multiplier sent to the native wallet.
  final BigInt basisPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisWalletMultiplierFeePolicy &&
          other.basisPoints == basisPoints;

  @override
  int get hashCode => basisPoints.hashCode;

  @override
  String toString() =>
      'XelisWalletFeePolicy.multiplier(basisPoints: $basisPoints)';
}

/// One exact transfer requested from the native wallet.
///
/// [amountAtomic] is expressed in the asset's atomic units and must fit the
/// native unsigned 64-bit amount range. Consumers must parse decimal user
/// input exactly before constructing this value; they must not pass through a
/// floating-point conversion.
final class XelisWalletTransferRequest {
  const XelisWalletTransferRequest({
    required this.destination,
    required this.asset,
    required this.amountAtomic,
    this.extraData,
    this.encryptExtraData = true,
  });

  /// Canonical destination address, including integrated-address data.
  final String destination;

  /// Canonical hexadecimal asset hash.
  final String asset;

  /// Amount in the asset's atomic units.
  final BigInt amountAtomic;

  /// Optional application data attached to the transfer.
  ///
  /// This value can be sensitive and must not be included in standard logs.
  final String? extraData;

  /// Whether [extraData] is encrypted for its destination.
  final bool encryptExtraData;
}

/// Transaction prepared and held by one native wallet instance.
///
/// [hash], [feeAtomic], and [details] describe the exact prepared transaction
/// that can be passed to `broadcastPreparedTransaction` or
/// `discardPreparedTransaction`. Consumers must retain this object through
/// review instead of reconstructing it from displayed strings.
final class XelisWalletPreparedTransaction {
  const XelisWalletPreparedTransaction({
    required this.hash,
    required this.feeAtomic,
    required this.details,
  });

  /// Canonical hexadecimal hash of the prepared transaction.
  final String hash;

  /// Actual fee encoded in the prepared transaction, in atomic XELIS units.
  final BigInt feeAtomic;

  /// Typed, lossless details used for user review.
  final XelisWalletPreparedTransactionDetails details;
}

/// Base type for prepared transaction review details.
sealed class XelisWalletPreparedTransactionDetails {
  const XelisWalletPreparedTransactionDetails();
}

/// One transfer contained in prepared transaction review details.
final class XelisWalletPreparedTransfer {
  const XelisWalletPreparedTransfer({
    required this.destination,
    required this.asset,
    required this.amountAtomic,
    required this.hasExtraData,
    required this.extraDataEncrypted,
  });

  final String destination;
  final String asset;
  final BigInt amountAtomic;

  /// Whether application data is attached to this transfer.
  ///
  /// The payload itself is deliberately absent from prepared review details.
  final bool hasExtraData;

  /// Whether the attached application data is encrypted.
  final bool extraDataEncrypted;
}

/// Origin of the effective extra data attached to a prepared transfer.
enum XelisWalletPreparedExtraDataSource {
  /// The data was encoded directly in the destination address.
  integratedAddress,

  /// The caller supplied a separate application-data value.
  explicit,
}

/// Explicitly revealed extra data for one exact prepared transfer.
///
/// This type is returned only by the capability-bound inspection method. Its
/// [toString] deliberately omits [data] so standard diagnostic logs cannot
/// expose application content accidentally.
final class XelisWalletPreparedTransferExtraData {
  const XelisWalletPreparedTransferExtraData({
    required this.data,
    required this.source,
    required this.encrypted,
  });

  final XelisDataElement data;
  final XelisWalletPreparedExtraDataSource source;
  final bool encrypted;

  @override
  String toString() =>
      'XelisWalletPreparedTransferExtraData('
      'source: $source, encrypted: $encrypted, data: <redacted>)';
}

/// Typed review details for a transaction containing transfers.
final class XelisWalletPreparedTransfers
    extends XelisWalletPreparedTransactionDetails {
  XelisWalletPreparedTransfers({
    required List<XelisWalletPreparedTransfer> transfers,
  }) : transfers = List.unmodifiable(transfers);

  final List<XelisWalletPreparedTransfer> transfers;
}

/// Typed review details for an asset burn.
final class XelisWalletPreparedBurn
    extends XelisWalletPreparedTransactionDetails {
  const XelisWalletPreparedBurn({
    required this.asset,
    required this.amountAtomic,
  });

  final String asset;
  final BigInt amountAtomic;
}

/// Typed review details for creating a new multisig configuration.
final class XelisWalletPreparedMultisigSetup
    extends XelisWalletPreparedTransactionDetails {
  XelisWalletPreparedMultisigSetup({
    required this.threshold,
    required List<XelisWalletMultisigParticipant> participants,
  }) : participants = List.unmodifiable(participants);

  final int threshold;
  final List<XelisWalletMultisigParticipant> participants;
}

/// Typed review details for a finalized multisig transaction.
final class XelisWalletPreparedMultisigTransaction
    extends XelisWalletPreparedTransactionDetails {
  const XelisWalletPreparedMultisigTransaction({required this.transaction});

  final XelisWalletMultisigSigningTransaction transaction;
}

/// Result of submitting one exact prepared transaction.
///
/// The five variants are exhaustive. Any attached [XelisWalletException]
/// retains its package-owned support reference and classification. Contract or
/// bridge failures for which no submission outcome can be asserted are thrown
/// instead of being represented by this type.
sealed class XelisWalletBroadcastResult {
  const XelisWalletBroadcastResult();
}

/// The transaction was submitted and removed from the prepared store.
final class XelisWalletBroadcastSubmitted extends XelisWalletBroadcastResult {
  const XelisWalletBroadcastSubmitted();
}

/// Submission was interrupted by a reviewed retryable failure.
///
/// The exact prepared transaction remains available for an explicit retry.
final class XelisWalletBroadcastRetryable extends XelisWalletBroadcastResult {
  const XelisWalletBroadcastRetryable({required this.failure});

  final XelisWalletException failure;
}

/// The daemon rejected the transaction and the prepared value was discarded.
final class XelisWalletBroadcastRejected extends XelisWalletBroadcastResult {
  const XelisWalletBroadcastRejected({required this.failure});

  final XelisWalletException failure;
}

/// Submission failed locally and the prepared value was discarded.
final class XelisWalletBroadcastLocalFailure
    extends XelisWalletBroadcastResult {
  const XelisWalletBroadcastLocalFailure({required this.failure});

  final XelisWalletException failure;
}

/// The transaction was submitted, but local wallet state needs reconciliation.
///
/// The prepared value was consumed and must never be broadcast again.
final class XelisWalletBroadcastSubmittedNeedsResync
    extends XelisWalletBroadcastResult {
  const XelisWalletBroadcastSubmittedNeedsResync({required this.failure});

  final XelisWalletException failure;
}
