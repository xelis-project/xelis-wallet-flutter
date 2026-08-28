import 'dart:io';

const expectedVersion = '2.13.0';

Future<void> main() async {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() ||
      !pubspec.readAsStringSync().contains('name: xelis_wallet_flutter')) {
    stderr.writeln(
      'Run this command from the xelis_wallet_flutter repository root.',
    );
    exitCode = 1;
    return;
  }

  final versionResult = await Process.run('flutter_rust_bridge_codegen', const [
    '--version',
  ]);
  final versionOutput = '${versionResult.stdout}${versionResult.stderr}';

  if (versionResult.exitCode != 0 || !versionOutput.contains(expectedVersion)) {
    stderr.writeln(
      'flutter_rust_bridge_codegen $expectedVersion is required; '
      'received: ${versionOutput.trim()}',
    );
    exitCode = 1;
    return;
  }

  final dartOutput = Directory('lib/src/generated/rust_bridge');
  if (dartOutput.existsSync()) {
    await dartOutput.delete(recursive: true);
  }

  final rustOutput = File('rust/src/frb_generated.rs');
  if (rustOutput.existsSync()) {
    await rustOutput.delete();
  }

  final bridgeProcess = await Process.start(
    'flutter_rust_bridge_codegen',
    // Versions are pinned and checked above. Skipping the redundant tool-side
    // dependency probe also avoids recursively acquiring Flutter's batch lock
    // when this script itself runs through Dart's native build hooks.
    const ['generate', '--no-deps-check'],
    mode: ProcessStartMode.inheritStdio,
  );
  final bridgeExitCode = await bridgeProcess.exitCode;
  if (bridgeExitCode != 0) {
    exitCode = bridgeExitCode;
    return;
  }

  final buildRunnerProcess = await Process.start(
    Platform.resolvedExecutable,
    const ['run', 'build_runner', 'build'],
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await buildRunnerProcess.exitCode;
}
