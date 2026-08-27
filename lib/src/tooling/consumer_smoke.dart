import 'dart:io';

const consumerSmokeUsage =
    'Usage: dart --packages=.dart_tool/package_config.json '
    'tool/consumer_smoke.dart '
    '--platform <linux|windows|macos|android|ios> '
    '--mode <run|build> [--keep]';

const consumerSmokeHelp =
    '''
$consumerSmokeUsage

Generate an isolated Flutter consumer in the system temporary directory.

The run mode loads and calls the native library on a desktop target. The build
mode creates a release application for any supported native target. By default,
the generated workspace is deleted after the command completes.
''';

const _workspacePrefix = 'xelis_wallet_flutter_consumer_smoke_';

enum ConsumerSmokePlatform {
  linux,
  windows,
  macos,
  android,
  ios;

  bool get supportsRun => switch (this) {
    linux || windows || macos => true,
    android || ios => false,
  };
}

enum ConsumerSmokeMode { run, build }

sealed class ConsumerSmokeArguments {
  const ConsumerSmokeArguments();
}

final class ConsumerSmokeHelpArguments extends ConsumerSmokeArguments {
  const ConsumerSmokeHelpArguments();
}

final class ConsumerSmokeExecutionArguments extends ConsumerSmokeArguments {
  const ConsumerSmokeExecutionArguments({
    required this.platform,
    required this.mode,
    required this.keep,
  });

  final ConsumerSmokePlatform platform;
  final ConsumerSmokeMode mode;
  final bool keep;
}

ConsumerSmokeArguments parseConsumerSmokeArguments(List<String> arguments) {
  if (arguments case ['--help']) {
    return const ConsumerSmokeHelpArguments();
  }

  String? platformValue;
  String? modeValue;
  var keep = false;

  for (var index = 0; index < arguments.length; index++) {
    switch (arguments[index]) {
      case '--platform':
        if (platformValue != null || index + 1 >= arguments.length) {
          throw const FormatException(
            'Expected exactly one value after --platform.',
          );
        }
        platformValue = arguments[++index];
      case '--mode':
        if (modeValue != null || index + 1 >= arguments.length) {
          throw const FormatException(
            'Expected exactly one value after --mode.',
          );
        }
        modeValue = arguments[++index];
      case '--keep':
        if (keep) {
          throw const FormatException('--keep may be specified only once.');
        }
        keep = true;
      default:
        throw FormatException('Unknown argument: ${arguments[index]}');
    }
  }

  final platform = ConsumerSmokePlatform.values
      .where((value) => value.name == platformValue)
      .firstOrNull;
  if (platform == null) {
    throw const FormatException(
      'Expected --platform <linux|windows|macos|android|ios>.',
    );
  }

  final mode = ConsumerSmokeMode.values
      .where((value) => value.name == modeValue)
      .firstOrNull;
  if (mode == null) {
    throw const FormatException('Expected --mode <run|build>.');
  }
  if (mode == ConsumerSmokeMode.run && !platform.supportsRun) {
    throw FormatException(
      'The run mode is supported only on desktop targets, not '
      '${platform.name}.',
    );
  }

  return ConsumerSmokeExecutionArguments(
    platform: platform,
    mode: mode,
    keep: keep,
  );
}

