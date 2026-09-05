import 'dart:io';

const nativeLibraryDirectoryVariable =
    'FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR';

/// Flutter builds the code assets before starting tests. FRB 2.13's dynamic
/// loader needs their directory explicitly on Linux; flutter_tester only adds
/// its native asset directory to the library search path on Windows.
Map<String, String> nativeTestEnvironment({
  required String operatingSystem,
  required Directory packageRoot,
  required Map<String, String> environment,
}) => {
  ...environment,
  if (operatingSystem == 'linux')
    nativeLibraryDirectoryVariable: Directory.fromUri(
      packageRoot.absolute.uri.resolve('build/native_assets/linux/'),
    ).path,
};

Future<void> main(List<String> arguments) async {
  final root = Directory.current;
  final manifest = File.fromUri(root.uri.resolve('pubspec.yaml'));
  if (!manifest.existsSync() ||
      !manifest.readAsStringSync().contains('name: xelis_wallet_flutter')) {
    stderr.writeln('Run this script from the XWF package root.');
    exitCode = 64;
    return;
  }
  final process = await Process.start(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    ['test', ...arguments],
    environment: nativeTestEnvironment(
      operatingSystem: Platform.operatingSystem,
      packageRoot: root,
      environment: Platform.environment,
    ),
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exitCode = await process.exitCode;
}
