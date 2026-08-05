import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/address_dtos.dart'
    as generated_address;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/wallet_dtos.dart'
    as generated_models;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

final _maxUnsigned64 = BigInt.parse('18446744073709551615');
final _aboveJavaScriptSafeInteger = BigInt.parse('9007199254740993');
final _supportIdPattern = RegExp(r'^XWF-(?:[0-9A-F]{4}-){4}[0-9A-F]{4}$');

const _nativeBroadcastFailure = generated_error.NativeXelisError(
  version: XelisWalletErrorContract.currentVersion,
  source: generated_error.NativeXelisErrorSource.xelisCommon,
  code: generated_error.NativeXelisErrorCode.network,
  nativeKind: 'TIMED_OUT',
  nativeCode: -32001,
  diagnosticMessage: 'privileged native broadcast diagnostic',
);

void main() {
  group('prepared transaction adapter', () {
    test(
      'preserves exact u64 values, basis points, and safe projection',
      () async {
        const secretExtraData = 'private transfer payload';
        final native = _nativeTransfer(
          hash: 'transfer-hash',
          preparationId: _aboveJavaScriptSafeInteger,
          fee: _aboveJavaScriptSafeInteger,
          amount: _maxUnsigned64,
          hasExtraData: true,
          encryptExtraData: true,
        );
        final delegate = _FakeGeneratedPreparedWallet(
          estimatedFee: _maxUnsigned64,
          preparedTransactions: [native],
        );
        final wallet = NativeXelisWallet(delegate);
        final request = XelisWalletTransferRequest(
          destination: 'xel:destination',
          asset: 'asset-hash',
          amountAtomic: _maxUnsigned64,
          extraData: secretExtraData,
        );
        final policy = XelisWalletFeePolicy.multiplier(basisPoints: 15_001);

        final estimated = await wallet.estimateTransferFees(
          transfers: [request],
          feePolicy: policy,
        );
        final prepared = await wallet.prepareTransfers(
          transfers: [request],
          feePolicy: policy,
        );

        expect(estimated, _maxUnsigned64);
        expect(delegate.estimatedTransfers.single.amount, _maxUnsigned64);
        expect(delegate.estimatedFeePolicy?.basisPoints, 15_001);
        expect(delegate.preparedTransfers.single.amount, _maxUnsigned64);
        expect(delegate.preparedTransferFeePolicy?.basisPoints, 15_001);
        expect(delegate.preparedTransfers.single.extraData, secretExtraData);
        expect(prepared.hash, 'transfer-hash');
        expect(prepared.feeAtomic, _aboveJavaScriptSafeInteger);

        final details = prepared.details as XelisWalletPreparedTransfers;
        final transfer = details.transfers.single;
        expect(transfer.amountAtomic, _maxUnsigned64);
        expect(transfer.destination, 'xel:destination');
        expect(transfer.asset, 'asset-hash');
        expect(transfer.hasExtraData, isTrue);
        expect(transfer.extraDataEncrypted, isTrue);
        expect(transfer.toString(), isNot(contains(secretExtraData)));
        expect(details.toString(), isNot(contains(secretExtraData)));

        final result = await wallet.broadcastPreparedTransaction(
          transaction: prepared,
        );
        expect(result, isA<XelisWalletBroadcastSubmitted>());
        expect(
          delegate.broadcastCalls.single.preparationId,
          _aboveJavaScriptSafeInteger,
        );
        expect(delegate.broadcastCalls.single.txHash, 'transfer-hash');
      },
    );

    test(
      'reveals typed extra data only through the exact prepared capability',
      () async {
        const secret = 'exchange deposit reference';
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(
              hash: 'inspect-hash',
              preparationId: _aboveJavaScriptSafeInteger,
              hasExtraData: true,
            ),
          ],
          inspectionResult:
              const generated_models.NativePreparedTransferExtraData(
                data: generated_address.NativeXelisDataElement.value(
                  value: generated_address.NativeXelisDataValue.stringValue(
                    value: secret,
                  ),
                ),
                source: generated_models
                    .NativePreparedExtraDataSource
                    .integratedAddress,
                encrypted: true,
              ),
        );
        final wallet = NativeXelisWallet(delegate);
        final prepared = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.one)],
        );

        final revealed = await wallet.inspectPreparedTransferExtraData(
          transaction: prepared,
          transferIndex: 0,
        );

        expect(
          revealed.data,
          const XelisDataElement.value(XelisDataValue.string(secret)),
        );
        expect(
          revealed.source,
          XelisWalletPreparedExtraDataSource.integratedAddress,
        );
        expect(revealed.encrypted, isTrue);
        expect(revealed.toString(), isNot(contains(secret)));
        expect(
          delegate.inspectionCalls.single.preparationId,
          _aboveJavaScriptSafeInteger,
        );
        expect(delegate.inspectionCalls.single.txHash, 'inspect-hash');
        expect(delegate.inspectionCalls.single.transferIndex, 0);

        final reconstructed = XelisWalletPreparedTransaction(
          hash: prepared.hash,
          feeAtomic: prepared.feeAtomic,
          details: prepared.details,
        );
        final error = await _captureXelisException(
          () => wallet.inspectPreparedTransferExtraData(
            transaction: reconstructed,
            transferIndex: 0,
          ),
        );
        _expectInvalidCapability(
          error,
          XelisWalletOperation.walletTransactionPreparedInspect,
        );
        expect(delegate.inspectionCalls, hasLength(1));
      },
    );

    test(
      'maps typed burn and forwards its atomic amount without conversion',
      () async {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeBurn(
              hash: 'burn-hash',
              preparationId: _maxUnsigned64,
              fee: _aboveJavaScriptSafeInteger,
              asset: 'burn-asset',
              amount: _maxUnsigned64,
            ),
          ],
        );
        final wallet = NativeXelisWallet(delegate);

        final prepared = await wallet.prepareBurn(
          asset: 'burn-asset',
          amountAtomic: _aboveJavaScriptSafeInteger,
          feePolicy: XelisWalletFeePolicy.multiplier(basisPoints: 20_000),
        );

        expect(delegate.lastBurnAmount, _aboveJavaScriptSafeInteger);
        expect(delegate.lastBurnAsset, 'burn-asset');
        expect(delegate.lastBurnFeePolicy?.basisPoints, 20_000);
        expect(prepared.feeAtomic, _aboveJavaScriptSafeInteger);
        final burn = prepared.details as XelisWalletPreparedBurn;
        expect(burn.asset, 'burn-asset');
        expect(burn.amountAtomic, _maxUnsigned64);
      },
    );

    test(
      'forwards transfer-all and burn-all stable parameters exactly',
      () async {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(
              hash: 'all-hash',
              preparationId: BigInt.one,
              fee: BigInt.from(10),
              amount: BigInt.from(90),
              hasExtraData: true,
              encryptExtraData: false,
            ),
            _nativeBurn(
              hash: 'burn-all-hash',
              preparationId: BigInt.two,
              fee: BigInt.from(11),
              asset: 'burn-all-asset',
              amount: BigInt.from(89),
            ),
          ],
        );
        final wallet = NativeXelisWallet(delegate);

        await wallet.prepareTransferAll(
          destination: 'xel:all-destination',
          asset: 'all-asset',
          extraData: 'private all payload',
          encryptExtraData: false,
          feePolicy: XelisWalletFeePolicy.multiplier(basisPoints: 30_000),
        );
        await wallet.prepareBurnAll(
          asset: 'burn-all-asset',
          feePolicy: XelisWalletFeePolicy.multiplier(basisPoints: 40_000),
        );

        expect(delegate.lastTransferAllDestination, 'xel:all-destination');
        expect(delegate.lastTransferAllAsset, 'all-asset');
        expect(delegate.lastTransferAllExtraData, 'private all payload');
        expect(delegate.lastTransferAllEncryptExtraData, isFalse);
        expect(delegate.lastTransferAllFeePolicy?.basisPoints, 30_000);
        expect(delegate.lastBurnAllAsset, 'burn-all-asset');
        expect(delegate.lastBurnAllFeePolicy?.basisPoints, 40_000);
      },
    );

    test('maps all four native failures to XWF broadcast exceptions', () async {
      final outcomes = <generated_models.NativePreparedTransactionBroadcastOutcome>[
        const generated_models.NativePreparedTransactionBroadcastOutcome.retryable(
          failure: _nativeBroadcastFailure,
        ),
        const generated_models.NativePreparedTransactionBroadcastOutcome.rejected(
          failure: _nativeBroadcastFailure,
        ),
        const generated_models.NativePreparedTransactionBroadcastOutcome.localFailure(
          failure: _nativeBroadcastFailure,
        ),
        const generated_models.NativePreparedTransactionBroadcastOutcome.submittedNeedsResync(
          failure: _nativeBroadcastFailure,
        ),
      ];

      for (var index = 0; index < outcomes.length; index++) {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(
              hash: 'outcome-$index',
              preparationId: BigInt.from(index + 1),
            ),
          ],
          broadcastOutcomes: [outcomes[index]],
        );
        final wallet = NativeXelisWallet(delegate);
        final prepared = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.one)],
        );

        final result = await wallet.broadcastPreparedTransaction(
          transaction: prepared,
        );
        final failure = _failureFrom(result);

        expect(_resultName(result), _resultNameForNative(outcomes[index]));
        expect(failure.source, XelisWalletErrorSource.xelisCommon);
        expect(
          failure.operation,
          XelisWalletOperation.walletTransactionBroadcast,
        );
        expect(failure.operation.id, 'wallet.transaction.broadcast');
        expect(failure.code, XelisWalletErrorCode.networkFailure);
        expect(failure.nativeKind, 'TIMED_OUT');
        expect(failure.nativeCode, -32001);
        expect(failure.supportId, matches(_supportIdPattern));
        expect(
          failure.diagnosticMessage,
          'privileged native broadcast diagnostic',
        );
        expect(failure.toString(), isNot(contains('privileged')));
      }
    });

    test(
      'retryable retains the exact capability until a terminal result',
      () async {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(
              hash: 'retry-hash',
              preparationId: _aboveJavaScriptSafeInteger,
            ),
          ],
          broadcastOutcomes: [
            const generated_models.NativePreparedTransactionBroadcastOutcome.retryable(
              failure: _nativeBroadcastFailure,
            ),
            const generated_models.NativePreparedTransactionBroadcastOutcome.submitted(),
          ],
        );
        final wallet = NativeXelisWallet(delegate);
        final prepared = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.one)],
        );

        final retry = await wallet.broadcastPreparedTransaction(
          transaction: prepared,
        );
        final submitted = await wallet.broadcastPreparedTransaction(
          transaction: prepared,
        );

        expect(retry, isA<XelisWalletBroadcastRetryable>());
        expect(submitted, isA<XelisWalletBroadcastSubmitted>());
        expect(delegate.broadcastCalls, hasLength(2));
        for (final call in delegate.broadcastCalls) {
          expect(call.preparationId, _aboveJavaScriptSafeInteger);
          expect(call.txHash, 'retry-hash');
        }

        final consumed = await _captureXelisException(
          () => wallet.broadcastPreparedTransaction(transaction: prepared),
        );
        _expectInvalidCapability(
          consumed,
          XelisWalletOperation.walletTransactionBroadcast,
        );
        expect(delegate.broadcastCalls, hasLength(2));
      },
    );

    test('every terminal outcome invalidates its prepared capability', () async {
      final terminalOutcomes = <generated_models.NativePreparedTransactionBroadcastOutcome>[
        const generated_models.NativePreparedTransactionBroadcastOutcome.submitted(),
        const generated_models.NativePreparedTransactionBroadcastOutcome.rejected(
          failure: _nativeBroadcastFailure,
        ),
        const generated_models.NativePreparedTransactionBroadcastOutcome.localFailure(
          failure: _nativeBroadcastFailure,
        ),
        const generated_models.NativePreparedTransactionBroadcastOutcome.submittedNeedsResync(
          failure: _nativeBroadcastFailure,
        ),
      ];

      for (var index = 0; index < terminalOutcomes.length; index++) {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(
              hash: 'terminal-$index',
              preparationId: BigInt.from(index + 10),
            ),
          ],
          broadcastOutcomes: [terminalOutcomes[index]],
        );
        final wallet = NativeXelisWallet(delegate);
        final prepared = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.one)],
        );

        await wallet.broadcastPreparedTransaction(transaction: prepared);
        final stale = await _captureXelisException(
          () => wallet.broadcastPreparedTransaction(transaction: prepared),
        );

        _expectInvalidCapability(
          stale,
          XelisWalletOperation.walletTransactionBroadcast,
        );
        expect(delegate.broadcastCalls, hasLength(1));
      }
    });

    test(
      'rejects replacement, reconstruction, and cross-wallet use before delegate',
      () async {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(hash: 'first-hash', preparationId: BigInt.from(20)),
            _nativeTransfer(
              hash: 'second-hash',
              preparationId: BigInt.from(21),
            ),
          ],
        );
        final wallet = NativeXelisWallet(delegate);
        final first = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.one)],
        );
        final second = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.two)],
        );

        final replaced = await _captureXelisException(
          () => wallet.broadcastPreparedTransaction(transaction: first),
        );
        _expectInvalidCapability(
          replaced,
          XelisWalletOperation.walletTransactionBroadcast,
        );
        expect(delegate.broadcastCalls, isEmpty);

        final reconstructed = XelisWalletPreparedTransaction(
          hash: second.hash,
          feeAtomic: second.feeAtomic,
          details: second.details,
        );
        final reconstructedError = await _captureXelisException(
          () => wallet.broadcastPreparedTransaction(transaction: reconstructed),
        );
        _expectInvalidCapability(
          reconstructedError,
          XelisWalletOperation.walletTransactionBroadcast,
        );
        expect(delegate.broadcastCalls, isEmpty);

        final otherDelegate = _FakeGeneratedPreparedWallet();
        final otherWallet = NativeXelisWallet(otherDelegate);
        final crossWallet = await _captureXelisException(
          () => otherWallet.broadcastPreparedTransaction(transaction: second),
        );
        _expectInvalidCapability(
          crossWallet,
          XelisWalletOperation.walletTransactionBroadcast,
        );
        expect(otherDelegate.broadcastCalls, isEmpty);

        expect(
          await wallet.broadcastPreparedTransaction(transaction: second),
          isA<XelisWalletBroadcastSubmitted>(),
        );
        expect(delegate.broadcastCalls.single.preparationId, BigInt.from(21));
        expect(delegate.broadcastCalls.single.txHash, 'second-hash');
      },
    );

    test(
      'discard succeeds once while a retryable failure retains capability',
      () async {
        final delegate = _FakeGeneratedPreparedWallet(
          preparedTransactions: [
            _nativeTransfer(
              hash: 'discard-hash',
              preparationId: _maxUnsigned64,
            ),
          ],
          cancelError: _nativeBroadcastFailure,
        );
        final wallet = NativeXelisWallet(delegate);
        final prepared = await wallet.prepareTransfers(
          transfers: [_request(amount: BigInt.one)],
        );

        final nativeFailure = await _captureXelisException(
          () => wallet.discardPreparedTransaction(transaction: prepared),
        );
        expect(
          nativeFailure.operation,
          XelisWalletOperation.walletTransactionPreparedCancel,
        );
        expect(
          nativeFailure.operation.id,
          'wallet.transaction.prepared.cancel',
        );
        expect(nativeFailure.code, XelisWalletErrorCode.networkFailure);
        expect(nativeFailure.supportId, matches(_supportIdPattern));
        expect(delegate.cancelCalls, hasLength(1));

        delegate.cancelError = null;
        await wallet.discardPreparedTransaction(transaction: prepared);
        expect(delegate.cancelCalls, hasLength(2));
        for (final call in delegate.cancelCalls) {
          expect(call.preparationId, _maxUnsigned64);
          expect(call.txHash, 'discard-hash');
        }

        final invalidated = await _captureXelisException(
          () => wallet.discardPreparedTransaction(transaction: prepared),
        );
        _expectInvalidCapability(
          invalidated,
          XelisWalletOperation.walletTransactionPreparedCancel,
        );
        expect(delegate.cancelCalls, hasLength(2));
      },
    );

    test(
      'rejects non-positive and overflowing amounts before native calls',
      () async {
        final delegate = _FakeGeneratedPreparedWallet();
        final wallet = NativeXelisWallet(delegate);

        final zero = await _captureXelisException(
          () => wallet.estimateTransferFees(
            transfers: [_request(amount: BigInt.zero)],
          ),
        );
        _expectInvalidAmount(
          zero,
          XelisWalletOperation.walletTransactionFeesEstimate,
        );

        final overflowing = await _captureXelisException(
          () => wallet.prepareTransfers(
            transfers: [_request(amount: _maxUnsigned64 + BigInt.one)],
          ),
        );
        _expectInvalidAmount(
          overflowing,
          XelisWalletOperation.walletTransactionTransfersPrepare,
        );

        final negative = await _captureXelisException(
          () => wallet.prepareBurn(
            asset: 'asset-hash',
            amountAtomic: -BigInt.one,
          ),
        );
        _expectInvalidAmount(
          negative,
          XelisWalletOperation.walletTransactionBurnPrepare,
        );

        expect(delegate.estimateCalls, 0);
        expect(delegate.prepareTransfersCalls, 0);
        expect(delegate.prepareBurnCalls, 0);
      },
    );
  });
}

