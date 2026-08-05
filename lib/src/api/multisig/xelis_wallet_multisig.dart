import '../models/xelis_network.dart';

/// One participant in the canonical active multisig configuration.
final class XelisWalletMultisigParticipant {
  const XelisWalletMultisigParticipant({
    required this.id,
    required this.address,
  });

  final int id;
  final String address;
}

/// Lossless active multisig state read from wallet storage.
final class XelisWalletMultisigState {
  XelisWalletMultisigState({
    required this.threshold,
    required List<XelisWalletMultisigParticipant> participants,
    required this.topoheight,
  }) : participants = List.unmodifiable(participants);

  final int threshold;
  final List<XelisWalletMultisigParticipant> participants;
  final BigInt topoheight;
}

/// Typed transaction review carried by a canonical multisig signing request.
sealed class XelisWalletMultisigSigningTransaction {
  const XelisWalletMultisigSigningTransaction();
}

/// One transfer disclosed for multisig review without revealing its payload.
final class XelisWalletMultisigSigningTransfer {
  const XelisWalletMultisigSigningTransfer({
    required this.destination,
    required this.asset,
    required this.amountAtomic,
    required this.hasExtraData,
  });

  final String destination;
  final String asset;
  final BigInt amountAtomic;
  final bool hasExtraData;
}

/// Multisig request containing one or more transfers.
final class XelisWalletMultisigTransfers
    extends XelisWalletMultisigSigningTransaction {
  XelisWalletMultisigTransfers({
    required List<XelisWalletMultisigSigningTransfer> transfers,
  }) : transfers = List.unmodifiable(transfers);

  final List<XelisWalletMultisigSigningTransfer> transfers;
}

/// Multisig request burning an exact atomic asset amount.
final class XelisWalletMultisigBurn
    extends XelisWalletMultisigSigningTransaction {
  const XelisWalletMultisigBurn({
    required this.asset,
    required this.amountAtomic,
  });

  final String asset;
  final BigInt amountAtomic;
}

/// Multisig request deleting the active configuration.
final class XelisWalletMultisigDelete
    extends XelisWalletMultisigSigningTransaction {
  const XelisWalletMultisigDelete();
}

/// Canonical, source-attested request that participants inspect and sign.
///
/// Source-wallet cancellation and finalization, as well as participant-side
/// signing, require the exact object returned by the wallet. Reconstructing an
/// equal-looking value does not recreate its private capability.
final class XelisWalletMultisigSigningRequest {
  XelisWalletMultisigSigningRequest({
    required this.encoded,
    required this.signingHash,
    required this.source,
    required this.network,
    required this.feeAtomic,
    required this.feeLimitAtomic,
    required this.nonce,
    required this.referenceTopoheight,
    required this.threshold,
    required List<XelisWalletMultisigParticipant> participants,
    required this.participantId,
    required this.transaction,
  }) : participants = List.unmodifiable(participants);

  final String encoded;
  final String signingHash;
  final String source;
  final XelisNetwork network;
  final BigInt feeAtomic;
  final BigInt feeLimitAtomic;
  final BigInt nonce;
  final BigInt referenceTopoheight;
  final int threshold;
  final List<XelisWalletMultisigParticipant> participants;

  /// ID of the opened wallet in this configuration, when it is a participant.
  final int? participantId;

  final XelisWalletMultisigSigningTransaction transaction;
}

/// Canonical participant signature share verified for one exact pending request.
///
/// A source wallet must obtain this object through
/// `inspectMultisigSignatureShare`; reconstructing it cannot authorize
/// finalization.
final class XelisWalletMultisigSignatureShare {
  const XelisWalletMultisigSignatureShare({
    required this.encoded,
    required this.signingHash,
    required this.participantId,
    required this.signature,
  });

  final String encoded;
  final String signingHash;
  final int participantId;
  final String signature;
}
