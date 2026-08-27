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
      expect(integrationTest, contains('runNativeSmoke()'));
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
}