XelisWalletTransferRequest _request({required BigInt amount}) =>
    XelisWalletTransferRequest(
      destination: 'xel:destination',
      asset: 'asset-hash',
      amountAtomic: amount,
    );

generated_models.NativePreparedTransaction _nativeTransfer({
  required String hash,
  required BigInt preparationId,
  BigInt? fee,
  BigInt? amount,
  bool hasExtraData = false,
  bool encryptExtraData = true,
}) => generated_models.NativePreparedTransaction(
  hash: hash,
  preparationId: preparationId,
  fee: fee ?? BigInt.one,
  transaction: generated_models.NativePreparedTransactionKind.transfers(
    transfers: [
      generated_models.NativePreparedTransfer(
        amount: amount ?? BigInt.one,
        destination: 'xel:destination',
        asset: 'asset-hash',
        hasExtraData: hasExtraData,
        encryptExtraData: encryptExtraData,
      ),
    ],
  ),
);

generated_models.NativePreparedTransaction _nativeBurn({
  required String hash,
  required BigInt preparationId,
  required BigInt fee,
  required String asset,
  required BigInt amount,
}) => generated_models.NativePreparedTransaction(
  hash: hash,
  preparationId: preparationId,
  fee: fee,
  transaction: generated_models.NativePreparedTransactionKind.burn(
    asset: asset,
    amount: amount,
  ),
);

