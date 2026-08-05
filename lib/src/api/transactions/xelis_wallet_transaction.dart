import '../data/xelis_data_element.dart';

/// Confirmed transaction emitted by the native wallet.
///
/// Hashes use their canonical hexadecimal representation. Monetary [BigInt]
/// values nested below this record use atomic units and remain lossless on Web.
final class XelisWalletTransactionEntry {
  const XelisWalletTransactionEntry({
    required this.hash,
    required this.topoheight,
    required this.timestampMillis,
    required this.entry,
  });

  /// Canonical hexadecimal transaction hash.
  final String hash;

  /// Topological height at which the transaction was confirmed.
  final BigInt topoheight;

  /// Native wallet timestamp in milliseconds.
  final BigInt timestampMillis;

  /// Typed wallet-history entry.
  final XelisWalletTransactionEntryData entry;
}

/// Transaction known locally but not yet confirmed.
///
/// Hashes use their canonical hexadecimal representation. Monetary [BigInt]
/// values nested below this record use atomic units and remain lossless on Web.
final class XelisWalletPendingTransaction {
  const XelisWalletPendingTransaction({
    required this.hash,
    required this.timestampMillis,
    required this.entry,
  });

  /// Canonical hexadecimal transaction hash.
  final String hash;

  /// Native wallet creation timestamp in milliseconds.
  final BigInt timestampMillis;

  /// Typed wallet-history entry.
  final XelisWalletTransactionEntryData entry;
}

/// Base type for the wallet's transaction-history entry variants.
///
/// Asset and contract identifiers are canonical hexadecimal hashes, addresses
/// are canonical network strings, and monetary values are atomic units of
/// their corresponding asset unless a field says otherwise.
sealed class XelisWalletTransactionEntryData {
  const XelisWalletTransactionEntryData();
}

/// Block reward credited to the wallet, in atomic XELIS units.
final class XelisWalletCoinbaseEntry extends XelisWalletTransactionEntryData {
  const XelisWalletCoinbaseEntry({required this.reward});

  final BigInt reward;
}

/// Asset burn submitted by the wallet.
final class XelisWalletBurnEntry extends XelisWalletTransactionEntryData {
  const XelisWalletBurnEntry({
    required this.asset,
    required this.amount,
    required this.fee,
    required this.nonce,
  });

  final String asset;
  final BigInt amount;
  final BigInt fee;
  final BigInt nonce;
}

/// Transfers received from a canonical network address.
final class XelisWalletIncomingEntry extends XelisWalletTransactionEntryData {
  XelisWalletIncomingEntry({
    required this.from,
    required List<XelisWalletTransferIn> transfers,
  }) : transfers = List.unmodifiable(transfers);

  final String from;
  final List<XelisWalletTransferIn> transfers;
}

/// Transfers sent by the wallet.
final class XelisWalletOutgoingEntry extends XelisWalletTransactionEntryData {
  XelisWalletOutgoingEntry({
    required List<XelisWalletTransferOut> transfers,
    required this.fee,
    required this.nonce,
  }) : transfers = List.unmodifiable(transfers);

  final List<XelisWalletTransferOut> transfers;
  final BigInt fee;
  final BigInt nonce;
}

/// Multisig configuration transaction submitted by the wallet.
final class XelisWalletMultisigEntry extends XelisWalletTransactionEntryData {
  XelisWalletMultisigEntry({
    required List<String> participants,
    required this.threshold,
    required this.fee,
    required this.nonce,
  }) : participants = List.unmodifiable(participants);

  final List<String> participants;
  final int threshold;
  final BigInt fee;
  final BigInt nonce;
}

/// Smart-contract invocation submitted by the wallet.
final class XelisWalletInvokeContractEntry
    extends XelisWalletTransactionEntryData {
  XelisWalletInvokeContractEntry({
    required this.contract,
    required List<XelisWalletAssetAmount> deposits,
    required List<XelisWalletContractTransferGroup> received,
    required this.chunkId,
    required this.fee,
    required this.maxGas,
    required this.nonce,
  }) : deposits = List.unmodifiable(deposits),
       received = List.unmodifiable(received);

  final String contract;
  final List<XelisWalletAssetAmount> deposits;
  final List<XelisWalletContractTransferGroup> received;
  final int chunkId;
  final BigInt fee;
  final BigInt maxGas;
  final BigInt nonce;
}

/// Smart-contract deployment submitted by the wallet.
final class XelisWalletDeployContractEntry
    extends XelisWalletTransactionEntryData {
  const XelisWalletDeployContractEntry({
    required this.fee,
    required this.nonce,
    this.invoke,
  });

  final BigInt fee;
  final BigInt nonce;
  final XelisWalletDeployInvoke? invoke;
}

