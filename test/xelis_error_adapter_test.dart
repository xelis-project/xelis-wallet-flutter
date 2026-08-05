import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/api/errors/xelis_wallet_exception.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_error_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;

const _seedSearchBoundary = XelisErrorBoundary(
  source: XelisWalletErrorSource.xelisWallet,
  operation: XelisWalletOperation.seedSearch,
);
const _runtimeBoundary = XelisErrorBoundary(
  source: XelisWalletErrorSource.xelisWalletFlutter,
  operation: XelisWalletOperation.runtimeInitialize,
);

void main() {
  test('maps anyhow errors to safe structured metadata', () {
    final mapped = adaptXelisError(
      AnyhowException('Cannot open wallet\n\ninternal context'),
      boundary: _seedSearchBoundary,
      supportIdFactory: () => 'XWF-1111-2222-3333-4444-5555',
    );

    expect(mapped, isA<XelisWalletOperationException>());
    final exception = mapped as XelisWalletOperationException;
    expect(exception.contractVersion, XelisWalletErrorContract.currentVersion);
    expect(exception.source, XelisWalletErrorSource.xelisWallet);
    expect(exception.operation, XelisWalletOperation.seedSearch);
    expect(exception.code, XelisWalletErrorCode.operationFailed);
    expect(exception.supportId, 'XWF-1111-2222-3333-4444-5555');
    expect(
      exception.diagnosticMessage,
      'Cannot open wallet\n\ninternal context',
    );
    expect(exception.nativeKind, isNull);
    expect(exception.nativeCode, isNull);
    expect(exception.toString(), contains('source=xelisWallet'));
    expect(exception.toString(), contains('operation=seed_search.search'));
    expect(exception.toString(), contains('code=operation.failed'));
    expect(exception.toString(), contains(exception.supportId));
    expect(exception.toString(), isNot(contains('internal context')));
  });

  test('creates distinct opaque support identifiers', () {
    final first =
        adaptXelisError(AnyhowException('first'), boundary: _seedSearchBoundary)
            as XelisWalletException;
    final second =
        adaptXelisError(
              AnyhowException('second'),
              boundary: _seedSearchBoundary,
            )
            as XelisWalletException;

    final pattern = RegExp(r'^XWF-(?:[0-9A-F]{4}-){4}[0-9A-F]{4}$');
    expect(first.supportId, matches(pattern));
    expect(second.supportId, matches(pattern));
    expect(second.supportId, isNot(first.supportId));
  });

  test('maps structured native metadata without parsing diagnostics', () {
    final mapped = adaptXelisError(
      const generated_error.NativeXelisError(
        version: 1,
        source: generated_error.NativeXelisErrorSource.xelisCommon,
        code: generated_error.NativeXelisErrorCode.remoteRejected,
        nativeKind: 'SERVER_ERROR',
        nativeCode: -32042,
        diagnosticMessage: 'daemon rejected request at C:\\private\\wallet',
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.configurationInitialize,
      ),
      supportIdFactory: () => 'XWF-1111-2222-3333-4444-5555',
    );

    expect(mapped, isA<XelisWalletOperationException>());
    final exception = mapped as XelisWalletOperationException;
    expect(exception.contractVersion, 1);
    expect(exception.source, XelisWalletErrorSource.xelisCommon);
    expect(exception.operation, XelisWalletOperation.configurationInitialize);
    expect(exception.code, XelisWalletErrorCode.daemonRejected);
    expect(exception.nativeKind, 'SERVER_ERROR');
    expect(exception.nativeCode, -32042);
    expect(exception.diagnosticMessage, contains(r'C:\private\wallet'));
    expect(exception.toString(), isNot(contains('private')));
  });

  test('maps dedicated native recovery codes', () {
    const supportId = 'XWF-1111-2222-3333-4444-5555';
    final authentication =
        adaptXelisError(
              const generated_error.NativeXelisError(
                version: 1,
                source: generated_error.NativeXelisErrorSource.xelisWallet,
                code: generated_error
                    .NativeXelisErrorCode
                    .authenticationOrCorruptData,
                nativeKind: 'INVALID_ENCRYPTED_VALUE',
                diagnosticMessage: 'invalid encrypted value',
              ),
              boundary: _runtimeBoundary,
              supportIdFactory: () => supportId,
            )
            as XelisWalletOperationException;
    final mismatch =
        adaptXelisError(
              const generated_error.NativeXelisError(
                version: 1,
                source: generated_error.NativeXelisErrorSource.xelisWallet,
                code: generated_error.NativeXelisErrorCode.networkMismatch,
                nativeKind: 'NETWORK_MISMATCH',
                diagnosticMessage: 'network mismatch',
              ),
              boundary: _runtimeBoundary,
              supportIdFactory: () => supportId,
            )
            as XelisWalletOperationException;
    final cancelled =
        adaptXelisError(
              const generated_error.NativeXelisError(
                version: 1,
                source: generated_error.NativeXelisErrorSource.xelisWallet,
                code: generated_error.NativeXelisErrorCode.cancelled,
                nativeKind: 'NETWORK_CONNECT_CANCELLED',
                diagnosticMessage: 'connection cancelled',
              ),
              boundary: _runtimeBoundary,
              supportIdFactory: () => supportId,
            )
            as XelisWalletOperationException;
    final inProgress =
        adaptXelisError(
              const generated_error.NativeXelisError(
                version: 1,
                source:
                    generated_error.NativeXelisErrorSource.xelisWalletFlutter,
                code: generated_error.NativeXelisErrorCode.operationInProgress,
                nativeKind: 'NETWORK_CONNECT_IN_PROGRESS',
                diagnosticMessage: 'connection attempt in progress',
              ),
              boundary: _runtimeBoundary,
              supportIdFactory: () => supportId,
            )
            as XelisWalletOperationException;

    expect(
      authentication.code,
      XelisWalletErrorCode.authenticationOrCorruptData,
    );
    expect(mismatch.code, XelisWalletErrorCode.networkMismatch);
    expect(cancelled.code, XelisWalletErrorCode.cancelled);
    expect(inProgress.code, XelisWalletErrorCode.operationInProgress);
  });

  test('rejects an unsupported native error contract version', () {
    final mapped = adaptXelisError(
      const generated_error.NativeXelisError(
        version: 2,
        source: generated_error.NativeXelisErrorSource.xelisCommon,
        code: generated_error.NativeXelisErrorCode.remoteRejected,
        nativeKind: 'SERVER_ERROR',
        nativeCode: -32042,
        diagnosticMessage: 'private future-version diagnostic',
      ),
      boundary: _runtimeBoundary,
      supportIdFactory: () => 'XWF-1111-2222-3333-4444-5555',
    );

    expect(mapped, isA<XelisWalletBridgeException>());
    final exception = mapped as XelisWalletBridgeException;
    expect(exception.contractVersion, XelisWalletErrorContract.currentVersion);
    expect(exception.source, XelisWalletErrorSource.flutterRustBridge);
    expect(exception.code, XelisWalletErrorCode.bridgeFailure);
    expect(exception.nativeKind, 'NATIVE_ERROR_CONTRACT_VERSION_2');
    expect(exception.diagnosticMessage, contains('future-version diagnostic'));
    expect(exception.toString(), isNot(contains('future-version')));
  });

  test('classifies public bridge failures by concrete FRB type', () {
    final panic =
        adaptXelisError(
              PanicException('native panic'),
              boundary: _runtimeBoundary,
              supportIdFactory: () => 'XWF-AAAA-BBBB-CCCC-DDDD-EEEE',
            )
            as XelisWalletBridgeException;
    final platform =
        adaptXelisError(
              const PlatformMismatchException(),
              boundary: _runtimeBoundary,
              supportIdFactory: () => 'XWF-AAAA-BBBB-CCCC-DDDD-EEEE',
            )
            as XelisWalletBridgeException;
    expect(panic.source, XelisWalletErrorSource.flutterRustBridge);
    expect(panic.code, XelisWalletErrorCode.nativePanic);
    expect(panic.diagnosticMessage, 'native panic');
    expect(platform.source, XelisWalletErrorSource.platform);
    expect(platform.code, XelisWalletErrorCode.unsupportedPlatform);
  });

  test('keeps authored and unrelated Dart errors by identity', () {
    const authored = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.seedSearch,
      code: XelisWalletErrorCode.operationFailed,
      supportId: 'XWF-1111-2222-3333-4444-5555',
      diagnosticMessage: 'wallet error',
    );
    final unrelated = StateError('application error');

    expect(
      adaptXelisError(authored, boundary: _seedSearchBoundary),
      same(authored),
    );
    expect(
      adaptXelisError(unrelated, boundary: _seedSearchBoundary),
      same(unrelated),
    );
  });

  test('preserves the original stack for synchronous failures', () {
    final originalStack = StackTrace.current;
    Object? caughtError;
    StackTrace? caughtStack;

    try {
      guardXelisCall<void>(
        () => Error.throwWithStackTrace(
          AnyhowException('synchronous failure'),
          originalStack,
        ),
        boundary: _seedSearchBoundary,
      );
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStack = stackTrace;
    }

    expect(caughtError, isA<XelisWalletOperationException>());
    expect(caughtStack.toString(), originalStack.toString());
  });

  test(
    'maps synchronous failures from an asynchronous operation thunk',
    () async {
      final future = guardXelisFuture<void>(
        () => throw AnyhowException('future setup failed'),
        boundary: _runtimeBoundary,
      );

      await expectLater(future, throwsA(isA<XelisWalletOperationException>()));
    },
  );

  test('preserves the original stack for asynchronous failures', () async {
    final originalStack = StackTrace.current;
    Object? caughtError;
    StackTrace? caughtStack;

    try {
      await guardXelisFuture<void>(
        () => Future<void>.error(
          AnyhowException('asynchronous failure'),
          originalStack,
        ),
        boundary: _runtimeBoundary,
      );
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStack = stackTrace;
    }

    expect(caughtError, isA<XelisWalletOperationException>());
    expect(caughtStack.toString(), originalStack.toString());
  });

  test('maps stream errors and preserves broadcast lifecycle', () async {
    var wasCancelled = false;
    final source = StreamController<int>.broadcast(
      onCancel: () {
        wasCancelled = true;
      },
    );
    final stream = guardXelisStream(
      () => source.stream,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.loggingStream,
      ),
    );
    final values = <int>[];
    final errors = <Object>[];
    final errorStacks = <StackTrace>[];
    final done = Completer<void>();
    final originalStack = StackTrace.current;

    expect(stream.isBroadcast, isTrue);

    final subscription = stream.listen(
      values.add,
      onError: (Object error, StackTrace stackTrace) {
        errors.add(error);
        errorStacks.add(stackTrace);
      },
      onDone: done.complete,
    );
    source
      ..add(7)
      ..addError(
        AnyhowException('stream failed\nprivate context'),
        originalStack,
      );
    await source.close();
    await done.future;
    await subscription.cancel();

    expect(values, [7]);
    expect(errors, hasLength(1));
    expect(errors.single, isA<XelisWalletOperationException>());
    final exception = errors.single as XelisWalletOperationException;
    expect(exception.operation, XelisWalletOperation.loggingStream);
    expect(exception.diagnosticMessage, 'stream failed\nprivate context');
    expect(errorStacks.single.toString(), originalStack.toString());
    expect(wasCancelled, isTrue);
  });
}
