import 'dart:async';

import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/runtime/xelis_wallet_runtime_event.dart';
import '../../api/runtime/xelis_wallet_runtime_event_subscription.dart';
import '../../generated/rust_bridge/api/error.dart' as generated_error;
import '../../generated/rust_bridge/api/models/runtime_event_dtos.dart'
    as generated_event;
import '../../generated/rust_bridge/api/wallet/runtime_events.dart'
    as generated_subscription;
import 'xelis_error_adapter.dart';

typedef NativeRuntimeSubscriptionTerminated =
    void Function(NativeXelisWalletRuntimeEventSubscription subscription);

/// Private bridge implementation of the authored runtime-event subscription.
///
/// The class is public only for package-internal tests and is not exported by
/// the supported root library.
final class NativeXelisWalletRuntimeEventSubscription
    implements XelisWalletRuntimeEventSubscription {
  NativeXelisWalletRuntimeEventSubscription(
    this._delegate, {
    NativeRuntimeSubscriptionTerminated? onTerminated,
  }) : _onTerminated = onTerminated {
    generation = guardXelisCall(
      _delegate.generation,
      boundary: _subscribeBoundary,
    );
    _controller = StreamController<XelisWalletRuntimeEventFrame>(
      sync: true,
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: cancel,
    );
  }

  static const _subscribeBoundary = XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletEventsSubscribe,
  );
  static const _streamBoundary = XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletEventsStream,
  );
  static const _cancelBoundary = XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWalletFlutter,
    operation: XelisWalletOperation.walletEventsCancel,
  );

  final generated_subscription.WalletRuntimeEventSubscription _delegate;
  final NativeRuntimeSubscriptionTerminated? _onTerminated;
  late final StreamController<XelisWalletRuntimeEventFrame> _controller;

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
  Stream<XelisWalletRuntimeEventFrame> get events => _controller.stream;

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
      // A synchronous bridge cancellation failure may mean that Rust never
      // received the wake-up. Keep the opaque handle alive and allow callers
      // (including wallet.close()) to retry instead of caching a failed
      // cancellation forever or disposing during an in-flight native read.
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

        // The listener may have been paused while the native read was in
        // flight. Hold its single returned frame here instead of letting the
        // StreamController buffer it, so cancellation can discard it before a
        // later resume delivers a stale callback.
        await _waitWhilePaused();
        if (_cancelRequested) {
          break;
        }

        final frame = adaptRuntimeEventFrame(
          nativeFrame,
          expectedGeneration: generation,
          expectedSequence: _expectedSequence,
        );
        _expectedSequence += BigInt.one;
        _controller.add(frame);
        if (frame.event is XelisWalletEventStreamClosed) {
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

XelisWalletRuntimeEventFrame adaptRuntimeEventFrame(
  generated_event.NativeWalletRuntimeEventFrame frame, {
  required BigInt expectedGeneration,
  required BigInt expectedSequence,
}) {
  if (frame.version != XelisWalletRuntimeEventContract.currentVersion) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletEventsStream,
      nativeKind: 'NATIVE_RUNTIME_EVENT_CONTRACT_VERSION_${frame.version}',
      diagnosticMessage:
          'Unsupported native runtime event contract version ${frame.version}.',
    );
  }
  if (frame.generation != expectedGeneration) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletEventsStream,
      nativeKind: 'NATIVE_RUNTIME_EVENT_GENERATION_MISMATCH',
      diagnosticMessage:
          'Expected runtime event generation $expectedGeneration but received '
          '${frame.generation}.',
    );
  }
  if (frame.sequence != expectedSequence) {
    throw xelisBridgeContractException(
      operation: XelisWalletOperation.walletEventsStream,
      nativeKind: 'NATIVE_RUNTIME_EVENT_SEQUENCE_MISMATCH',
      diagnosticMessage:
          'Expected runtime event sequence $expectedSequence but received '
          '${frame.sequence}.',
    );
  }

  return XelisWalletRuntimeEventFrame(
    contractVersion: frame.version,
    generation: frame.generation,
    sequence: frame.sequence,
    event: _adaptRuntimeEvent(frame.event),
  );
}

XelisWalletRuntimeEvent _adaptRuntimeEvent(
  generated_event.NativeWalletRuntimeEvent event,
) => switch (event) {
  generated_event.NativeWalletRuntimeEvent_Online() =>
    const XelisWalletOnline(),
  generated_event.NativeWalletRuntimeEvent_Offline() =>
    const XelisWalletOffline(),
  generated_event.NativeWalletRuntimeEvent_SyncIssue(:final failure) =>
    XelisWalletSyncIssue(
      failure: _adaptEventFailure(
        failure,
        operation: XelisWalletOperation.walletSync,
      ),
    ),
  generated_event.NativeWalletRuntimeEvent_NewTopoHeight(:final topoheight) =>
    XelisWalletTopoheightChanged(topoheight: topoheight),
  generated_event.NativeWalletRuntimeEvent_Rescan(:final startTopoheight) =>
    XelisWalletRescanStarted(startTopoheight: startTopoheight),
  generated_event.NativeWalletRuntimeEvent_HistorySynced(:final topoheight) =>
    XelisWalletHistorySynced(topoheight: topoheight),
  generated_event.NativeWalletRuntimeEvent_Degraded(
    :final skippedEvents,
    :final failure,
  ) =>
    XelisWalletEventStreamDegraded(
      skippedEvents: skippedEvents,
      failure: _adaptEventFailure(
        failure,
        operation: XelisWalletOperation.walletEventsStream,
      ),
    ),
  generated_event.NativeWalletRuntimeEvent_Closed(
    :final reason,
    :final failure,
  ) =>
    XelisWalletEventStreamClosed(
      reason: switch (reason) {
        generated_event
            .NativeWalletRuntimeStreamCloseReason
            .nativeChannelClosed =>
          XelisWalletRuntimeStreamCloseReason.nativeChannelClosed,
      },
      failure: _adaptEventFailure(
        failure,
        operation: XelisWalletOperation.walletEventsStream,
      ),
    ),
};

XelisWalletException _adaptEventFailure(
  generated_error.NativeXelisError failure, {
  required XelisWalletOperation operation,
}) =>
    adaptXelisError(
          failure,
          boundary: XelisErrorBoundary(
            source: XelisWalletErrorSource.xelisWalletFlutter,
            operation: operation,
          ),
        )
        as XelisWalletException;
