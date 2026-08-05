/// Versioning information for the stable XELIS wallet error contract.
abstract final class XelisWalletErrorContract {
  /// Current version of the structured error contract.
  static const currentVersion = 1;
}

/// Component that originally classified an error.
enum XelisWalletErrorSource {
  xelisWalletFlutter,
  xelisWallet,
  xelisCommon,
  flutterRustBridge,
  platform,
  dependency,
  unknown,
}

/// Stable, non-exhaustive identifier for an error category.
///
/// This is intentionally a value class instead of an enum. New codes can be
/// added without forcing applications to update exhaustive switches.
final class XelisWalletErrorCode {
  const XelisWalletErrorCode._(this.id);

  final String id;

  static const operationFailed = XelisWalletErrorCode._('operation.failed');
  static const streamLagged = XelisWalletErrorCode._('stream.lagged');
  static const streamClosedUnexpectedly = XelisWalletErrorCode._(
    'stream.closed_unexpectedly',
  );
  static const invalidInput = XelisWalletErrorCode._('input.invalid');
  static const authenticationOrCorruptData = XelisWalletErrorCode._(
    'wallet.authentication_or_corrupt_data',
  );
  static const offline = XelisWalletErrorCode._('wallet.offline');
  static const networkFailure = XelisWalletErrorCode._('network.failed');
  static const networkMismatch = XelisWalletErrorCode._('network.mismatch');
  static const daemonRejected = XelisWalletErrorCode._('daemon.rejected');
  static const insufficientFunds = XelisWalletErrorCode._(
    'balance.insufficient_funds',
  );
  static const conflict = XelisWalletErrorCode._('state.conflict');
  static const operationInProgress = XelisWalletErrorCode._(
    'state.operation_in_progress',
  );
  static const notFound = XelisWalletErrorCode._('resource.not_found');
  static const unsupported = XelisWalletErrorCode._('operation.unsupported');
  static const storageFailure = XelisWalletErrorCode._('storage.failed');
  static const serializationFailure = XelisWalletErrorCode._(
    'serialization.failed',
  );
  static const cancelled = XelisWalletErrorCode._('operation.cancelled');
  static const initializationFailure = XelisWalletErrorCode._(
    'initialization.failed',
  );
  static const internal = XelisWalletErrorCode._('internal.failed');
  static const unsupportedPlatform = XelisWalletErrorCode._(
    'bridge.unsupported_platform',
  );
  static const nativePanic = XelisWalletErrorCode._('bridge.native_panic');
  static const bridgeFailure = XelisWalletErrorCode._('bridge.failed');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XelisWalletErrorCode && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Stable identifier for the operation that crossed the package boundary.
final class XelisWalletOperation {
  const XelisWalletOperation._(this.id);

  final String id;

