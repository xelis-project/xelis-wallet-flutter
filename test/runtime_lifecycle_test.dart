import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/runtime/runtime_lifecycle.dart';

void main() {
  test('initializes the runtime only once', () async {
    var initializationCount = 0;
    final lifecycle = RuntimeLifecycle(
      initializeRuntime: () async {
        initializationCount++;
      },
    );

    await lifecycle.initialize();
    await lifecycle.initialize();

    expect(initializationCount, 1);
    expect(lifecycle.isInitialized, isTrue);
  });

  test('shares an initialization between concurrent callers', () async {
    var initializationCount = 0;
    final initializationCompleter = Completer<void>();
    final lifecycle = RuntimeLifecycle(
      initializeRuntime: () {
        initializationCount++;
        return initializationCompleter.future;
      },
    );

    final first = lifecycle.initialize();
    final second = lifecycle.initialize();

    expect(identical(first, second), isTrue);
    expect(initializationCount, 1);
    expect(lifecycle.isInitialized, isFalse);

    initializationCompleter.complete();
    await Future.wait([first, second]);

    expect(lifecycle.isInitialized, isTrue);
  });

  test('allows a retry after initialization fails', () async {
    var initializationCount = 0;
    final lifecycle = RuntimeLifecycle(
      initializeRuntime: () {
        initializationCount++;
        if (initializationCount == 1) {
          throw StateError('initialization failed');
        }
        return Future<void>.value();
      },
    );

    await expectLater(lifecycle.initialize(), throwsStateError);
    expect(lifecycle.isInitialized, isFalse);

    await lifecycle.initialize();

    expect(initializationCount, 2);
    expect(lifecycle.isInitialized, isTrue);
  });

  test(
    'shares equal configured initialization between concurrent callers',
    () async {
      var initializationCount = 0;
      final initializationCompleter = Completer<void>();
      final lifecycle = ConfiguredRuntimeLifecycle<(String, bool)>(
        initializeRuntime: (configuration) {
          initializationCount++;
          return initializationCompleter.future;
        },
      );

      final first = lifecycle.initialize(('info', false));
      final second = lifecycle.initialize(('info', false));

      expect(identical(first, second), isTrue);
      expect(initializationCount, 1);

      initializationCompleter.complete();
      await Future.wait([first, second]);

      expect(lifecycle.isInitialized, isTrue);
    },
  );

  test('rejects a conflicting configured initialization', () async {
    final initializationCompleter = Completer<void>();
    final lifecycle = ConfiguredRuntimeLifecycle<(String, bool)>(
      initializeRuntime: (_) => initializationCompleter.future,
    );

    final first = lifecycle.initialize(('info', false));
    await expectLater(lifecycle.initialize(('debug', true)), throwsStateError);

    initializationCompleter.complete();
    await first;

    await expectLater(lifecycle.initialize(('debug', true)), throwsStateError);
  });

  test('allows a configured retry after initialization fails', () async {
    var initializationCount = 0;
    final lifecycle = ConfiguredRuntimeLifecycle<(String, bool)>(
      initializeRuntime: (_) {
        initializationCount++;
        if (initializationCount == 1) {
          throw StateError('initialization failed');
        }
        return Future<void>.value();
      },
    );

    await expectLater(lifecycle.initialize(('info', false)), throwsStateError);
    await lifecycle.initialize(('info', false));

    expect(initializationCount, 2);
    expect(lifecycle.isInitialized, isTrue);
  });
}
