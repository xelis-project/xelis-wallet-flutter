import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/api/errors/xelis_wallet_exception.dart';
import 'package:xelis_wallet_flutter/src/api/logging/log_entry.dart';
import 'package:xelis_wallet_flutter/src/api/progress/progress_report.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/runtime_event_adapters.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/logger.dart'
    as generated_logger;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/progress_report.dart'
    as generated_progress;

void main() {
  test('maps every generated log level to the authored model', () {
    const expectedLevels = <generated_logger.Level, XelisLogLevel>{
      generated_logger.Level.error: XelisLogLevel.error,
      generated_logger.Level.warn: XelisLogLevel.warn,
      generated_logger.Level.info: XelisLogLevel.info,
      generated_logger.Level.debug: XelisLogLevel.debug,
      generated_logger.Level.trace: XelisLogLevel.trace,
    };

    for (final MapEntry(key: generatedLevel, value: expectedLevel)
        in expectedLevels.entries) {
      final entry = adaptLogEntry(
        generated_logger.NativeLogEntry(
          level: generatedLevel,
          target: 'xelis_wallet::storage',
          message: 'message',
        ),
      );

      expect(
        entry,
        XelisLogEntry(
          level: expectedLevel,
          source: XelisLogSource.xelisWallet,
          target: 'xelis_wallet::storage',
          message: 'message',
        ),
      );
    }
  });

  test('classifies native log provenance without parsing messages', () {
    const expectedSources = <String, XelisLogSource>{
      'xelis_wallet_flutter::api::wallet': XelisLogSource.xelisWalletFlutter,
      'xelis_wallet::storage': XelisLogSource.xelisWallet,
      'xelis_common::rpc': XelisLogSource.xelisCommon,
      'flutter_rust_bridge::handler': XelisLogSource.flutterRustBridge,
      'tokio_tungstenite::client': XelisLogSource.dependency,
    };

    for (final MapEntry(key: target, value: expectedSource)
        in expectedSources.entries) {
      expect(classifyLogSource(target), expectedSource, reason: target);
    }
  });

  test('maps every progress field to the authored model', () {
    final report = adaptProgressReport(
      const generated_progress.ProgressReport(
        progress: 0.75,
        step: 'precomputed_tables',
        message: 'Downloading',
      ),
    );

    expect(
      report,
      const ProgressReport(
        progress: 0.75,
        step: 'precomputed_tables',
        message: 'Downloading',
      ),
    );
  });

  test('preserves log stream values, errors, and completion', () async {
    final source = StreamController<generated_logger.NativeLogEntry>();
    final error = StateError('native stream error');
    final values = <XelisLogEntry>[];
    final errors = <Object>[];
    final done = Completer<void>();

    adaptLogStream(
      () => source.stream,
    ).listen(values.add, onError: errors.add, onDone: done.complete);

    source
      ..add(
        const generated_logger.NativeLogEntry(
          level: generated_logger.Level.info,
          target: 'xelis_wallet',
          message: 'ready',
        ),
      )
      ..addError(error);
    await source.close();
    await done.future;

    expect(values, const [
      XelisLogEntry(
        level: XelisLogLevel.info,
        source: XelisLogSource.xelisWallet,
        target: 'xelis_wallet',
        message: 'ready',
      ),
    ]);
    expect(errors, [same(error)]);
  });

  test('maps native errors emitted by a runtime event stream', () async {
    final source = StreamController<generated_logger.NativeLogEntry>();
    final errors = <Object>[];
    final done = Completer<void>();

    adaptLogStream(
      () => source.stream,
    ).listen((_) {}, onError: errors.add, onDone: done.complete);

    source.addError(AnyhowException('logger failed\nprivate context'));
    await source.close();
    await done.future;

    expect(errors.single, isA<XelisWalletOperationException>());
    final exception = errors.single as XelisWalletOperationException;
    expect(exception.source, XelisWalletErrorSource.xelisWalletFlutter);
    expect(exception.operation, XelisWalletOperation.loggingStream);
    expect(exception.code, XelisWalletErrorCode.operationFailed);
    expect(exception.diagnosticMessage, 'logger failed\nprivate context');
    expect(exception.toString(), isNot(contains('private context')));
  });

  test('propagates cancellation to the generated progress stream', () async {
    var wasCancelled = false;
    final source = StreamController<generated_progress.ProgressReport>(
      onCancel: () {
        wasCancelled = true;
      },
    );

    final subscription = adaptProgressStream(
      () => source.stream,
    ).listen((_) {});
    await subscription.cancel();

    expect(wasCancelled, isTrue);
    await source.close();
  });
}