  static const runtimeInitialize = XelisWalletOperation._('runtime.initialize');
  static const configurationInitialize = XelisWalletOperation._(
    'configuration.initialize',
  );
  static const cryptoProviderInitialize = XelisWalletOperation._(
    'crypto_provider.initialize',
  );
  static const loggingInitialize = XelisWalletOperation._('logging.initialize');
  static const loggingStream = XelisWalletOperation._('logging.stream');
  static const progressStream = XelisWalletOperation._('progress.stream');
  static const seedSearchCreate = XelisWalletOperation._('seed_search.create');
  static const seedSearch = XelisWalletOperation._('seed_search.search');
  static const seedValidate = XelisWalletOperation._('seed_search.validate');
  static const seedSearchDispose = XelisWalletOperation._(
    'seed_search.dispose',
  );
  static const walletCreate = XelisWalletOperation._('wallet.create');
  static const walletRecoverSeed = XelisWalletOperation._(
    'wallet.recover.seed',
  );
  static const walletRecoverPrivateKey = XelisWalletOperation._(
    'wallet.recover.private_key',
  );
  static const walletOpen = XelisWalletOperation._('wallet.open');
  static const walletAddressRead = XelisWalletOperation._(
    'wallet.address.read',
  );
  static const walletNetworkRead = XelisWalletOperation._(
    'wallet.network.read',
  );
  static const walletNetworkConnect = XelisWalletOperation._(
    'wallet.network.connect',
  );
  static const walletNetworkDisconnect = XelisWalletOperation._(
    'wallet.network.disconnect',
  );
  static const walletNetworkStatusRead = XelisWalletOperation._(
    'wallet.network.status.read',
  );
  static const walletSyncStatusRead = XelisWalletOperation._(
    'wallet.sync.status.read',
  );
  static const walletSync = XelisWalletOperation._('wallet.sync');
  static const walletXswdStart = XelisWalletOperation._('wallet.xswd.start');
  static const walletXswdStop = XelisWalletOperation._('wallet.xswd.stop');
  static const walletXswdStateRead = XelisWalletOperation._(
    'wallet.xswd.state.read',
  );
  static const walletXswdRelayerAdd = XelisWalletOperation._(
    'wallet.xswd.relayer.add',
  );
  static const walletXswdSessionClose = XelisWalletOperation._(
    'wallet.xswd.session.close',
  );
  static const walletXswdPermissionsUpdate = XelisWalletOperation._(
    'wallet.xswd.permissions.update',
  );
  static const walletEventsSubscribe = XelisWalletOperation._(
    'wallet.events.subscribe',
  );
  static const walletEventsStream = XelisWalletOperation._(
    'wallet.events.stream',
  );
  static const walletEventsCancel = XelisWalletOperation._(
    'wallet.events.cancel',
  );
  static const walletBusinessEventsSubscribe = XelisWalletOperation._(
    'wallet.business_events.subscribe',
  );
  static const walletBusinessEventsStream = XelisWalletOperation._(
    'wallet.business_events.stream',
  );
  static const walletBusinessEventsCancel = XelisWalletOperation._(
    'wallet.business_events.cancel',
  );
  static const walletBalanceRead = XelisWalletOperation._(
    'wallet.balance.xelis.read',
  );
  static const walletTrackedBalancesRead = XelisWalletOperation._(
    'wallet.balances.tracked.read',
  );
  static const walletKnownAssetsRead = XelisWalletOperation._(
    'wallet.assets.known.read',
  );
  static const walletAssetMetadataRead = XelisWalletOperation._(
    'wallet.asset.metadata.read',
  );
  static const walletAssetTrack = XelisWalletOperation._('wallet.asset.track');
  static const walletAssetUntrack = XelisWalletOperation._(
    'wallet.asset.untrack',
  );
  static const walletAddressBookMigrate = XelisWalletOperation._(
    'wallet.address_book.migrate',
  );
  static const walletAddressBookList = XelisWalletOperation._(
    'wallet.address_book.list',
  );
  static const walletAddressBookUpsert = XelisWalletOperation._(
    'wallet.address_book.upsert',
  );
  static const walletAddressBookRemove = XelisWalletOperation._(
    'wallet.address_book.remove',
  );
  static const walletAddressBookFind = XelisWalletOperation._(
    'wallet.address_book.find',
  );
  static const walletAddressBookMatch = XelisWalletOperation._(
    'wallet.address_book.match',
  );
  static const walletHistoryCountRead = XelisWalletOperation._(
    'wallet.history.count.read',
  );
  static const walletHistoryRead = XelisWalletOperation._(
    'wallet.history.read',
  );
  static const walletHistoryCsvConvert = XelisWalletOperation._(
    'wallet.history.csv.convert',
  );
  static const walletHistoryCsvExport = XelisWalletOperation._(
    'wallet.history.csv.export',
  );
  static const walletHistoryTransactionRead = XelisWalletOperation._(
    'wallet.history.transaction.read',
  );
  static const walletPendingTransactionsRead = XelisWalletOperation._(
    'wallet.transactions.pending.read',
  );
  static const walletPendingTransactionRead = XelisWalletOperation._(
    'wallet.transactions.pending.transaction.read',
  );
  static const walletMultisigStateRead = XelisWalletOperation._(
    'wallet.multisig.state.read',
  );
  static const walletMultisigSetupPrepare = XelisWalletOperation._(
    'wallet.multisig.setup.prepare',
  );
  static const walletMultisigParticipantValidate = XelisWalletOperation._(
    'wallet.multisig.participant.validate',
  );
  static const walletMultisigTransfersPrepare = XelisWalletOperation._(
    'wallet.multisig.transfers.prepare',
  );
  static const walletMultisigTransferAllPrepare = XelisWalletOperation._(
    'wallet.multisig.transfer_all.prepare',
  );
  static const walletMultisigBurnPrepare = XelisWalletOperation._(
    'wallet.multisig.burn.prepare',
  );
  static const walletMultisigBurnAllPrepare = XelisWalletOperation._(
    'wallet.multisig.burn_all.prepare',
  );
  static const walletMultisigDeletePrepare = XelisWalletOperation._(
    'wallet.multisig.delete.prepare',
  );
  static const walletMultisigRequestInspect = XelisWalletOperation._(
    'wallet.multisig.request.inspect',
  );
  static const walletMultisigRequestSign = XelisWalletOperation._(
    'wallet.multisig.request.sign',
  );
  static const walletMultisigShareInspect = XelisWalletOperation._(
    'wallet.multisig.share.inspect',
  );
  static const walletMultisigFinalize = XelisWalletOperation._(
    'wallet.multisig.finalize',
  );
  static const walletMultisigRequestCancel = XelisWalletOperation._(
    'wallet.multisig.request.cancel',
  );
  static const walletTransactionFeesEstimate = XelisWalletOperation._(
    'wallet.transaction.fees.estimate',
  );
  static const walletTransactionTransfersPrepare = XelisWalletOperation._(
    'wallet.transaction.transfers.prepare',
  );
  static const walletTransactionTransferAllPrepare = XelisWalletOperation._(
    'wallet.transaction.transfer_all.prepare',
  );
  static const walletTransactionBurnPrepare = XelisWalletOperation._(
    'wallet.transaction.burn.prepare',
  );
  static const walletTransactionBurnAllPrepare = XelisWalletOperation._(
    'wallet.transaction.burn_all.prepare',
  );
  static const walletTransactionPreparedCancel = XelisWalletOperation._(
    'wallet.transaction.prepared.cancel',
  );
  static const walletTransactionPreparedInspect = XelisWalletOperation._(
    'wallet.transaction.prepared.inspect',
  );
  static const walletTransactionBroadcast = XelisWalletOperation._(
    'wallet.transaction.broadcast',
  );
  static const walletRescan = XelisWalletOperation._('wallet.rescan');
  static const walletDaemonInfoRead = XelisWalletOperation._(
    'wallet.daemon.info.read',
  );
  static const walletSeedRead = XelisWalletOperation._('wallet.seed.read');
  static const walletPasswordVerify = XelisWalletOperation._(
    'wallet.password.verify',
  );
  static const walletPasswordChange = XelisWalletOperation._(
    'wallet.password.change',
  );
  static const addressValidate = XelisWalletOperation._('address.validate');
  static const addressParse = XelisWalletOperation._('address.parse');
  static const addressIntegratedCreate = XelisWalletOperation._(
    'address.integrated.create',
  );
  static const precomputedTablesCheck = XelisWalletOperation._(
    'precomputed_tables.check',
  );
  static const precomputedTablesUpdate = XelisWalletOperation._(
    'precomputed_tables.update',
  );
  static const walletClose = XelisWalletOperation._('wallet.close');
  static const walletDispose = XelisWalletOperation._('wallet.dispose');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XelisWalletOperation && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Base exception exposed by the stable XELIS wallet Flutter API.
///
/// [source], [operation], [code], and [supportId] are safe identifiers intended
/// for control flow, user-facing support references, and standard logs.
/// [diagnosticMessage] may contain paths, amounts, hashes, or other operational
/// context. Only expose it through an explicit diagnostic/support workflow.
abstract class XelisWalletException implements Exception {
  const XelisWalletException({
    required this.source,
    required this.operation,
    required this.code,
    required this.supportId,
    this.diagnosticMessage,
    this.nativeKind,
    this.nativeCode,
    this.contractVersion = XelisWalletErrorContract.currentVersion,
  });

