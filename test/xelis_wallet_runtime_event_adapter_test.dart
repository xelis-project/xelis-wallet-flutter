import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_runtime_event_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/runtime_event_dtos.dart'
    as generated_event;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet/runtime_events.dart'
    as generated_subscription;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('runtime event mapping', () {
    test('maps every runtime variant and preserves lossless integers', () {
      final huge = BigInt.parse('18446744073709551614');
      final nativeEvents = <generated_event.NativeWalletRuntimeEvent>[
        const generated_event.NativeWalletRuntimeEvent.online(),
        const generated_event.NativeWalletRuntimeEvent.offline(),
        generated_event.NativeWalletRuntimeEvent.syncIssue(
          failure: _nativeFailure(
            source: generated_error.NativeXelisErrorSource.xelisWallet,
            code: generated_error.NativeXelisErrorCode.operationFailed,
            nativeKind: 'WALLET_SYNC_ERROR',
            diagnosticMessage: r'sync failed near C:\private\wallet.db',
          ),
        ),
        generated_event.NativeWalletRuntimeEvent.newTopoHeight(
          topoheight: huge,
        ),
        generated_event.NativeWalletRuntimeEvent.rescan(
          startTopoheight: huge - BigInt.one,
        ),
        generated_event.NativeWalletRuntimeEvent.historySynced(
          topoheight: huge - BigInt.two,
        ),
        generated_event.NativeWalletRuntimeEvent.degraded(
          skippedEvents: huge,
          failure: _nativeFailure(
            source: generated_error.NativeXelisErrorSource.xelisWalletFlutter,
            code: generated_error.NativeXelisErrorCode.streamLagged,
            nativeKind: 'WALLET_EVENTS_LAGGED',
            diagnosticMessage: 'Skipped $huge upstream events',
          ),
        ),
        generated_event.NativeWalletRuntimeEvent.closed(
          reason: generated_event
              .NativeWalletRuntimeStreamCloseReason
              .nativeChannelClosed,
          failure: _nativeFailure(
            source: generated_error.NativeXelisErrorSource.xelisWalletFlutter,
            code: generated_error.NativeXelisErrorCode.streamClosedUnexpectedly,
            nativeKind: 'WALLET_EVENT_STREAM_CLOSED',
            diagnosticMessage: 'Native channel closed',
          ),
        ),
      ];

      final mapped = <XelisWalletRuntimeEvent>[];
      for (var index = 0; index < nativeEvents.length; index++) {
        final sequence = BigInt.from(index + 1);
        mapped.add(
          adaptRuntimeEventFrame(
            generated_event.NativeWalletRuntimeEventFrame(
              version: XelisWalletRuntimeEventContract.currentVersion,
              generation: huge,
              sequence: sequence,
              event: nativeEvents[index],
            ),
            expectedGeneration: huge,
            expectedSequence: sequence,
          ).event,
        );
      }

      expect(mapped[0], isA<XelisWalletOnline>());
      expect(mapped[1], isA<XelisWalletOffline>());

      final syncIssue = mapped[2] as XelisWalletSyncIssue;
      expect(syncIssue.failure.source, XelisWalletErrorSource.xelisWallet);
      expect(syncIssue.failure.operation, XelisWalletOperation.walletSync);
      expect(syncIssue.failure.code, XelisWalletErrorCode.operationFailed);
      expect(syncIssue.failure.nativeKind, 'WALLET_SYNC_ERROR');
      expect(syncIssue.failure.diagnosticMessage, contains('private'));
      expect(syncIssue.failure.toString(), isNot(contains('private')));

      expect((mapped[3] as XelisWalletTopoheightChanged).topoheight, huge);
      expect(
        (mapped[4] as XelisWalletRescanStarted).startTopoheight,
        huge - BigInt.one,
      );
      expect(
        (mapped[5] as XelisWalletHistorySynced).topoheight,
        huge - BigInt.two,
      );

      final degraded = mapped[6] as XelisWalletEventStreamDegraded;
      expect(degraded.skippedEvents, huge);
      expect(degraded.failure.code, XelisWalletErrorCode.streamLagged);
      expect(
        degraded.failure.operation,
        XelisWalletOperation.walletEventsStream,
      );

      final closed = mapped[7] as XelisWalletEventStreamClosed;
      expect(
        closed.reason,
        XelisWalletRuntimeStreamCloseReason.nativeChannelClosed,
      );
      expect(
        closed.failure.code,
        XelisWalletErrorCode.streamClosedUnexpectedly,
      );
    });

    test('rejects an unsupported contract version', () {
      expect(
        () => adaptRuntimeEventFrame(
          _frame(version: 2),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.one,
        ),
        throwsA(
          isA<XelisWalletBridgeException>()
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.bridgeFailure,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'NATIVE_RUNTIME_EVENT_CONTRACT_VERSION_2',
              ),
        ),
      );
    });

    test('rejects generation and sequence mismatches', () {
      expect(
        () => adaptRuntimeEventFrame(
          _frame(generation: BigInt.two),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.one,
        ),
        throwsA(
          isA<XelisWalletBridgeException>().having(
            (error) => error.nativeKind,
            'nativeKind',
            'NATIVE_RUNTIME_EVENT_GENERATION_MISMATCH',
          ),
        ),
      );
      expect(
        () => adaptRuntimeEventFrame(
          _frame(sequence: BigInt.two),
          expectedGeneration: BigInt.one,
          expectedSequence: BigInt.one,
        ),
        throwsA(
          isA<XelisWalletBridgeException>().having(
            (error) => error.nativeKind,
            'nativeKind',
            'NATIVE_RUNTIME_EVENT_SEQUENCE_MISMATCH',
          ),
        ),
      );
    });
  });

  group('runtime event subscription', () {
    test('pulls one frame at a time and stops pulling while paused', () async {
      final delegate = _FakeGeneratedSubscription();
      final subscription = NativeXelisWalletRuntimeEventSubscription(delegate);
      final received = <XelisWalletRuntimeEventFrame>[];
      final done = Completer<void>();
      final listener = subscription.events.listen(
        received.add,
        onDone: done.complete,
      );

      await pumpEventQueue();
      expect(delegate.nextCallCount, 1);

      delegate.emit(_frame());
      await pumpEventQueue();
      expect(received, hasLength(1));
      expect(delegate.nextCallCount, 2);

      listener.pause();
      delegate.emit(_frame(sequence: BigInt.two));
      await pumpEventQueue();
      expect(received, hasLength(1));
      expect(delegate.nextCallCount, 2);

      listener.resume();
      await pumpEventQueue();
      expect(received, hasLength(2));
      expect(delegate.nextCallCount, 3);

      await subscription.cancel();
      await done.future;
      expect(subscription.isCancelled, isTrue);
      expect(delegate.cancelCount, 1);
      expect(delegate.disposeCount, 1);
      expect(delegate.isDisposed, isTrue);
    });

    test('is single-subscription and cancellation is idempotent', () async {
      final delegate = _FakeGeneratedSubscription();
      final subscription = NativeXelisWalletRuntimeEventSubscription(delegate);
      final first = subscription.events.listen((_) {});

      expect(() => subscription.events.listen((_) {}), throwsStateError);
      await Future.wait([subscription.cancel(), subscription.cancel()]);
      await first.cancel();

      expect(delegate.cancelCount, 1);
      expect(delegate.disposeCount, 1);
    });

    test('drops an in-flight frame when cancelled while paused', () async {
      final delegate = _FakeGeneratedSubscription();
      final subscription = NativeXelisWalletRuntimeEventSubscription(delegate);
      final received = <XelisWalletRuntimeEventFrame>[];
      final listener = subscription.events.listen(received.add);

      await pumpEventQueue();
      listener.pause();
      delegate.emit(_frame());
      await pumpEventQueue();
      expect(received, isEmpty);

      await subscription.cancel();
      listener.resume();
      await pumpEventQueue();

      expect(received, isEmpty);
      expect(delegate.cancelCount, 1);
      expect(delegate.disposeCount, 1);
      await listener.cancel();
    });

    test('retries native cancellation after a bridge failure', () async {
      final cancelError = StateError('native cancel failed');
      final delegate = _FakeGeneratedSubscription(
        cancelFailures: Queue.of([cancelError]),
      );
      final subscription = NativeXelisWalletRuntimeEventSubscription(delegate);
      final listener = subscription.events.listen((_) {});
      await pumpEventQueue();

      await expectLater(subscription.cancel(), throwsA(same(cancelError)));
      expect(delegate.cancelCount, 1);
      expect(delegate.disposeCount, 0);

      await subscription.cancel();
      expect(delegate.cancelCount, 2);
      expect(delegate.disposeCount, 1);
      await listener.cancel();
    });

    test('emits one typed close frame and then completes', () async {
      final delegate = _FakeGeneratedSubscription();
      final subscription = NativeXelisWalletRuntimeEventSubscription(delegate);
      final received = <XelisWalletRuntimeEventFrame>[];
      final done = Completer<void>();
      subscription.events.listen(received.add, onDone: done.complete);
      await pumpEventQueue();

      delegate.emit(
        _frame(
          event: generated_event.NativeWalletRuntimeEvent.closed(
            reason: generated_event
                .NativeWalletRuntimeStreamCloseReason
                .nativeChannelClosed,
            failure: _nativeFailure(
              source: generated_error.NativeXelisErrorSource.xelisWalletFlutter,
              code:
                  generated_error.NativeXelisErrorCode.streamClosedUnexpectedly,
              nativeKind: 'WALLET_EVENT_STREAM_CLOSED',
              diagnosticMessage: 'closed',
            ),
          ),
        ),
      );

      await done.future;
      expect(received, hasLength(1));
      expect(received.single.event, isA<XelisWalletEventStreamClosed>());
      expect(delegate.nextCallCount, 1);
      expect(delegate.cancelCount, 1);
      expect(delegate.disposeCount, 1);
    });

    test('adapts native read failures at the stream boundary', () async {
      final delegate = _FakeGeneratedSubscription();
      final subscription = NativeXelisWalletRuntimeEventSubscription(delegate);
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
          source: generated_error.NativeXelisErrorSource.xelisWalletFlutter,
          code: generated_error.NativeXelisErrorCode.operationInProgress,
          nativeKind: 'WALLET_EVENT_NEXT_IN_PROGRESS',
          diagnosticMessage: 'private read detail',
        ),
      );

      final error = await errorCompleter.future as XelisWalletException;
      await done.future;
      expect(error.operation, XelisWalletOperation.walletEventsStream);
      expect(error.code, XelisWalletErrorCode.operationInProgress);
      expect(error.diagnosticMessage, 'private read detail');
      expect(error.toString(), isNot(contains('private')));
      expect(delegate.disposeCount, 1);
    });

    test(
      'wallet close cancels subscriptions before closing native wallet',
      () async {
        final calls = <String>[];
        final delegateSubscription = _FakeGeneratedSubscription(calls: calls);
        final delegateWallet = _FakeGeneratedWallet(
          subscription: delegateSubscription,
          calls: calls,
        );
        final wallet = NativeXelisWallet(delegateWallet);

        final subscription = await wallet.subscribeRuntimeEvents();
        await wallet.close();

        expect(subscription.isCancelled, isTrue);
        expect(calls, [
          'wallet.subscribe',
          'subscription.cancel',
          'subscription.dispose',
          'wallet.close',
        ]);
      },
    );

    test(
      'cleans up the native subscription when adapter construction fails',
      () async {
        final generationError = StateError('generation read failed');
        final delegateSubscription = _FakeGeneratedSubscription(
          generationError: generationError,
          cancelFailures: Queue.of([StateError('cleanup cancel failed')]),
        );
        final delegateWallet = _FakeGeneratedWallet(
          subscription: delegateSubscription,
          calls: <String>[],
        );
        final wallet = NativeXelisWallet(delegateWallet);

        await expectLater(
          wallet.subscribeRuntimeEvents(),
          throwsA(same(generationError)),
        );

        expect(delegateSubscription.cancelCount, 1);
        expect(delegateSubscription.disposeCount, 1);
        expect(delegateSubscription.isDisposed, isTrue);
        await wallet.close();
        wallet.dispose();
      },
    );
  });
}

