import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('XelisWalletFeePolicy', () {
    test('uses an exact 10000 basis-point automatic policy', () {
      expect(
        XelisWalletFeePolicy.automatic.multiplierBasisPoints,
        XelisWalletFeePolicy.basisPointsScale,
      );
      expect(XelisWalletFeePolicy.basisPointsScale, 10000);
    });

    test('represents the supported UI multipliers without floating point', () {
      final normal = XelisWalletFeePolicy.multiplier(basisPoints: 10000);
      final priority = XelisWalletFeePolicy.multiplier(basisPoints: 15000);
      final fastest = XelisWalletFeePolicy.multiplier(basisPoints: 20000);

      expect(normal, XelisWalletFeePolicy.automatic);
      expect(priority.multiplierBasisPoints, 15000);
      expect(fastest.multiplierBasisPoints, 20000);

      final source = File(
        'lib/src/api/transactions/xelis_wallet_prepared_transaction.dart',
      ).readAsStringSync();
      expect(RegExp(r'\bdouble\b').hasMatch(source), isFalse);
    });

    test('rejects multipliers outside the reviewed bounds', () {
      expect(
        () => XelisWalletFeePolicy.multiplier(basisPoints: 9999),
        throwsRangeError,
      );
      expect(
        () => XelisWalletFeePolicy.multiplier(basisPoints: 100001),
        throwsRangeError,
      );
      expect(
        XelisWalletFeePolicy.multiplier(
          basisPoints: 100000,
        ).multiplierBasisPoints,
        100000,
      );
    });
  });

  test(
    'transfer requests preserve atomic amounts beyond JavaScript integers',
    () {
      final amount = BigInt.parse('900719925474099312345');
      final request = XelisWalletTransferRequest(
        destination: 'xel:destination',
        asset: 'asset',
        amountAtomic: amount,
        extraData: 'potentially sensitive payload',
      );

      expect(request.amountAtomic, same(amount));
      expect(request.encryptExtraData, isTrue);
    },
  );

  test('prepared transfer details are typed and defensively immutable', () {
    final transfer = XelisWalletPreparedTransfer(
      destination: 'xel:destination',
      asset: 'asset',
      amountAtomic: BigInt.parse('18446744073709551615'),
      hasExtraData: true,
      extraDataEncrypted: true,
    );
    final source = <XelisWalletPreparedTransfer>[transfer];
    final details = XelisWalletPreparedTransfers(transfers: source);
    source.add(
      XelisWalletPreparedTransfer(
        destination: 'xel:other',
        asset: 'asset',
        amountAtomic: BigInt.one,
        hasExtraData: false,
        extraDataEncrypted: false,
      ),
    );

    final prepared = XelisWalletPreparedTransaction(
      hash: 'prepared-hash',
      feeAtomic: BigInt.parse('9007199254740993'),
      details: details,
    );

    expect(details.transfers, hasLength(1));
    expect(() => details.transfers.add(transfer), throwsUnsupportedError);
    expect(prepared.details, same(details));
    expect(prepared.feeAtomic, BigInt.parse('9007199254740993'));
  });

  test('prepared burn details keep the exact atomic amount', () {
    final amount = BigInt.parse('18446744073709551615');
    final details = XelisWalletPreparedBurn(
      asset: 'asset',
      amountAtomic: amount,
    );

    expect(details.amountAtomic, same(amount));
  });

  test(
    'broadcast results keep five exhaustive outcomes and failure identity',
    () {
      const failure = XelisWalletOperationException(
        source: XelisWalletErrorSource.xelisCommon,
        operation: XelisWalletOperation.walletTransactionBroadcast,
        code: XelisWalletErrorCode.networkFailure,
        supportId: 'XWF-1111-2222-3333-4444-5555',
        nativeKind: 'TIMED_OUT',
      );
      const results = <XelisWalletBroadcastResult>[
        XelisWalletBroadcastSubmitted(),
        XelisWalletBroadcastRetryable(failure: failure),
        XelisWalletBroadcastRejected(failure: failure),
        XelisWalletBroadcastLocalFailure(failure: failure),
        XelisWalletBroadcastSubmittedNeedsResync(failure: failure),
      ];

      expect(results.map(_broadcastResultName), <String>[
        'submitted',
        'retryable',
        'rejected',
        'localFailure',
        'submittedNeedsResync',
      ]);

      for (final result in results.skip(1)) {
        final attachedFailure = switch (result) {
          XelisWalletBroadcastRetryable(:final failure) ||
          XelisWalletBroadcastRejected(:final failure) ||
          XelisWalletBroadcastLocalFailure(:final failure) ||
          XelisWalletBroadcastSubmittedNeedsResync(:final failure) => failure,
          XelisWalletBroadcastSubmitted() => throw StateError(
            'Submitted does not carry a failure.',
          ),
        };
        expect(attachedFailure, same(failure));
        expect(attachedFailure.supportId, startsWith('XWF-'));
      }
    },
  );

  test('locks the transaction operation identifiers', () {
    expect(
      XelisWalletOperation.walletTransactionFeesEstimate.id,
      'wallet.transaction.fees.estimate',
    );
    expect(
      XelisWalletOperation.walletTransactionTransfersPrepare.id,
      'wallet.transaction.transfers.prepare',
    );
    expect(
      XelisWalletOperation.walletTransactionTransferAllPrepare.id,
      'wallet.transaction.transfer_all.prepare',
    );
    expect(
      XelisWalletOperation.walletTransactionBurnPrepare.id,
      'wallet.transaction.burn.prepare',
    );
    expect(
      XelisWalletOperation.walletTransactionBurnAllPrepare.id,
      'wallet.transaction.burn_all.prepare',
    );
    expect(
      XelisWalletOperation.walletTransactionPreparedCancel.id,
      'wallet.transaction.prepared.cancel',
    );
    expect(
      XelisWalletOperation.walletTransactionBroadcast.id,
      'wallet.transaction.broadcast',
    );
  });
}

String _broadcastResultName(XelisWalletBroadcastResult result) =>
    switch (result) {
      XelisWalletBroadcastSubmitted() => 'submitted',
      XelisWalletBroadcastRetryable() => 'retryable',
      XelisWalletBroadcastRejected() => 'rejected',
      XelisWalletBroadcastLocalFailure() => 'localFailure',
      XelisWalletBroadcastSubmittedNeedsResync() => 'submittedNeedsResync',
    };
