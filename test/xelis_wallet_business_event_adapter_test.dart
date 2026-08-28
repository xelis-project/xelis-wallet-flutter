import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_business_event_adapter.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/business_event_dtos.dart'
    as generated_event;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/wallet_dtos.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet/business_events.dart'
    as generated_subscription;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet_api;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('business event mapping', () {
    test('maps all transaction variants and preserves u64 values', () {
      final huge = BigInt.parse('18446744073709551615');
      const hash = 'ab';
      final extraData = generated_event.NativeWalletExtraData(
        flag: generated_event.NativeWalletExtraDataFlag.private,
        hasPayload: true,
        payloadKind: generated_event.NativeWalletExtraDataPayloadKind.string,
      );
      final transferIn = generated_event.NativeWalletTransferIn(
        asset: 'asset-in',
        amount: huge,
        extraData: extraData,
      );
      final transferOut = generated_event.NativeWalletTransferOut(
        destination: 'xel:destination',
        asset: 'asset-out',
        amount: huge,
        extraData: extraData,
      );
      final amount = generated_event.NativeWalletAssetAmount(
        asset: 'asset-contract',
        amount: huge,
      );
      final group = generated_event.NativeWalletContractTransferGroup(
        contract: 'contract-source',
        transfers: [amount],
      );
      final variants = <generated_event.NativeWalletTransactionEntryData>[
        generated_event.NativeWalletTransactionEntryData.coinbase(reward: huge),
        generated_event.NativeWalletTransactionEntryData.burn(
          asset: 'burn-asset',
          amount: huge,
          fee: huge,
          nonce: huge,
        ),
        generated_event.NativeWalletTransactionEntryData.incoming(
          from: 'xel:source',
          transfers: [transferIn],
        ),
        generated_event.NativeWalletTransactionEntryData.outgoing(
          transfers: [transferOut],
          fee: huge,
          nonce: huge,
        ),
        generated_event.NativeWalletTransactionEntryData.multisig(
          participants: const ['xel:a', 'xel:b'],
          threshold: 2,
          fee: huge,
          nonce: huge,
        ),
        generated_event.NativeWalletTransactionEntryData.invokeContract(
          contract: 'contract',
          deposits: [amount],
          received: [group],
          chunkId: 65535,
          fee: huge,
          maxGas: huge,
          nonce: huge,
        ),
        generated_event.NativeWalletTransactionEntryData.deployContract(
          fee: huge,
          nonce: huge,
          invoke: generated_event.NativeWalletDeployInvoke(
            maxGas: huge,
            deposits: [amount],
          ),
        ),
        generated_event.NativeWalletTransactionEntryData.incomingContract(
          transfers: [group],
        ),
        generated_event.NativeWalletTransactionEntryData.outgoingBlob(
          destinations: const ['xel:a'],
          fee: huge,
          nonce: huge,
          data: extraData,
        ),
        generated_event.NativeWalletTransactionEntryData.incomingBlob(
          from: 'xel:source',
          destinations: const ['xel:b'],
          data: extraData,
        ),
      ];
      final expectedTypes = <Type>[
        XelisWalletCoinbaseEntry,
        XelisWalletBurnEntry,
        XelisWalletIncomingEntry,
        XelisWalletOutgoingEntry,
        XelisWalletMultisigEntry,
        XelisWalletInvokeContractEntry,
        XelisWalletDeployContractEntry,
        XelisWalletIncomingContractEntry,
        XelisWalletOutgoingBlobEntry,
        XelisWalletIncomingBlobEntry,
      ];

      for (var index = 0; index < variants.length; index++) {
        final transaction = generated_event.NativeWalletTransactionEntry(
          hash: hash,
          topoheight: huge,
          timestampMillis: huge,
          entry: variants[index],
        );
        final event =
            adaptBusinessEventFrame(
                  generated_event.NativeWalletBusinessEventFrame(
                    version: XelisWalletBusinessEventContract.currentVersion,
                    generation: BigInt.one,
                    sequence: BigInt.from(index + 1),
                    event:
                        generated_event
                            .NativeWalletBusinessEvent.newTransaction(
                          transaction: transaction,
                        ),
                  ),
                  expectedGeneration: BigInt.one,
                  expectedSequence: BigInt.from(index + 1),
                ).event
                as XelisWalletNewTransaction;

        expect(event.transaction.topoheight, huge);
        expect(event.transaction.timestampMillis, huge);
        expect(event.transaction.entry.runtimeType, expectedTypes[index]);
      }

      final incoming =
          adaptBusinessEventFrame(
                _frame(
                  event:
                      generated_event.NativeWalletBusinessEvent.newTransaction(
                        transaction:
                            generated_event.NativeWalletTransactionEntry(
                              hash: hash,
                              topoheight: huge,
                              timestampMillis: huge,
                              entry: variants[2],
                            ),
                      ),
                ),
                expectedGeneration: BigInt.one,
                expectedSequence: BigInt.one,
              ).event
              as XelisWalletNewTransaction;
      final mappedExtra =
          (incoming.transaction.entry as XelisWalletIncomingEntry)
              .transfers
              .single
              .extraData!;
      expect(mappedExtra.hasPayload, isTrue);
      expect(mappedExtra.flag, XelisWalletExtraDataFlag.private);
      expect(mappedExtra.payloadKind, isNull);
      expect(mappedExtra.toString(), isNot(contains('shared')));
      expect(mappedExtra.toString(), isNot(contains('payload')));
    });

    test('maps the reserved unknown payload kind for explicit reads', () {
      final nativeExtraData = generated_event.NativeWalletExtraData(
        flag: generated_event.NativeWalletExtraDataFlag.public,
        hasPayload: true,
        payloadKind: generated_event.NativeWalletExtraDataPayloadKind.unknown,
      );
      final transaction = xelisWalletTransactionFromGenerated(
        generated_event.NativeWalletTransactionEntry(
          hash: 'hash',
          topoheight: BigInt.one,
          timestampMillis: BigInt.one,
          entry: generated_event.NativeWalletTransactionEntryData.incoming(
            from: 'xel:source',
            transfers: [
              generated_event.NativeWalletTransferIn(
                asset: 'asset',
                amount: BigInt.one,
                extraData: nativeExtraData,
              ),
            ],
          ),
        ),
        includePayload: true,
      );

      final mapped = (transaction.entry as XelisWalletIncomingEntry)
          .transfers
          .single
          .extraData!;
      expect(mapped.payload, isNull);
      expect(mapped.payloadKind, XelisWalletExtraDataPayloadKind.unknown);
    });

    test('maps every top-level business variant and authored failures', () {
      final huge = BigInt.parse('18446744073709551615');
      final transactionData = generated_event
          .NativeWalletTransactionEntryData.coinbase(reward: huge);
      final failure = _nativeFailure(
        code: generated_error.NativeXelisErrorCode.streamLagged,
        nativeKind: 'WALLET_BUSINESS_EVENTS_LAGGED',
      );
      final closedFailure = _nativeFailure(
        code: generated_error.NativeXelisErrorCode.streamClosedUnexpectedly,
        nativeKind: 'WALLET_BUSINESS_EVENT_STREAM_CLOSED',
      );
      final asset = generated_event.NativeWalletAsset(
        assetHash: 'asset',
        topoheight: huge,
        metadata: generated_wallet.XelisAssetMetadata(
          name: 'Asset',
          ticker: 'AST',
          decimals: 8,
          maxSupply: generated_wallet.XelisMaxSupplyMode.mintable(huge),
          owner: generated_wallet.XelisAssetOwner.creator(
            contract: 'contract',
            id: huge,
          ),
        ),
      );
      final nativeEvents = <generated_event.NativeWalletBusinessEvent>[
        generated_event.NativeWalletBusinessEvent.newTransaction(
          transaction: generated_event.NativeWalletTransactionEntry(
            hash: 'confirmed',
            topoheight: huge,
            timestampMillis: huge,
            entry: transactionData,
          ),
        ),
        generated_event.NativeWalletBusinessEvent.newPendingTransaction(
          transaction: generated_event.NativeWalletPendingTransaction(
            hash: 'pending',
            timestampMillis: huge,
            entry: transactionData,
          ),
        ),
        generated_event.NativeWalletBusinessEvent.balanceChanged(
          asset: 'asset',
          balance: huge,
        ),
        generated_event.NativeWalletBusinessEvent.newAsset(asset: asset),
        const generated_event.NativeWalletBusinessEvent.assetTracked(
          asset: 'asset',
        ),
        const generated_event.NativeWalletBusinessEvent.assetUntracked(
          asset: 'asset',
        ),
        generated_event.NativeWalletBusinessEvent.degraded(
          skippedEvents: huge,
          failure: failure,
        ),
        generated_event.NativeWalletBusinessEvent.closed(
          reason: generated_event
              .NativeWalletBusinessStreamCloseReason
              .nativeChannelClosed,
          failure: closedFailure,
        ),
      ];
      final expectedTypes = <Type>[
        XelisWalletNewTransaction,
        XelisWalletNewPendingTransaction,
        XelisWalletBalanceChanged,
        XelisWalletNewAsset,
        XelisWalletAssetTracked,
        XelisWalletAssetUntracked,
        XelisWalletBusinessEventStreamDegraded,
        XelisWalletBusinessEventStreamClosed,
      ];

      for (var index = 0; index < nativeEvents.length; index++) {
        final event = adaptBusinessEventFrame(
          _frame(sequence: BigInt.from(index + 1), event: nativeEvents[index]),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.from(index + 1),
        ).event;
        expect(event.runtimeType, expectedTypes[index]);
      }

      final mappedAsset =
          (adaptBusinessEventFrame(
                    _frame(event: nativeEvents[3]),
                    expectedGeneration: BigInt.one,
                    expectedSequence: BigInt.one,
                  ).event
                  as XelisWalletNewAsset)
              .asset;
      expect(mappedAsset.topoheight, huge);
      expect(
        (mappedAsset.metadata.maxSupply as XelisWalletMintableMaxSupply).amount,
        huge,
      );
      expect((mappedAsset.metadata.owner as XelisWalletAssetCreator).id, huge);

      final unownedAsset =
          (adaptBusinessEventFrame(
                    _frame(
                      event: generated_event.NativeWalletBusinessEvent.newAsset(
                        asset: generated_event.NativeWalletAsset(
                          assetHash: 'native-asset',
                          topoheight: huge,
                          metadata: generated_wallet.XelisAssetMetadata(
                            name: 'XELIS',
                            ticker: 'XEL',
                            decimals: 8,
                            maxSupply:
                                const generated_wallet.XelisMaxSupplyMode.none(),
                            owner:
                                const generated_wallet.XelisAssetOwner.none(),
                          ),
                        ),
                      ),
                    ),
                    expectedGeneration: BigInt.one,
                    expectedSequence: BigInt.one,
                  ).event
                  as XelisWalletNewAsset)
              .asset;
      expect(unownedAsset.metadata.owner, isA<XelisWalletNoAssetOwner>());

      final degraded =
          adaptBusinessEventFrame(
                _frame(event: nativeEvents[6]),
                expectedGeneration: BigInt.one,
                expectedSequence: BigInt.one,
              ).event
              as XelisWalletBusinessEventStreamDegraded;
      expect(degraded.failure.supportId, startsWith('XWF-'));
      expect(
        degraded.failure.operation,
        XelisWalletOperation.walletBusinessEventsStream,
      );
    });

    test('rejects version, generation, and sequence mismatches', () {
      expect(
        () => adaptBusinessEventFrame(
          _frame(version: 2),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.one,
        ),
        throwsA(
          isA<XelisWalletBridgeException>().having(
            (error) => error.nativeKind,
            'nativeKind',
            'NATIVE_BUSINESS_EVENT_CONTRACT_VERSION_2',
          ),
        ),
      );
      expect(
        () => adaptBusinessEventFrame(
          _frame(generation: BigInt.two),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.one,
        ),
        throwsA(isA<XelisWalletBridgeException>()),
      );
      expect(
        () => adaptBusinessEventFrame(
          _frame(sequence: BigInt.two),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.one,
        ),
        throwsA(isA<XelisWalletBridgeException>()),
      );
    });
  });

  test(
    'business subscription is pull-driven and cancellation is idempotent',
    () async {
      final delegate = _FakeGeneratedBusinessSubscription();
      final subscription = NativeXelisWalletBusinessEventSubscription(delegate);
      final received = <XelisWalletBusinessEventFrame>[];
      final listener = subscription.events.listen(received.add);

      await pumpEventQueue();
      expect(delegate.nextCallCount, 1);
      delegate.emit(_frame());
      await pumpEventQueue();
      expect(received, hasLength(1));
      expect(delegate.nextCallCount, 2);

      await Future.wait([subscription.cancel(), subscription.cancel()]);
      await listener.cancel();
      expect(delegate.cancelCount, 1);
      expect(delegate.disposeCount, 1);
    },
  );

  test('business subscription emits typed close and then completes', () async {
    final delegate = _FakeGeneratedBusinessSubscription();
    final subscription = NativeXelisWalletBusinessEventSubscription(delegate);
    final received = <XelisWalletBusinessEventFrame>[];
    final done = Completer<void>();
    subscription.events.listen(received.add, onDone: done.complete);
    await pumpEventQueue();

    delegate.emit(
      _frame(
        event: generated_event.NativeWalletBusinessEvent.closed(
          reason: generated_event
              .NativeWalletBusinessStreamCloseReason
              .nativeChannelClosed,
          failure: _nativeFailure(
            code: generated_error.NativeXelisErrorCode.streamClosedUnexpectedly,
            nativeKind: 'WALLET_BUSINESS_EVENT_STREAM_CLOSED',
          ),
        ),
      ),
    );

    await done.future;
    expect(received, hasLength(1));
    expect(received.single.event, isA<XelisWalletBusinessEventStreamClosed>());
    expect(delegate.nextCallCount, 1);
    expect(delegate.cancelCount, 1);
    expect(delegate.disposeCount, 1);
  });

  test('business subscription preserves native read failures', () async {
    final delegate = _FakeGeneratedBusinessSubscription();
    final subscription = NativeXelisWalletBusinessEventSubscription(delegate);
    final errorCompleter = Completer<Object>();
    final done = Completer<void>();
    subscription.events.listen(
      (_) {},
      onError: (Object error) => errorCompleter.complete(error),
      onDone: done.complete,
    );
    await pumpEventQueue();

    delegate.fail(
      _nativeFailure(
        code: generated_error.NativeXelisErrorCode.operationInProgress,
        nativeKind: 'WALLET_BUSINESS_EVENT_NEXT_IN_PROGRESS',
      ),
    );

    final error = await errorCompleter.future as XelisWalletException;
    await done.future;
    expect(error.operation, XelisWalletOperation.walletBusinessEventsStream);
    expect(error.code, XelisWalletErrorCode.operationInProgress);
    expect(error.diagnosticMessage, 'native diagnostic');
    expect(error.toString(), isNot(contains('native diagnostic')));
    expect(delegate.disposeCount, 1);
  });

  test(
    'wallet close cancels business subscriptions before closing native wallet',
    () async {
      final calls = <String>[];
      final delegateSubscription = _FakeGeneratedBusinessSubscription(
        calls: calls,
      );
      final delegateWallet = _FakeGeneratedWallet(
        subscription: delegateSubscription,
        calls: calls,
      );
      final wallet = NativeXelisWallet(delegateWallet);

      final subscription = await wallet.subscribeBusinessEvents();
      await wallet.close();

      expect(subscription.isCancelled, isTrue);
      expect(calls, [
        'wallet.subscribe',
        'subscription.cancel',
        'subscription.dispose',
        'wallet.close',
      ]);
      expect(
        delegateWallet.lastDisclosure,
        generated_event.NativeWalletExtraDataDisclosure.redacted,
      );
    },
  );

  test('business subscription forwards its fixed disclosure level', () async {
    final delegateSubscription = _FakeGeneratedBusinessSubscription();
    final delegateWallet = _FakeGeneratedWallet(
      subscription: delegateSubscription,
      calls: <String>[],
    );
    final wallet = NativeXelisWallet(delegateWallet);

    final subscription = await wallet.subscribeBusinessEvents(
      extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
    );

    expect(
      delegateWallet.lastDisclosure,
      generated_event.NativeWalletExtraDataDisclosure.detailed,
    );
    await subscription.cancel();
  });
}

