import 'dart:async';

import '../../api/assets/xelis_wallet_asset.dart';
import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/events/xelis_wallet_business_event.dart';
import '../../api/events/xelis_wallet_business_event_subscription.dart';
import '../../api/transactions/xelis_wallet_transaction.dart';
import '../../generated/rust_bridge/api/error.dart' as generated_error;
import '../../generated/rust_bridge/api/models/business_event_dtos.dart'
    as generated_event;
import '../../generated/rust_bridge/api/models/wallet_dtos.dart'
    as generated_wallet;
import '../../generated/rust_bridge/api/wallet/business_events.dart'
    as generated_subscription;
import 'xelis_error_adapter.dart';
import 'xelis_runtime_utility_adapter.dart';

typedef NativeBusinessSubscriptionTerminated = void Function(
  NativeXelisWalletBusinessEventSubscription subscription,
);

/// Private bridge implementation of the authored business-event subscription.
final class NativeXelisWalletBusinessEventSubscription
    implements XelisWalletBusinessEventSubscription {
  NativeXelisWalletBusinessEventSubscription(
    this._delegate, {
    NativeBusinessSubscriptionTerminated? onTerminated,
  }) : _onTerminated = onTerminated {
    generation = guardXelisCall(
      _delegate.generation,
      boundary: _subscribeBoundary,
    );
    _controller = StreamController<XelisWalletBusinessEventFrame>(
      sync: true,
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: cancel,
    );
  }

  static const _subscribeBoundary = XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletBusinessEventsSubscribe,
  );
  static const _streamBoundary = XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletBusinessEventsStream,
  );
  static const _cancelBoundary = XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletBusinessEventsCancel,
  );

  final generated_subscription.WalletBusinessEventSubscription _delegate;
  final NativeBusinessSubscriptionTerminated? _onTerminated;
  late final StreamController<XelisWalletBusinessEventFrame> _controller;

  @override
  late final BigInt generation;

  Future<void>? _pumpFuture;
  Future<void>? _cancelFuture;
  Completer<void>? _resumeCompleter;
  var _expectedSequence = BigInt.one;
  var _paused = false;
  var _cancelRequested = false;
  var _nativeCancelRequested = false;
  var _finalized = false;

  @override
  Stream<XelisWalletBusinessEventFrame> get events => _controller.stream;

  @override
  bool get isCancelled => _cancelRequested;

  @override
  Future<void> cancel() {
    final existing = _cancelFuture;
    if (existing != null) {
      return existing;
    }

    _cancelRequested = true;
    _resumePump();
    final future = _runCancellationAttempt();
    _cancelFuture = future;
    return future;
  }

  Future<void> _runCancellationAttempt() async {
    try {
      await _cancelAndFinalize();
    } catch (_) {
      _cancelFuture = null;
      rethrow;
    }
  }

  void _onListen() {
    final future = _pump();
    _pumpFuture = future;
    unawaited(future);
  }

  void _onPause() {
    if (_cancelRequested) {
      return;
    }
    _paused = true;
    _resumeCompleter ??= Completer<void>();
  }

  void _onResume() {
    _paused = false;
    _resumePump();
  }

  void _resumePump() {
    final completer = _resumeCompleter;
    _resumeCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitWhilePaused() async {
    while (_paused && !_cancelRequested) {
      final completer = _resumeCompleter ??= Completer<void>();
      await completer.future;
    }
  }

  Future<void> _pump() async {
    try {
      while (!_cancelRequested) {
        await _waitWhilePaused();
        if (_cancelRequested) {
          break;
        }

        final nativeFrame = await guardXelisFuture(
          _delegate.nextEvent,
          boundary: _streamBoundary,
        );
        if (_cancelRequested || nativeFrame == null) {
          break;
        }

        await _waitWhilePaused();
        if (_cancelRequested) {
          break;
        }

        final frame = adaptBusinessEventFrame(
          nativeFrame,
          expectedGeneration: generation,
          expectedSequence: _expectedSequence,
        );
        _expectedSequence += BigInt.one;
        _controller.add(frame);
        if (frame.event is XelisWalletBusinessEventStreamClosed) {
          break;
        }
      }
    } catch (error, stackTrace) {
      if (!_cancelRequested && !_controller.isClosed) {
        _controller.addError(error, stackTrace);
      }
    } finally {
      _cancelRequested = true;
      _resumePump();
      try {
        _requestNativeCancel();
      } catch (error, stackTrace) {
        if (!_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      }
      _finalize();
    }
  }

  Future<void> _cancelAndFinalize() async {
    _requestNativeCancel();
    final pump = _pumpFuture;
    if (pump != null) {
      await pump;
    } else {
      _finalize();
    }
  }

  void _requestNativeCancel() {
    if (_nativeCancelRequested) {
      return;
    }
    guardXelisCall(_delegate.cancel, boundary: _cancelBoundary);
    _nativeCancelRequested = true;
  }

  void _finalize() {
    if (_finalized) {
      return;
    }
    _finalized = true;

    try {
      if (!_delegate.isDisposed) {
        guardXelisCall(_delegate.dispose, boundary: _cancelBoundary);
      }
    } catch (error, stackTrace) {
      if (!_controller.isClosed) {
        _controller.addError(error, stackTrace);
      }
    } finally {
      _onTerminated?.call(this);
      if (!_controller.isClosed) {
        unawaited(_controller.close());
      }
    }
  }
}

XelisWalletBusinessEventFrame adaptBusinessEventFrame(
  generated_event.NativeWalletBusinessEventFrame frame, {
  required BigInt expectedGeneration,
  required BigInt expectedSequence,
}) {
  if (frame.version != XelisWalletBusinessEventContract.currentVersion) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletBusinessEventsStream,
      nativeKind: 'NATIVE_BUSINESS_EVENT_CONTRACT_VERSION_${frame.version}',
      diagnosticMessage:
          'Unsupported native business event contract version ${frame.version}.',
    );
  }
  if (frame.generation != expectedGeneration) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletBusinessEventsStream,
      nativeKind: 'NATIVE_BUSINESS_EVENT_GENERATION_MISMATCH',
      diagnosticMessage:
          'Expected business event generation $expectedGeneration but received '
          '${frame.generation}.',
    );
  }
  if (frame.sequence != expectedSequence) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletBusinessEventsStream,
      nativeKind: 'NATIVE_BUSINESS_EVENT_SEQUENCE_MISMATCH',
      diagnosticMessage:
          'Expected business event sequence $expectedSequence but received '
          '${frame.sequence}.',
    );
  }

  return XelisWalletBusinessEventFrame(
    contractVersion: frame.version,
    generation: frame.generation,
    sequence: frame.sequence,
    event: _adaptBusinessEvent(frame.event),
  );
}