  final int contractVersion;
  final XelisWalletErrorSource source;
  final XelisWalletOperation operation;
  final XelisWalletErrorCode code;
  final String supportId;

  /// Full diagnostic detail from the failing layer, when available.
  ///
  /// This value is deliberately omitted from [toString]. Treat it as
  /// potentially sensitive even when it originates from audited Rust crates.
  final String? diagnosticMessage;

  /// Stable native discriminant, when the Rust layer exposes one.
  final String? nativeKind;

  /// Native numeric error code, such as a JSON-RPC server code.
  final int? nativeCode;

  @override
  String toString() =>
      '$runtimeType('
      'source=${source.name}, '
      'operation=${operation.id}, '
      'code=${code.id}, '
      'supportId=$supportId)';
}

/// An expected native operation failure returned through Rust `Result`.
final class XelisWalletOperationException extends XelisWalletException {
  const XelisWalletOperationException({
    required super.source,
    required super.operation,
    required super.code,
    required super.supportId,
    super.diagnosticMessage,
    super.nativeKind,
    super.nativeCode,
    super.contractVersion,
  });
}

/// A bridge, platform, disposal, or native panic failure.
final class XelisWalletBridgeException extends XelisWalletException {
  const XelisWalletBridgeException({
    required super.source,
    required super.operation,
    required super.code,
    required super.supportId,
    super.diagnosticMessage,
    super.nativeKind,
    super.nativeCode,
    super.contractVersion,
  });
}