generated_error.NativeXelisError _nativeFailure({
  required generated_error.NativeXelisErrorCode code,
  required String nativeKind,
}) => generated_error.NativeXelisError(
  version: XelisWalletErrorContract.currentVersion,
  source: generated_error.NativeXelisErrorSource.xelisWalletFlutter,
  code: code,
  nativeKind: nativeKind,
  diagnosticMessage: 'native diagnostic',
);

generated_event.NativeWalletBusinessEventFrame _frame({
  int version = XelisWalletBusinessEventContract.currentVersion,
  BigInt? generation,
  BigInt? sequence,
  generated_event.NativeWalletBusinessEvent event =
      const generated_event.NativeWalletBusinessEvent.assetTracked(
        asset: 'asset',
      ),
}) => generated_event.NativeWalletBusinessEventFrame(
  version: version,
  generation: generation ?? BigInt.one,
  sequence: sequence ?? BigInt.one,
  event: event,
);

final class _FakeGeneratedBusinessSubscription
    implements generated_subscription.WalletBusinessEventSubscription {
  _FakeGeneratedBusinessSubscription({this.calls});

  final List<String>? calls;
  final Queue<Completer<generated_event.NativeWalletBusinessEventFrame?>>
  _pending = Queue();
  final Queue<generated_event.NativeWalletBusinessEventFrame?> _queued =
      Queue();
  int nextCallCount = 0;
  int cancelCount = 0;
  int disposeCount = 0;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  BigInt generation() => BigInt.one;

  @override
  Future<generated_event.NativeWalletBusinessEventFrame?> nextEvent() {
    nextCallCount++;
    if (_queued.isNotEmpty) {
      return Future.value(_queued.removeFirst());
    }
    final completer =
        Completer<generated_event.NativeWalletBusinessEventFrame?>();
    _pending.add(completer);
    return completer.future;
  }

  void emit(generated_event.NativeWalletBusinessEventFrame frame) {
    if (_pending.isEmpty) {
      _queued.add(frame);
    } else {
      _pending.removeFirst().complete(frame);
    }
  }

  void fail(Object error) {
    _pending.removeFirst().completeError(error, StackTrace.current);
  }

  @override
  void cancel() {
    cancelCount++;
    calls?.add('subscription.cancel');
    while (_pending.isNotEmpty) {
      _pending.removeFirst().complete(null);
    }
  }

  @override
  void dispose() {
    disposeCount++;
    calls?.add('subscription.dispose');
    _isDisposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _FakeGeneratedWallet implements generated_wallet_api.XelisWallet {
  _FakeGeneratedWallet({required this.subscription, required this.calls});

  final generated_subscription.WalletBusinessEventSubscription subscription;
  final List<String> calls;
  generated_event.NativeWalletExtraDataDisclosure? lastDisclosure;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  Future<generated_subscription.WalletBusinessEventSubscription>
  subscribeBusinessEvents({
    required generated_event.NativeWalletExtraDataDisclosure
    extraDataDisclosure,
  }) async {
    calls.add('wallet.subscribe');
    lastDisclosure = extraDataDisclosure;
    return subscription;
  }

  @override
  Future<void> close() async {
    calls.add('wallet.close');
  }

  @override
  void dispose() {
    _isDisposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