Future<XelisWalletException> _captureXelisException(
  FutureOr<Object?> Function() action,
) async {
  try {
    await action();
  } on XelisWalletException catch (error) {
    return error;
  }
  fail('Expected a XelisWalletException');
}

void _expectInvalidCapability(
  XelisWalletException error,
  XelisWalletOperation operation,
) {
  expect(error, isA<XelisWalletOperationException>());
  expect(error.source, XelisWalletErrorSource.xelisWalletFlutter);
  expect(error.operation, operation);
  expect(error.code, XelisWalletErrorCode.conflict);
  expect(error.nativeKind, 'PREPARED_TRANSACTION_CAPABILITY_INVALID');
  expect(error.supportId, matches(_supportIdPattern));
}

void _expectInvalidAmount(
  XelisWalletException error,
  XelisWalletOperation operation,
) {
  expect(error, isA<XelisWalletOperationException>());
  expect(error.source, XelisWalletErrorSource.xelisWalletFlutter);
  expect(error.operation, operation);
  expect(error.code, XelisWalletErrorCode.invalidInput);
  expect(error.nativeKind, 'TRANSACTION_AMOUNT_INVALID');
  expect(error.supportId, matches(_supportIdPattern));
}

XelisWalletException _failureFrom(XelisWalletBroadcastResult result) =>
    switch (result) {
      XelisWalletBroadcastRetryable(:final failure) ||
      XelisWalletBroadcastRejected(:final failure) ||
      XelisWalletBroadcastLocalFailure(:final failure) ||
      XelisWalletBroadcastSubmittedNeedsResync(:final failure) => failure,
      XelisWalletBroadcastSubmitted() => throw StateError(
        'Submitted does not contain a failure.',
      ),
    };