XelisWalletBusinessEvent _adaptBusinessEvent(
  generated_event.NativeWalletBusinessEvent event,
) => switch (event) {
  generated_event.NativeWalletBusinessEvent_NewTransaction(
    :final transaction,
  ) =>
    XelisWalletNewTransaction(
      transaction: xelisWalletTransactionFromGenerated(
        transaction,
        includePayload: false,
      ),
    ),
  generated_event.NativeWalletBusinessEvent_NewPendingTransaction(
    :final transaction,
  ) =>
    XelisWalletNewPendingTransaction(
      transaction: xelisWalletPendingTransactionFromGenerated(
        transaction,
        includePayload: false,
      ),
    ),
  generated_event.NativeWalletBusinessEvent_BalanceChanged(
    :final asset,
    :final balance,
  ) =>
    XelisWalletBalanceChanged(asset: asset, balance: balance),
  generated_event.NativeWalletBusinessEvent_NewAsset(:final asset) =>
    XelisWalletNewAsset(asset: _adaptAsset(asset)),
  generated_event.NativeWalletBusinessEvent_AssetTracked(:final asset) =>
    XelisWalletAssetTracked(asset: asset),
  generated_event.NativeWalletBusinessEvent_AssetUntracked(:final asset) =>
    XelisWalletAssetUntracked(asset: asset),
  generated_event.NativeWalletBusinessEvent_Degraded(
    :final skippedEvents,
    :final failure,
  ) =>
    XelisWalletBusinessEventStreamDegraded(
      skippedEvents: skippedEvents,
      failure: _adaptEventFailure(failure),
    ),
  generated_event.NativeWalletBusinessEvent_Closed(
    :final reason,
    :final failure,
  ) =>
    XelisWalletBusinessEventStreamClosed(
      reason: switch (reason) {
        generated_event
            .NativeWalletBusinessStreamCloseReason
            .nativeChannelClosed =>
          XelisWalletBusinessStreamCloseReason.nativeChannelClosed,
      },
      failure: _adaptEventFailure(failure),
    ),
};

XelisWalletTransactionEntry xelisWalletTransactionFromGenerated(
  generated_event.NativeWalletTransactionEntry value, {
  required bool includePayload,
}) => XelisWalletTransactionEntry(
  hash: value.hash,
  topoheight: value.topoheight,
  timestampMillis: value.timestampMillis,
  entry: _adaptTransactionEntry(value.entry, includePayload),
);

XelisWalletPendingTransaction xelisWalletPendingTransactionFromGenerated(
  generated_event.NativeWalletPendingTransaction value, {
  required bool includePayload,
}) => XelisWalletPendingTransaction(
  hash: value.hash,
  timestampMillis: value.timestampMillis,
  entry: _adaptTransactionEntry(value.entry, includePayload),
);

