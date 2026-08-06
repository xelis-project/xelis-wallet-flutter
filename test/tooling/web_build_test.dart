import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/tooling/web_build.dart';

void main() {
  group('parseWebBuildArguments', () {
    test('accepts an explicit output directory', () {
      final result = parseWebBuildArguments(['--output', 'web/pkg']);

      expect(result, isA<WebBuildOutputArguments>());
      expect(
        (result as WebBuildOutputArguments).outputDirectory.path,
        Directory('web/pkg').absolute.path,
      );
    });

    test('accepts help', () {
      expect(parseWebBuildArguments(['--help']), isA<WebBuildHelpArguments>());
    });

    test('rejects missing, incomplete, and unknown arguments', () {
      for (final arguments in <List<String>>[
        [],
        ['--output'],
        ['--unknown'],
        ['--output', 'web/pkg', '--unknown'],
      ]) {
        expect(
          () => parseWebBuildArguments(arguments),
          throwsA(isA<FormatException>()),
          reason: 'arguments: $arguments',
        );
      }
    });

    test('uses the development wrapper default when provided', () {
      final defaultOutput = Directory('web/pkg');

      final result = parseWebBuildArguments(
        const [],
        defaultOutputDirectory: defaultOutput,
      );

      expect(
        (result as WebBuildOutputArguments).outputDirectory.path,
        defaultOutput.absolute.path,
      );
    });
  });

  test('creates the expected wasm-pack command and environment', () {
    final packageRoot = Directory.current;
    final outputDirectory = Directory('consumer/web/pkg').absolute;

    final command = createWebBuildCommand(
      packageRoot: packageRoot,
      outputDirectory: outputDirectory,
      environment: const {
        'PRESERVED': 'value',
        'RUSTUP_TOOLCHAIN': 'stable',
        'RUSTFLAGS': 'old flags',
      },
    );

    expect(command.executable, 'wasm-pack');
    expect(command.arguments, [
      'build',
      '-t',
      'no-modules',
      '-d',
      outputDirectory.path,
      '--no-typescript',
      '--weak-refs',
      Directory.fromUri(packageRoot.uri.resolve('rust/')).path,
      '--',
      '-Z',
      'build-std=std,panic_abort',
      '--no-default-features',
      '--features',
      'network_handler,xswd',
    ]);
    expect(command.environment['PRESERVED'], 'value');
    expect(command.environment['RUSTUP_TOOLCHAIN'], 'nightly');
    expect(
      command.environment['RUSTFLAGS'],
      [
        '-C target-feature=+atomics,+bulk-memory,+mutable-globals',
        '-C link-arg=--export=__heap_base',
        '-C link-arg=--export=__wasm_init_tls',
        '-C link-arg=--export=__tls_base',
        '-C link-arg=--export=__tls_size',
        '-C link-arg=--export=__tls_align',
        '-C link-arg=--shared-memory',
        '-C link-arg=--import-memory',
        '-C link-arg=--max-memory=2147483648',
      ].join(' '),
    );
  });
}