String _resultName(XelisWalletBroadcastResult result) => switch (result) {
  XelisWalletBroadcastSubmitted() => 'submitted',
  XelisWalletBroadcastRetryable() => 'retryable',
  XelisWalletBroadcastRejected() => 'rejected',
  XelisWalletBroadcastLocalFailure() => 'localFailure',
  XelisWalletBroadcastSubmittedNeedsResync() => 'submittedNeedsResync',
};

String _resultNameForNative(
  generated_models.NativePreparedTransactionBroadcastOutcome result,
) => switch (result) {
  generated_models.NativePreparedTransactionBroadcastOutcome_Submitted() =>
    'submitted',
  generated_models.NativePreparedTransactionBroadcastOutcome_Retryable() =>
    'retryable',
  generated_models.NativePreparedTransactionBroadcastOutcome_Rejected() =>
    'rejected',
  generated_models.NativePreparedTransactionBroadcastOutcome_LocalFailure() =>
    'localFailure',
  generated_models.NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync() =>
    'submittedNeedsResync',
};

final class _PreparedCall {
  const _PreparedCall({required this.preparationId, required this.txHash});

  final BigInt preparationId;
  final String txHash;
}

final class _PreparedInspectionCall {
  const _PreparedInspectionCall({
    required this.preparationId,
    required this.txHash,
    required this.transferIndex,
  });