XelisWalletTransactionEntryData _adaptTransactionEntry(
  generated_event.NativeWalletTransactionEntryData value,
  bool includePayload,
) => switch (value) {
  generated_event.NativeWalletTransactionEntryData_Coinbase(:final reward) =>
    XelisWalletCoinbaseEntry(reward: reward),
  generated_event.NativeWalletTransactionEntryData_Burn(
    :final asset,
    :final amount,
    :final fee,
    :final nonce,
  ) =>
    XelisWalletBurnEntry(asset: asset, amount: amount, fee: fee, nonce: nonce),
  generated_event.NativeWalletTransactionEntryData_Incoming(
    :final from,
    :final transfers,
  ) =>
    XelisWalletIncomingEntry(
      from: from,
      transfers: transfers
          .map((value) => _adaptTransferIn(value, includePayload))
          .toList(growable: false),
    ),
  generated_event.NativeWalletTransactionEntryData_Outgoing(
    :final transfers,
    :final fee,
    :final nonce,
  ) =>
    XelisWalletOutgoingEntry(
      transfers: transfers
          .map((value) => _adaptTransferOut(value, includePayload))
          .toList(growable: false),
      fee: fee,
      nonce: nonce,
    ),
  generated_event.NativeWalletTransactionEntryData_Multisig(
    :final participants,
    :final threshold,
    :final fee,
    :final nonce,
  ) =>
    XelisWalletMultisigEntry(
      participants: participants,
      threshold: threshold,
      fee: fee,
      nonce: nonce,
    ),
  generated_event.NativeWalletTransactionEntryData_InvokeContract(
    :final contract,
    :final deposits,
    :final received,
    :final chunkId,
    :final fee,
    :final maxGas,
    :final nonce,
  ) =>
    XelisWalletInvokeContractEntry(
      contract: contract,
      deposits: deposits.map(_adaptAssetAmount).toList(growable: false),
      received: received
          .map(_adaptContractTransferGroup)
          .toList(growable: false),
      chunkId: chunkId,
      fee: fee,
      maxGas: maxGas,
      nonce: nonce,
    ),
  generated_event.NativeWalletTransactionEntryData_DeployContract(
    :final fee,
    :final nonce,
    :final invoke,
  ) =>
    XelisWalletDeployContractEntry(
      fee: fee,
      nonce: nonce,
      invoke: invoke == null ? null : _adaptDeployInvoke(invoke),
    ),
  generated_event.NativeWalletTransactionEntryData_IncomingContract(
    :final transfers,
  ) =>
    XelisWalletIncomingContractEntry(
      transfers: transfers
          .map(_adaptContractTransferGroup)
          .toList(growable: false),
    ),
  generated_event.NativeWalletTransactionEntryData_OutgoingBlob(
    :final destinations,
    :final fee,
    :final nonce,
    :final data,
  ) =>
    XelisWalletOutgoingBlobEntry(
      destinations: destinations,
      fee: fee,
      nonce: nonce,
      data: _adaptExtraData(data, includePayload),
    ),
  generated_event.NativeWalletTransactionEntryData_IncomingBlob(
    :final from,
    :final destinations,
    :final data,
  ) =>
    XelisWalletIncomingBlobEntry(
      from: from,
      destinations: destinations,
      data: _adaptExtraData(data, includePayload),
    ),
};

XelisWalletTransferIn _adaptTransferIn(
  generated_event.NativeWalletTransferIn value,
  bool includePayload,
) => XelisWalletTransferIn(
  asset: value.asset,
  amount: value.amount,
  extraData: value.extraData == null
      ? null
      : _adaptExtraData(value.extraData!, includePayload),
);

XelisWalletTransferOut _adaptTransferOut(
  generated_event.NativeWalletTransferOut value,
  bool includePayload,
) => XelisWalletTransferOut(
  destination: value.destination,
  asset: value.asset,
  amount: value.amount,
  extraData: value.extraData == null
      ? null
      : _adaptExtraData(value.extraData!, includePayload),
);