/// Transfers received by the wallet from a smart contract.
final class XelisWalletIncomingContractEntry
    extends XelisWalletTransactionEntryData {
  XelisWalletIncomingContractEntry({
    required List<XelisWalletContractTransferGroup> transfers,
  }) : transfers = List.unmodifiable(transfers);

  final List<XelisWalletContractTransferGroup> transfers;
}

/// Outgoing blob transaction with redacted extra-data metadata.
final class XelisWalletOutgoingBlobEntry
    extends XelisWalletTransactionEntryData {
  XelisWalletOutgoingBlobEntry({
    required List<String> destinations,
    required this.fee,
    required this.nonce,
    required this.data,
  }) : destinations = List.unmodifiable(destinations);

  final List<String> destinations;
  final BigInt fee;
  final BigInt nonce;
  final XelisWalletExtraData data;
}

/// Incoming blob transaction with redacted extra-data metadata.
final class XelisWalletIncomingBlobEntry
    extends XelisWalletTransactionEntryData {
  XelisWalletIncomingBlobEntry({
    required this.from,
    required List<String> destinations,
    required this.data,
  }) : destinations = List.unmodifiable(destinations);

  final String from;
  final List<String> destinations;
  final XelisWalletExtraData data;
}

/// One received asset amount, expressed in the asset's atomic units.
final class XelisWalletTransferIn {
  const XelisWalletTransferIn({
    required this.asset,
    required this.amount,
    this.extraData,
  });

  final String asset;
  final BigInt amount;
  final XelisWalletExtraData? extraData;
}

/// One sent asset amount, expressed in the asset's atomic units.
final class XelisWalletTransferOut {
  const XelisWalletTransferOut({
    required this.destination,
    required this.asset,
    required this.amount,
    this.extraData,
  });

  final String destination;
  final String asset;
  final BigInt amount;
  final XelisWalletExtraData? extraData;
}

/// Metadata about transaction extra data.
///
/// [payload] contains the lossless tagged representation only for a detailed
/// explicit read. It can contain application data and is therefore potentially
/// sensitive: do not include it in standard logs.
/// [payloadKind] is available from metadata reads without revealing the value.
/// Passive business events always set all three detail fields to `null`. The
/// upstream shared encryption key never crosses the package boundary.
final class XelisWalletExtraData {
  const XelisWalletExtraData({
    required this.flag,
    required this.hasPayload,
    this.payload,
    this.payloadKind,
  });

  final XelisWalletExtraDataFlag flag;
  final bool hasPayload;

  /// Lossless tagged payload returned by a detailed explicit read.
  ///
  /// This can contain sensitive application data and must not be included in
  /// standard logs or persisted implicitly.
  final XelisDataElement? payload;

  final XelisWalletExtraDataPayloadKind? payloadKind;
}

/// Amount of extra-data information requested by an explicit wallet read.
enum XelisWalletExtraDataDisclosure {
  /// Returns flag, payload presence, and top-level kind without payload data.
  metadata,

  /// Also returns the lossless tagged payload.
  ///
  /// This can contain sensitive application data and is intended for explicit
  /// detail or reveal flows only.
  detailed,
}

enum XelisWalletExtraDataFlag { private, public, proprietary, failed }

/// Stable top-level kind of an explicit extra-data payload.
///
/// [unknown] is reserved for forward-compatible native variants.
enum XelisWalletExtraDataPayloadKind {
  boolValue,
  string,
  u8,
  u16,
  u32,
  u64,
  u128,
  hash,
  blob,
  array,
  fields,
  unknown,
}

/// An asset amount expressed in that asset's atomic units.
final class XelisWalletAssetAmount {
  const XelisWalletAssetAmount({required this.asset, required this.amount});

  final String asset;
  final BigInt amount;
}

/// Asset transfers grouped by their canonical hexadecimal contract hash.
final class XelisWalletContractTransferGroup {
  XelisWalletContractTransferGroup({
    required this.contract,
    required List<XelisWalletAssetAmount> transfers,
  }) : transfers = List.unmodifiable(transfers);

  final String contract;
  final List<XelisWalletAssetAmount> transfers;
}

/// Optional invocation attached to a contract deployment.
final class XelisWalletDeployInvoke {
  XelisWalletDeployInvoke({
    required this.maxGas,
    required List<XelisWalletAssetAmount> deposits,
  }) : deposits = List.unmodifiable(deposits);

  final BigInt maxGas;
  final List<XelisWalletAssetAmount> deposits;
}