generated_error.NativeXelisError _nativeFailure({
  required generated_error.NativeXelisErrorSource source,
  required generated_error.NativeXelisErrorCode code,
  required String nativeKind,
  required String diagnosticMessage,
}) => generated_error.NativeXelisError(
  version: XelisWalletErrorContract.currentVersion,
  source: source,
  code: code,
  nativeKind: nativeKind,
  diagnosticMessage: diagnosticMessage,
);

generated_event.NativeWalletRuntimeEventFrame _frame({
  int version = XelisWalletRuntimeEventContract.currentVersion,
  BigInt? generation,
  BigInt? sequence,
  generated_event.NativeWalletRuntimeEvent event =
      const generated_event.NativeWalletRuntimeEvent.online(),
}) => generated_event.NativeWalletRuntimeEventFrame(
  version: version,
  generation: generation ?? BigInt.one,
  sequence: sequence ?? BigInt.one,
  event: event,
);

final class _FakeGeneratedSubscription
    implements generated_subscription.WalletRuntimeEventSubscription {
  _FakeGeneratedSubscription({
    this.calls,
    this.generationError,
    Queue<Object>? cancelFailures,
  }) : cancelFailures = cancelFailures ?? Queue<Object>();

  final List<String>? calls;
  final Object? generationError;
  final Queue<Object> cancelFailures;
  final Queue<Completer<generated_event.NativeWalletRuntimeEventFrame?>>
  _pending = Queue();
  final Queue<generated_event.NativeWalletRuntimeEventFrame?> _queued = Queue();
  int nextCallCount = 0;
  int cancelCount = 0;
  int disposeCount = 0;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  BigInt generation() {
    final error = generationError;
    if (error != null) {
      throw error;
    }
    return BigInt.one;
  }

  @override
  Future<generated_event.NativeWalletRuntimeEventFrame?> nextEvent() {
    nextCallCount++;
    if (_queued.isNotEmpty) {
      return Future.value(_queued.removeFirst());
    }
    final completer =
        Completer<generated_event.NativeWalletRuntimeEventFrame?>();
    _pending.add(completer);
    return completer.future;
  }

  void emit(generated_event.NativeWalletRuntimeEventFrame frame) {
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
    if (cancelFailures.isNotEmpty) {
      throw cancelFailures.removeFirst();
    }
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

final class _FakeGeneratedWallet implements generated_wallet.XelisWallet {
  _FakeGeneratedWallet({required this.subscription, required this.calls});

  final generated_subscription.WalletRuntimeEventSubscription subscription;
  final List<String> calls;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  Future<generated_subscription.WalletRuntimeEventSubscription>
  subscribeRuntimeEvents() async {
    calls.add('wallet.subscribe');
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
