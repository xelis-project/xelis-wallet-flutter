import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/tooling/consumer_smoke.dart';

void main() {
  group('parseConsumerSmokeArguments', () {
    test('accepts a desktop run with keep', () {
      final result = parseConsumerSmokeArguments(const [
        '--platform',
        'windows',
        '--mode',
        'run',
        '--keep',
      ]);

      expect(result, isA<ConsumerSmokeExecutionArguments>());
      final execution = result as ConsumerSmokeExecutionArguments;
      expect(execution.platform, ConsumerSmokePlatform.windows);
      expect(execution.mode, ConsumerSmokeMode.run);
      expect(execution.keep, isTrue);
    });

    test('accepts mobile build mode', () {
      final result = parseConsumerSmokeArguments(const [
        '--mode',
        'build',
        '--platform',
        'android',
      ]);

      final execution = result as ConsumerSmokeExecutionArguments;
      expect(execution.platform, ConsumerSmokePlatform.android);
      expect(execution.mode, ConsumerSmokeMode.build);
      expect(execution.keep, isFalse);
    });

    test('accepts a Web browser run', () {
      final result = parseConsumerSmokeArguments(const [
        '--platform',
        'web',
        '--mode',
        'run',
      ]);

      final execution = result as ConsumerSmokeExecutionArguments;
      expect(execution.platform, ConsumerSmokePlatform.web);
      expect(execution.mode, ConsumerSmokeMode.run);
      expect(execution.keep, isFalse);
    });

    test('accepts help', () {
      expect(
        parseConsumerSmokeArguments(const ['--help']),
        isA<ConsumerSmokeHelpArguments>(),
      );
    });

    test('rejects mobile run and malformed arguments', () {
      for (final arguments in <List<String>>[
        const [],
        const ['--platform', 'linux'],
        const ['--platform', 'android', '--mode', 'run'],
        const ['--platform', 'unknown', '--mode', 'build'],
        const ['--platform', 'linux', '--mode', 'build', '--unknown'],
      ]) {
        expect(
          () => parseConsumerSmokeArguments(arguments),
          throwsA(isA<FormatException>()),
          reason: 'arguments: $arguments',
        );
      }
    });
  });

  test('creates platform-specific run and build commands', () {
    final consumerDirectory = Directory('consumer').absolute;

    expect(
      createConsumerActionCommand(
        platform: ConsumerSmokePlatform.linux,
        mode: ConsumerSmokeMode.run,
        consumerDirectory: consumerDirectory,
      ).arguments,
      [
        'test',
        'integration_test/native_library_smoke_test.dart',
        '-d',
        'linux',
      ],
    );
    expect(
      createConsumerActionCommand(
        platform: ConsumerSmokePlatform.android,
        mode: ConsumerSmokeMode.build,
        consumerDirectory: consumerDirectory,
      ).arguments,
      ['build', 'apk', '--release'],
    );
    expect(
      createConsumerActionCommand(
        platform: ConsumerSmokePlatform.ios,
        mode: ConsumerSmokeMode.build,
        consumerDirectory: consumerDirectory,
      ).arguments,
      ['build', 'ios', '--release', '--no-codesign'],
    );
    expect(
      createConsumerActionCommand(
        platform: ConsumerSmokePlatform.web,
        mode: ConsumerSmokeMode.run,
        consumerDirectory: consumerDirectory,
      ).arguments,
      ['build', 'web', '--release'],
    );
    expect(
      createWebPackageBuildCommand(consumerDirectory: consumerDirectory)
          .arguments,
      ['run', 'xelis_wallet_flutter:build_web', '--output', 'web/pkg'],
    );
    expect(
      createWebBrowserSmokeCommand(consumerDirectory: consumerDirectory)
          .arguments,
      ['run', 'tool/web_smoke_runner.dart'],
    );
  });

  test(
    'writes an isolated consumer with the local package dependency',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'xwf_consumer_smoke_files_test_',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final consumer = Directory.fromUri(workspace.uri.resolve('consumer/'));
      await consumer.create(recursive: true);

      await writeConsumerSmokeProjectFiles(
        consumerDirectory: consumer,
        packageRoot: Directory.current,
        platform: ConsumerSmokePlatform.windows,
      );

      final pubspec = await File.fromUri(consumer.uri.resolve('pubspec.yaml'))
          .readAsString();
      final main = await File.fromUri(consumer.uri.resolve('lib/main.dart'))
          .readAsString();
      final integrationTest = await File.fromUri(
        consumer.uri.resolve('integration_test/native_library_smoke_test.dart'),
      ).readAsString();

      expect(pubspec, contains('xelis_wallet_flutter:'));
      expect(
        pubspec,
        contains(Directory.current.absolute.path.replaceAll('\\', '/')),
      );
      expect(main, contains('XelisWalletFlutter.initialize()'));
      expect(main, contains('isAddressValid'));
      expect(main, contains("Text('XWF_NATIVE_CONSUMER_SMOKE_PASS')"));
      expect(
        main.indexOf('await runNativeSmoke();'),
        lessThan(main.indexOf("debugPrint('XWF_NATIVE_CONSUMER_SMOKE_PASS')")),
      );
      expect(integrationTest, contains('runNativeSmoke()'));
    },
  );

  test(
    'writes a Web consumer that exercises Rust integer round trips',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'xwf_web_consumer_smoke_files_test_',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final consumer = Directory.fromUri(workspace.uri.resolve('consumer/'));
      await consumer.create(recursive: true);

      await writeConsumerSmokeProjectFiles(
        consumerDirectory: consumer,
        packageRoot: Directory.current,
        platform: ConsumerSmokePlatform.web,
      );

      final main = await File.fromUri(consumer.uri.resolve('lib/main.dart'))
          .readAsString();
      final index = await File.fromUri(consumer.uri.resolve('web/index.html'))
          .readAsString();
      final runner = await File.fromUri(
        consumer.uri.resolve('tool/web_smoke_runner.dart'),
      ).readAsString();

      expect(main, contains('XelisWalletFlutter.initialize()'));
      expect(main, contains('XelisWalletFlutter.makeIntegratedAddress'));
      expect(main, contains('9007199254740993'));
      expect(main, contains('18446744073709551615'));
      final verification = main.indexOf('await runWebAddressIntegerSmoke();');
      final success = main.indexOf(r'_reportResult(_successMarker.toJS);');
      expect(verification, greaterThanOrEqualTo(0));
      expect(success, greaterThan(verification));
      expect(index, contains('xwfReportResult'));
      expect(runner, contains('Cross-Origin-Opener-Policy'));
      expect(runner, contains('Cross-Origin-Embedder-Policy'));
      expect(runner, contains('XWF_WEB_CONSUMER_SMOKE_PASS'));
      expect(runner, contains('initialization=true'));
      expect(runner, contains('address_round_trip=true'));
      expect(
        runner,
        contains('above_javascript_safe_integer=9007199254740993'),
      );
      expect(runner, contains('maximum_u64=18446744073709551615'));
    },
  );

  test(
    'recognizes only direct owned children of the system temp directory',
    () {
      final tempDirectory = Directory.systemTemp.absolute;
      final owned = Directory.fromUri(
        tempDirectory.uri.resolve('xelis_wallet_flutter_consumer_smoke_123/'),
      );
      final nested = Directory.fromUri(owned.uri.resolve('nested/'));

      expect(
        isOwnedConsumerSmokeWorkspace(
          workspace: owned,
          systemTempDirectory: tempDirectory,
        ),
        isTrue,
      );
      expect(
        isOwnedConsumerSmokeWorkspace(
          workspace: nested,
          systemTempDirectory: tempDirectory,
        ),
        isFalse,
      );
      expect(
        isOwnedConsumerSmokeWorkspace(
          workspace: Directory.current,
          systemTempDirectory: tempDirectory,
        ),
        isFalse,
      );
    },
  );

  test('runs commands in order and removes its generated workspace', () async {
    final tempParent = await Directory.systemTemp.createTemp(
      'xwf_consumer_smoke_parent_test_',
    );
    addTearDown(() async {
      if (await tempParent.exists()) {
        await tempParent.delete(recursive: true);
      }
    });
    final commands = <ConsumerSmokeCommand>[];

    final result = await runConsumerSmoke(
      arguments: const ConsumerSmokeExecutionArguments(
        platform: ConsumerSmokePlatform.windows,
        mode: ConsumerSmokeMode.build,
        keep: false,
      ),
      packageRoot: Directory.current,
      systemTempDirectory: tempParent,
      processRunner: (command) async {
        commands.add(command);
        if (command.arguments.first == 'create') {
          await Directory(command.arguments.last).create(recursive: true);
        }
        return 0;
      },
    );

    expect(result, 0);
    expect(commands, hasLength(3));
    expect(commands[0].arguments.first, 'create');
    expect(commands[1].arguments, ['pub', 'get']);
    expect(commands[2].arguments, ['build', 'windows', '--release']);
    expect(await tempParent.list().toList(), isEmpty);
  });

  test('builds and runs the generated Web consumer in order', () async {
    final tempParent = await Directory.systemTemp.createTemp(
      'xwf_web_consumer_smoke_parent_test_',
    );
    addTearDown(() async {
      if (await tempParent.exists()) {
        await tempParent.delete(recursive: true);
      }
    });
    final commands = <ConsumerSmokeCommand>[];

    final result = await runConsumerSmoke(
      arguments: const ConsumerSmokeExecutionArguments(
        platform: ConsumerSmokePlatform.web,
        mode: ConsumerSmokeMode.run,
        keep: false,
      ),
      packageRoot: Directory.current,
      systemTempDirectory: tempParent,
      processRunner: (command) async {
        commands.add(command);
        if (command.arguments.first == 'create') {
          await Directory(command.arguments.last).create(recursive: true);
        }
        return 0;
      },
    );

    expect(result, 0);
    expect(commands, hasLength(5));
    expect(commands[0].arguments.first, 'create');
    expect(commands[1].arguments, ['pub', 'get']);
    expect(commands[2].arguments, [
      'run',
      'xelis_wallet_flutter:build_web',
      '--output',
      'web/pkg',
    ]);
    expect(commands[3].arguments, ['build', 'web', '--release']);
    expect(commands[4].arguments, ['run', 'tool/web_smoke_runner.dart']);
    expect(await tempParent.list().toList(), isEmpty);
  });

  for (final failingStep in [3, 4, 5]) {
    test('stops the Web chain after failed step $failingStep', () async {
      final tempParent = await Directory.systemTemp.createTemp(
        'xwf_web_consumer_failure_test_',
      );
      addTearDown(() => tempParent.delete(recursive: true));
      var calls = 0;

      final result = await runConsumerSmoke(
        arguments: const ConsumerSmokeExecutionArguments(
          platform: ConsumerSmokePlatform.web,
          mode: ConsumerSmokeMode.run,
          keep: false,
        ),
        packageRoot: Directory.current,
        systemTempDirectory: tempParent,
        processRunner: (command) async {
          calls++;
          if (command.arguments.first == 'create') {
            await Directory(command.arguments.last).create(recursive: true);
          }
          return calls == failingStep ? 23 : 0;
        },
      );

      expect(result, 23);
      expect(calls, failingStep);
      expect(await tempParent.list().toList(), isEmpty);
    });
  }
}
