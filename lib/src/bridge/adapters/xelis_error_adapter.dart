import 'dart:async';
import 'dart:math';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

import '../../api/errors/xelis_wallet_exception.dart';
import '../../generated/rust_bridge/api/error.dart' as generated_error;

/// Classification supplied by the authored API at an FFI boundary.
final class XelisErrorBoundary {
  const XelisErrorBoundary({required this.source, required this.operation});

  final XelisWalletErrorSource source;
  final XelisWalletOperation operation;
}

typedef XelisSupportIdFactory = String Function();

var _fallbackSupportIdCounter = 0;

/// Converts a bridge-owned exception into the stable authored error contract.
///
/// Unknown Dart exceptions and already-authored exceptions are returned by
/// identity. The caller is responsible for preserving the original stack.
Object adaptXelisError(
  Object error, {
  required XelisErrorBoundary boundary,
  XelisSupportIdFactory? supportIdFactory,
}) {
  if (error is XelisWalletException) {
    return error;
  }

  final createSupportId = supportIdFactory ?? _createSupportId;

  return switch (error) {
    generated_error.NativeXelisError() => _adaptNativeError(
      error,
      boundary,
      createSupportId(),
    ),
    AnyhowException(:final message) => XelisWalletOperationException(
      source: boundary.source,
      operation: boundary.operation,
      code: XelisWalletErrorCode.operationFailed,
      supportId: createSupportId(),
      diagnosticMessage: message,
    ),
    PanicException(:final message) => XelisWalletBridgeException(
      source: XelisWalletErrorSource.flutterRustBridge,
      operation: boundary.operation,
      code: XelisWalletErrorCode.nativePanic,
      supportId: createSupportId(),
      diagnosticMessage: message,
    ),
    PlatformMismatchException() => XelisWalletBridgeException(
      source: XelisWalletErrorSource.platform,
      operation: boundary.operation,
      code: XelisWalletErrorCode.unsupportedPlatform,
      supportId: createSupportId(),
      diagnosticMessage: error.toString(),
    ),
    FrbException() => XelisWalletBridgeException(
      source: XelisWalletErrorSource.flutterRustBridge,
      operation: boundary.operation,
      code: XelisWalletErrorCode.bridgeFailure,
      supportId: createSupportId(),
      diagnosticMessage: error.toString(),
    ),
    _ => error,
  };
}

T guardXelisCall<T>(
  T Function() operation, {
  required XelisErrorBoundary boundary,
}) {
  try {
    return operation();
  } catch (error, stackTrace) {
    _throwAdapted(error, stackTrace, boundary);
  }
}

Future<T> guardXelisFuture<T>(
  FutureOr<T> Function() operation, {
  required XelisErrorBoundary boundary,
}) async {
  try {
    return await operation();
  } catch (error, stackTrace) {
    _throwAdapted(error, stackTrace, boundary);
  }
}

Stream<T> guardXelisStream<T>(
  Stream<T> Function() createStream, {
  required XelisErrorBoundary boundary,
}) {
  final stream = guardXelisCall(createStream, boundary: boundary);
  return stream.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (Object error, StackTrace stackTrace, EventSink<T> sink) =>
          sink.addError(adaptXelisError(error, boundary: boundary), stackTrace),
    ),
  );
}

Never _throwAdapted(
  Object error,
  StackTrace stackTrace,
  XelisErrorBoundary boundary,
) {
  Error.throwWithStackTrace(
    adaptXelisError(error, boundary: boundary),
    stackTrace,
  );
}

/// Creates a safe stable exception for malformed data produced by the private
/// generated bridge contract itself.
XelisWalletBridgeException xelisBridgeContractException({
  required XelisWalletOperation operation,
  required String nativeKind,
  required String diagnosticMessage,
}) => XelisWalletBridgeException(
  source: XelisWalletErrorSource.flutterRustBridge,
  operation: operation,
  code: XelisWalletErrorCode.bridgeFailure,
  supportId: _createSupportId(),
  diagnosticMessage: diagnosticMessage,
  nativeKind: nativeKind,
);

/// Creates a stable operation failure for a package-owned precondition that
/// cannot be delegated to the native bridge.
///
/// This is intentionally kept in the private adapter layer so authored API
/// values do not gain constructors for support identifiers. The diagnostic
/// remains privileged while the generated XWF reference and stable fields are
/// safe for normal support logging.
XelisWalletOperationException xelisOperationPreconditionException({
  required XelisWalletOperation operation,
  required XelisWalletErrorCode code,
  required String nativeKind,
  required String diagnosticMessage,
}) => XelisWalletOperationException(
  source: XelisWalletErrorSource.xelisWalletFlutter,
  operation: operation,
  code: code,
  supportId: _createSupportId(),
  diagnosticMessage: diagnosticMessage,
  nativeKind: nativeKind,
);