XelisWalletExtraData _adaptExtraData(
  generated_event.NativeWalletExtraData value,
  bool includePayload,
) => XelisWalletExtraData(
  flag: switch (value.flag) {
    generated_event.NativeWalletExtraDataFlag.private =>
      XelisWalletExtraDataFlag.private,
    generated_event.NativeWalletExtraDataFlag.public =>
      XelisWalletExtraDataFlag.public,
    generated_event.NativeWalletExtraDataFlag.proprietary =>
      XelisWalletExtraDataFlag.proprietary,
    generated_event.NativeWalletExtraDataFlag.failed =>
      XelisWalletExtraDataFlag.failed,
  },
  hasPayload: value.hasPayload,
  payload: includePayload && value.payload != null
      ? xelisDataElementFromGenerated(value.payload!)
      : null,
  payloadKind: includePayload
      ? switch (value.payloadKind) {
          null => null,
          generated_event.NativeWalletExtraDataPayloadKind.boolValue =>
            XelisWalletExtraDataPayloadKind.boolValue,
          generated_event.NativeWalletExtraDataPayloadKind.string =>
            XelisWalletExtraDataPayloadKind.string,
          generated_event.NativeWalletExtraDataPayloadKind.u8 =>
            XelisWalletExtraDataPayloadKind.u8,
          generated_event.NativeWalletExtraDataPayloadKind.u16 =>
            XelisWalletExtraDataPayloadKind.u16,
          generated_event.NativeWalletExtraDataPayloadKind.u32 =>
            XelisWalletExtraDataPayloadKind.u32,
          generated_event.NativeWalletExtraDataPayloadKind.u64 =>
            XelisWalletExtraDataPayloadKind.u64,
          generated_event.NativeWalletExtraDataPayloadKind.u128 =>
            XelisWalletExtraDataPayloadKind.u128,
          generated_event.NativeWalletExtraDataPayloadKind.hash =>
            XelisWalletExtraDataPayloadKind.hash,
          generated_event.NativeWalletExtraDataPayloadKind.blob =>
            XelisWalletExtraDataPayloadKind.blob,
          generated_event.NativeWalletExtraDataPayloadKind.array =>
            XelisWalletExtraDataPayloadKind.array,
          generated_event.NativeWalletExtraDataPayloadKind.fields =>
            XelisWalletExtraDataPayloadKind.fields,
          generated_event.NativeWalletExtraDataPayloadKind.unknown =>
            XelisWalletExtraDataPayloadKind.unknown,
        }
      : null,
);

XelisWalletAssetAmount _adaptAssetAmount(
  generated_event.NativeWalletAssetAmount value,
) => XelisWalletAssetAmount(asset: value.asset, amount: value.amount);

XelisWalletContractTransferGroup _adaptContractTransferGroup(
  generated_event.NativeWalletContractTransferGroup value,
) => XelisWalletContractTransferGroup(
  contract: value.contract,
  transfers: value.transfers.map(_adaptAssetAmount).toList(growable: false),
);

XelisWalletDeployInvoke _adaptDeployInvoke(
  generated_event.NativeWalletDeployInvoke value,
) => XelisWalletDeployInvoke(
  maxGas: value.maxGas,
  deposits: value.deposits.map(_adaptAssetAmount).toList(growable: false),
);

XelisWalletAsset _adaptAsset(generated_event.NativeWalletAsset value) =>
    XelisWalletAsset(
      assetHash: value.assetHash,
      topoheight: value.topoheight,
      metadata: xelisWalletAssetMetadataFromGenerated(value.metadata),
    );

XelisWalletAssetMetadata xelisWalletAssetMetadataFromGenerated(
  generated_wallet.XelisAssetMetadata value,
) => XelisWalletAssetMetadata(
  name: value.name,
  ticker: value.ticker,
  decimals: value.decimals,
  maxSupply: _adaptMaxSupply(value.maxSupply),
  owner: _adaptAssetOwner(value.owner),
);

XelisWalletMaxSupply _adaptMaxSupply(
  generated_wallet.XelisMaxSupplyMode value,
) => switch (value) {
  generated_wallet.XelisMaxSupplyMode_None() => const XelisWalletNoMaxSupply(),
  generated_wallet.XelisMaxSupplyMode_Fixed(:final field0) =>
    XelisWalletFixedMaxSupply(amount: field0),
  generated_wallet.XelisMaxSupplyMode_Mintable(:final field0) =>
    XelisWalletMintableMaxSupply(amount: field0),
};

XelisWalletAssetOwner _adaptAssetOwner(
  generated_wallet.XelisAssetOwner value,
) => switch (value) {
  generated_wallet.XelisAssetOwner_None() => const XelisWalletNoAssetOwner(),
  generated_wallet.XelisAssetOwner_Creator(:final contract, :final id) =>
    XelisWalletAssetCreator(contract: contract, id: id),
  generated_wallet.XelisAssetOwner_Owner(
    :final origin,
    :final originId,
    :final owner,
  ) =>
    XelisWalletCurrentAssetOwner(
      origin: origin,
      originId: originId,
      owner: owner,
    ),
};

XelisWalletException _adaptEventFailure(
  generated_error.NativeXelisError failure,
) => adaptXelisError(
  failure,
  boundary: const XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletBusinessEventsStream,
  ),
) as XelisWalletException;