final class ConsumerSmokeCommand {
  const ConsumerSmokeCommand({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final Directory workingDirectory;
}

typedef ConsumerSmokeProcessRunner = Future<int> Function(
  ConsumerSmokeCommand command,
);

ConsumerSmokeCommand createConsumerProjectCommand({
  required ConsumerSmokePlatform platform,
  required Directory workspace,
}) {
  final consumerDirectory = Directory.fromUri(
    workspace.uri.resolve('consumer/'),
  );
  return ConsumerSmokeCommand(
    executable: 'flutter',
    arguments: [
      'create',
      '--empty',
      '--platforms=${platform.name}',
      '--project-name=xwf_consumer_smoke',
      consumerDirectory.path,
    ],
    workingDirectory: workspace,
  );
}

ConsumerSmokeCommand createConsumerActionCommand({
  required ConsumerSmokePlatform platform,
  required ConsumerSmokeMode mode,
  required Directory consumerDirectory,
}) {
  if (mode == ConsumerSmokeMode.run) {
    if (!platform.supportsRun) {
      throw ArgumentError.value(
        platform,
        'platform',
        'The run mode requires a desktop target.',
      );
    }
    return ConsumerSmokeCommand(
      executable: 'flutter',
      arguments: [
        'test',
        'integration_test/native_library_smoke_test.dart',
        '-d',
        platform.name,
      ],
      workingDirectory: consumerDirectory,
    );
  }

  return ConsumerSmokeCommand(
    executable: 'flutter',
    arguments: switch (platform) {
      ConsumerSmokePlatform.android => ['build', 'apk', '--release'],
      ConsumerSmokePlatform.ios => [
        'build',
        'ios',
        '--release',
        '--no-codesign',
      ],
      _ => ['build', platform.name, '--release'],
    },
    workingDirectory: consumerDirectory,
  );
}

Future<void> writeConsumerSmokeProjectFiles({
  required Directory consumerDirectory,
  required Directory packageRoot,
}) async {
  final packagePath = packageRoot.absolute.path
      .replaceAll('\\', '/')
      .replaceAll("'", "''");

  await File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml'))
      .writeAsString('''
name: xwf_consumer_smoke
description: Ephemeral native loading consumer for xelis_wallet_flutter.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  xelis_wallet_flutter:
    path: '$packagePath'

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: false
''');

  final libDirectory = Directory.fromUri(consumerDirectory.uri.resolve('lib/'));
  final integrationTestDirectory = Directory.fromUri(
    consumerDirectory.uri.resolve('integration_test/'),
  );
  await libDirectory.create(recursive: true);
  await integrationTestDirectory.create(recursive: true);

  await File.fromUri(libDirectory.uri.resolve('main.dart')).writeAsString('''
import 'package:flutter/widgets.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

Future<void> runNativeSmoke() async {
  await XelisWalletFlutter.initialize();
  if (!XelisWalletFlutter.isInitialized) {
    throw StateError('The native bridge did not report successful startup.');
  }

  final valid = XelisWalletFlutter.isAddressValid(
    address: 'not-a-xelis-address',
    network: XelisNetwork.mainnet,
  );
  if (valid) {
    throw StateError('The native address validator accepted invalid input.');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runNativeSmoke();
  runApp(const SizedBox.shrink());
}
''');

  await File.fromUri(
    integrationTestDirectory.uri.resolve('native_library_smoke_test.dart'),
  ).writeAsString('''
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xwf_consumer_smoke/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads and calls the Rust library', (tester) async {
    await runNativeSmoke();
  });
}
''');
}

bool isOwnedConsumerSmokeWorkspace({
  required Directory workspace,
  required Directory systemTempDirectory,
}) {
  String normalized(String path) {
    final result = Directory(path).absolute.path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/+$'), '');
    return Platform.isWindows ? result.toLowerCase() : result;
  }

  return normalized(workspace.parent.path) ==
          normalized(systemTempDirectory.path) &&
      workspace.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last
          .startsWith(_workspacePrefix);
}

Future<int> runConsumerSmoke({
  required ConsumerSmokeExecutionArguments arguments,
  required Directory packageRoot,
  Directory? systemTempDirectory,
  ConsumerSmokeProcessRunner processRunner = runConsumerSmokeCommand,
  IOSink? outputSink,
  IOSink? errorSink,
}) async {
  final tempDirectory = (systemTempDirectory ?? Directory.systemTemp).absolute;
  final workspace = await tempDirectory.createTemp(_workspacePrefix);
  final consumerDirectory = Directory.fromUri(
    workspace.uri.resolve('consumer/'),
  );
  final out = outputSink ?? stdout;
  final errors = errorSink ?? stderr;

  out
    ..writeln('Consumer smoke workspace: ${workspace.path}')
    ..writeln('CONSUMER_SMOKE_WORKSPACE=${workspace.path}');

  try {
    final createExitCode = await processRunner(
      createConsumerProjectCommand(
        platform: arguments.platform,
        workspace: workspace,
      ),
    );
    if (createExitCode != 0) {
      return createExitCode;
    }

    await writeConsumerSmokeProjectFiles(
      consumerDirectory: consumerDirectory,
      packageRoot: packageRoot,
    );

    final pubGetExitCode = await processRunner(
      ConsumerSmokeCommand(
        executable: 'flutter',
        arguments: const ['pub', 'get'],
        workingDirectory: consumerDirectory,
      ),
    );
    if (pubGetExitCode != 0) {
      return pubGetExitCode;
    }

    return await processRunner(
      createConsumerActionCommand(
        platform: arguments.platform,
        mode: arguments.mode,
        consumerDirectory: consumerDirectory,
      ),
    );
  } on FileSystemException catch (error) {
    errors.writeln('Could not prepare the consumer smoke project: $error');
    return 74;
  } on ProcessException catch (error) {
    errors.writeln('Could not start the consumer smoke command: $error');
    return 127;
  } finally {
    if (arguments.keep) {
      out.writeln('Keeping consumer smoke workspace: ${workspace.path}');
    } else if (isOwnedConsumerSmokeWorkspace(
      workspace: workspace,
      systemTempDirectory: tempDirectory,
    )) {
      try {
        await workspace.delete(recursive: true);
      } on FileSystemException catch (error) {
        errors.writeln(
          'Could not delete consumer smoke workspace ${workspace.path}: $error',
        );
      }
    } else {
      errors.writeln(
        'Refusing to delete an unrecognized consumer smoke workspace: '
        '${workspace.path}',
      );
    }
  }
}

Future<int> runConsumerSmokeCommand(ConsumerSmokeCommand command) async {
  final process = await Process.start(
    command.executable,
    command.arguments,
    workingDirectory: command.workingDirectory.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  return process.exitCode;
}