String _createSupportId() {
  try {
    final random = Random.secure();
    final hex = List<int>.generate(10, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return _formatSupportId(hex);
  } catch (_) {
    // Support metadata must never hide the original native failure. The
    // timestamp/counter fallback is only used when secure randomness is not
    // available on the current platform.
    final timestamp = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(16, '0');
    final counter = (_fallbackSupportIdCounter++)
        .toRadixString(16)
        .padLeft(8, '0');
    final hex = '$timestamp$counter'.substring(4).toUpperCase();
    return _formatSupportId(hex);
  }
}

String _formatSupportId(String hex) =>
    'XWF-${hex.substring(0, 4)}-${hex.substring(4, 8)}-'
    '${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
    '${hex.substring(16, 20)}';

XelisWalletException _adaptNativeError(
  generated_error.NativeXelisError error,
  XelisErrorBoundary boundary,
  String supportId,
) {
  if (error.version != XelisWalletErrorContract.currentVersion) {
    return XelisWalletBridgeException(
      source: XelisWalletErrorSource.flutterRustBridge,
      operation: boundary.operation,
      code: XelisWalletErrorCode.bridgeFailure,
      supportId: supportId,
      diagnosticMessage:
          'Unsupported native error contract version ${error.version}.\n'
          '${error.diagnosticMessage}',
      nativeKind: 'NATIVE_ERROR_CONTRACT_VERSION_${error.version}',
    );
  }

  return XelisWalletOperationException(
    source: _adaptNativeSource(error.source),
    operation: boundary.operation,
    code: _adaptNativeCode(error.code),
    supportId: supportId,
    diagnosticMessage: error.diagnosticMessage,
    nativeKind: error.nativeKind,
    nativeCode: error.nativeCode,
  );
}

XelisWalletErrorSource _adaptNativeSource(
  generated_error.NativeXelisErrorSource source,
) => switch (source) {
  generated_error.NativeXelisErrorSource.xelisWalletFlutter =>
    XelisWalletErrorSource.xelisWalletFlutter,
  generated_error.NativeXelisErrorSource.xelisWallet =>
    XelisWalletErrorSource.xelisWallet,
  generated_error.NativeXelisErrorSource.xelisCommon =>
    XelisWalletErrorSource.xelisCommon,
  generated_error.NativeXelisErrorSource.dependency =>
    XelisWalletErrorSource.dependency,
  generated_error.NativeXelisErrorSource.unknown =>
    XelisWalletErrorSource.unknown,
};

XelisWalletErrorCode _adaptNativeCode(
  generated_error.NativeXelisErrorCode code,
) => switch (code) {
  generated_error.NativeXelisErrorCode.invalidInput =>
    XelisWalletErrorCode.invalidInput,
  generated_error.NativeXelisErrorCode.operationFailed =>
    XelisWalletErrorCode.operationFailed,
  generated_error.NativeXelisErrorCode.offline => XelisWalletErrorCode.offline,
  generated_error.NativeXelisErrorCode.network =>
    XelisWalletErrorCode.networkFailure,
  generated_error.NativeXelisErrorCode.remoteRejected =>
    XelisWalletErrorCode.daemonRejected,
  generated_error.NativeXelisErrorCode.insufficientFunds =>
    XelisWalletErrorCode.insufficientFunds,
  generated_error.NativeXelisErrorCode.conflict =>
    XelisWalletErrorCode.conflict,
  generated_error.NativeXelisErrorCode.notFound =>
    XelisWalletErrorCode.notFound,
  generated_error.NativeXelisErrorCode.unsupported =>
    XelisWalletErrorCode.unsupported,
  generated_error.NativeXelisErrorCode.storage =>
    XelisWalletErrorCode.storageFailure,
  generated_error.NativeXelisErrorCode.serialization =>
    XelisWalletErrorCode.serializationFailure,
  generated_error.NativeXelisErrorCode.initialization =>
    XelisWalletErrorCode.initializationFailure,
  generated_error.NativeXelisErrorCode.internal =>
    XelisWalletErrorCode.internal,
  generated_error.NativeXelisErrorCode.authenticationOrCorruptData =>
    XelisWalletErrorCode.authenticationOrCorruptData,
  generated_error.NativeXelisErrorCode.networkMismatch =>
    XelisWalletErrorCode.networkMismatch,
  generated_error.NativeXelisErrorCode.cancelled =>
    XelisWalletErrorCode.cancelled,
  generated_error.NativeXelisErrorCode.operationInProgress =>
    XelisWalletErrorCode.operationInProgress,
  generated_error.NativeXelisErrorCode.streamLagged =>
    XelisWalletErrorCode.streamLagged,
  generated_error.NativeXelisErrorCode.streamClosedUnexpectedly =>
    XelisWalletErrorCode.streamClosedUnexpectedly,
};