  final BigInt preparationId;
  final String txHash;
  final int transferIndex;
}

final class _FakeGeneratedPreparedWallet
    implements generated_wallet.XelisWallet {
  _FakeGeneratedPreparedWallet({
    BigInt? estimatedFee,
    List<generated_models.NativePreparedTransaction>? preparedTransactions,
    List<generated_models.NativePreparedTransactionBroadcastOutcome>?
    broadcastOutcomes,
    this.inspectionResult,
    this.cancelError,
  }) : estimatedFee = estimatedFee ?? BigInt.zero,
       preparedTransactions = [...?preparedTransactions],
       broadcastOutcomes = [...?broadcastOutcomes];

  final BigInt estimatedFee;
  final List<generated_models.NativePreparedTransaction> preparedTransactions;
  final List<generated_models.NativePreparedTransactionBroadcastOutcome>
  broadcastOutcomes;
  final generated_models.NativePreparedTransferExtraData? inspectionResult;
  Object? cancelError;

  var estimateCalls = 0;
  var prepareTransfersCalls = 0;
  var prepareBurnCalls = 0;
  List<generated_models.NativeTransactionTransferRequest> estimatedTransfers =
      const [];
  generated_models.NativeTransactionFeePolicy? estimatedFeePolicy;
  List<generated_models.NativeTransactionTransferRequest> preparedTransfers =
      const [];
  generated_models.NativeTransactionFeePolicy? preparedTransferFeePolicy;
  BigInt? lastBurnAmount;
  String? lastBurnAsset;
  generated_models.NativeTransactionFeePolicy? lastBurnFeePolicy;
  String? lastTransferAllDestination;
  String? lastTransferAllAsset;
  String? lastTransferAllExtraData;
  bool? lastTransferAllEncryptExtraData;
  generated_models.NativeTransactionFeePolicy? lastTransferAllFeePolicy;
  String? lastBurnAllAsset;
  generated_models.NativeTransactionFeePolicy? lastBurnAllFeePolicy;
  final broadcastCalls = <_PreparedCall>[];
  final cancelCalls = <_PreparedCall>[];
  final inspectionCalls = <_PreparedInspectionCall>[];

  @override
  bool get isDisposed => false;

  @override
  Future<BigInt> estimateTransferFeesAtomic({
    required List<generated_models.NativeTransactionTransferRequest> transfers,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    estimateCalls++;
    estimatedTransfers = List.unmodifiable(transfers);
    estimatedFeePolicy = feePolicy;
    return estimatedFee;
  }

  @override
  Future<generated_models.NativePreparedTransaction>
  prepareTransfersTransaction({
    required List<generated_models.NativeTransactionTransferRequest> transfers,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    prepareTransfersCalls++;
    preparedTransfers = List.unmodifiable(transfers);
    preparedTransferFeePolicy = feePolicy;
    return _nextPreparedTransaction();
  }

  @override
  Future<generated_models.NativePreparedTransaction>
  prepareTransferAllTransaction({
    required String destination,
    required String asset,
    String? extraData,
    required bool encryptExtraData,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    lastTransferAllDestination = destination;
    lastTransferAllAsset = asset;
    lastTransferAllExtraData = extraData;
    lastTransferAllEncryptExtraData = encryptExtraData;
    lastTransferAllFeePolicy = feePolicy;
    return _nextPreparedTransaction();
  }

  @override
  Future<generated_models.NativePreparedTransaction> prepareBurnTransaction({
    required BigInt amount,
    required String asset,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    prepareBurnCalls++;
    lastBurnAmount = amount;
    lastBurnAsset = asset;
    lastBurnFeePolicy = feePolicy;
    return _nextPreparedTransaction();
  }

  @override
  Future<generated_models.NativePreparedTransaction> prepareBurnAllTransaction({
    required String asset,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    lastBurnAllAsset = asset;
    lastBurnAllFeePolicy = feePolicy;
    return _nextPreparedTransaction();
  }

  @override
  Future<generated_models.NativePreparedTransactionBroadcastOutcome>
  broadcastPreparedTransaction({
    required BigInt preparationId,
    required String txHash,
  }) async {
    broadcastCalls.add(
      _PreparedCall(preparationId: preparationId, txHash: txHash),
    );
    if (broadcastOutcomes.isEmpty) {
      return const generated_models.NativePreparedTransactionBroadcastOutcome.submitted();
    }
    return broadcastOutcomes.removeAt(0);
  }

  @override
  Future<void> cancelPreparedTransaction({
    required BigInt preparationId,
    required String txHash,
  }) async {
    cancelCalls.add(
      _PreparedCall(preparationId: preparationId, txHash: txHash),
    );
    if (cancelError case final error?) {
      throw error;
    }
  }

  @override
  Future<generated_models.NativePreparedTransferExtraData>
  inspectPreparedTransferExtraData({
    required BigInt preparationId,
    required String txHash,
    required int transferIndex,
  }) async {
    inspectionCalls.add(
      _PreparedInspectionCall(
        preparationId: preparationId,
        txHash: txHash,
        transferIndex: transferIndex,
      ),
    );
    return inspectionResult ??
        (throw StateError('No prepared inspection result configured.'));
  }

  generated_models.NativePreparedTransaction _nextPreparedTransaction() {
    if (preparedTransactions.isEmpty) {
      throw StateError('No prepared transaction configured for fake delegate.');
    }
    return preparedTransactions.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
