import 'dart:async';

import '../../api/logging/log_entry.dart';
import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/progress/progress_report.dart';
import '../../generated/rust_bridge/api/logger.dart' as generated_logger;
import '../../generated/rust_bridge/api/progress_report.dart'
    as generated_progress;
import 'xelis_error_adapter.dart';

XelisLogEntry adaptLogEntry(generated_logger.NativeLogEntry entry) =>
    XelisLogEntry(
      level: switch (entry.level) {
        generated_logger.Level.error => XelisLogLevel.error,
        generated_logger.Level.warn => XelisLogLevel.warn,
        generated_logger.Level.info => XelisLogLevel.info,
        generated_logger.Level.debug => XelisLogLevel.debug,
        generated_logger.Level.trace => XelisLogLevel.trace,
      },
      source: classifyLogSource(entry.target),
      target: entry.target,
      message: entry.message,
    );

generated_logger.Level adaptLogLevel(XelisLogLevel level) => switch (level) {
  XelisLogLevel.error => generated_logger.Level.error,
  XelisLogLevel.warn => generated_logger.Level.warn,
  XelisLogLevel.info => generated_logger.Level.info,
  XelisLogLevel.debug => generated_logger.Level.debug,
  XelisLogLevel.trace => generated_logger.Level.trace,
};

XelisLogSource classifyLogSource(String target) {
  if (target == 'xelis_wallet_flutter' ||
      target.startsWith('xelis_wallet_flutter::')) {
    return XelisLogSource.xelisWalletFlutter;
  }
  if (target == 'xelis_wallet' || target.startsWith('xelis_wallet::')) {
    return XelisLogSource.xelisWallet;
  }
  if (target == 'xelis_common' || target.startsWith('xelis_common::')) {
    return XelisLogSource.xelisCommon;
  }
  if (target == 'flutter_rust_bridge' ||
      target.startsWith('flutter_rust_bridge::')) {
    return XelisLogSource.flutterRustBridge;
  }
  return XelisLogSource.dependency;
}

ProgressReport adaptProgressReport(generated_progress.ProgressReport report) =>
    ProgressReport(
      progress: report.progress,
      step: report.step,
      message: report.message,
    );

Stream<XelisLogEntry> adaptLogStream(
  Stream<generated_logger.NativeLogEntry> Function() createStream,
) => _detachGlobalSinkCancellation(
  guardXelisStream(
    createStream,
    boundary: const XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisWalletFlutter,
      operation: XelisWalletOperation.loggingStream,
    ),
  ),
).map(adaptLogEntry);

Stream<ProgressReport> adaptProgressStream(
  Stream<generated_progress.ProgressReport> Function() createStream,
) => _detachGlobalSinkCancellation(
  guardXelisStream(
    createStream,
    boundary: const XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisWalletFlutter,
      operation: XelisWalletOperation.progressStream,
    ),
  ),
).map(adaptProgressReport);

/// Starts cancellation of a replace-only process-global FRB sink without
/// waiting for its receive-port future.
///
/// FRB 2.13 can leave that future pending on Web after the Dart listener has
/// detached. Awaiting it would make a consumer's `StreamSubscription.cancel`
/// hang indefinitely even though creating a later stream replaces the native
/// sink. Wallet event subscriptions do not use this adapter: their explicit
/// native cancellation and disposal ordering remains fully awaited.
Stream<T> _detachGlobalSinkCancellation<T>(Stream<T> source) {
  late final StreamController<T> controller;
  late final StreamSubscription<T> subscription;
  controller = StreamController<T>(
    sync: true,
    onListen: () {
      subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    },
    onPause: () => subscription.pause(),
    onResume: () => subscription.resume(),
    onCancel: () => unawaited(subscription.cancel()),
  );
  return controller.stream;
}
