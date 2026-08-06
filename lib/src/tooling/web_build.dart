import 'dart:io';
import 'dart:isolate';

const buildWebUsage =
    'Usage: dart run xelis_wallet_flutter:build_web --output <directory>';

const buildWebHelp =
    '''
$buildWebUsage

Build the XELIS wallet WebAssembly package into the requested directory.

Prerequisites: wasm-pack, Rust nightly, and the wasm32-unknown-unknown target.
''';

const _rustFlags = <String>[
  '-C target-feature=+atomics,+bulk-memory,+mutable-globals',
  '-C link-arg=--export=__heap_base',
  '-C link-arg=--export=__wasm_init_tls',
  '-C link-arg=--export=__tls_base',
  '-C link-arg=--export=__tls_size',
  '-C link-arg=--export=__tls_align',
  '-C link-arg=--shared-memory',
  '-C link-arg=--import-memory',
  '-C link-arg=--max-memory=2147483648',
];

sealed class WebBuildArguments {
  const WebBuildArguments();
}

final class WebBuildHelpArguments extends WebBuildArguments {
  const WebBuildHelpArguments();
}

final class WebBuildOutputArguments extends WebBuildArguments {
  const WebBuildOutputArguments(this.outputDirectory);

  final Directory outputDirectory;
}

WebBuildArguments parseWebBuildArguments(
  List<String> arguments, {
  Directory? defaultOutputDirectory,
}) {
  return switch (arguments) {
    ['--help'] => const WebBuildHelpArguments(),
    ['--output', final path] when path.isNotEmpty => WebBuildOutputArguments(
      Directory(path).absolute,
    ),
    [] when defaultOutputDirectory != null => WebBuildOutputArguments(
      defaultOutputDirectory.absolute,
    ),
    _ => throw const FormatException('Expected --output <directory>.'),
  };
}

Future<Directory> resolveXwfPackageRoot() async {
  final libraryUri = await Isolate.resolvePackageUri(
    Uri.parse('package:xelis_wallet_flutter/xelis_wallet_flutter.dart'),
  );
  if (libraryUri == null || libraryUri.scheme != 'file') {
    throw StateError('Could not resolve the xelis_wallet_flutter package.');
  }

  return File.fromUri(libraryUri).parent.parent;
}

final class WebBuildCommand {
  const WebBuildCommand({
    required this.executable,
    required this.arguments,
    required this.environment,
  });

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
}

WebBuildCommand createWebBuildCommand({
  required Directory packageRoot,
  required Directory outputDirectory,
  Map<String, String>? environment,
}) {
  final rustDirectory = Directory.fromUri(packageRoot.uri.resolve('rust/'));

  return WebBuildCommand(
    executable: 'wasm-pack',
    arguments: [
      'build',
      '-t',
      'no-modules',
      '-d',
      outputDirectory.path,
      '--no-typescript',
      '--weak-refs',
      rustDirectory.path,
      '--',
      '-Z',
      'build-std=std,panic_abort',
      '--no-default-features',
      '--features',
      'network_handler,xswd',
    ],
    environment: Map.unmodifiable({
      ...?environment,
      'RUSTUP_TOOLCHAIN': 'nightly',
      'RUSTFLAGS': _rustFlags.join(' '),
    }),
  );
}

Future<int> runWebBuild({
  required Directory packageRoot,
  required Directory outputDirectory,
  IOSink? errorSink,
}) async {
  final command = createWebBuildCommand(
    packageRoot: packageRoot,
    outputDirectory: outputDirectory,
    environment: Platform.environment,
  );

  try {
    final process = await Process.start(
      command.executable,
      command.arguments,
      environment: command.environment,
      mode: ProcessStartMode.inheritStdio,
    );
    return await process.exitCode;
  } on ProcessException catch (error) {
    (errorSink ?? stderr).writeln(
      'Could not start wasm-pack. Install wasm-pack, Rust nightly, and the '
      'wasm32-unknown-unknown target, then retry. (${error.message})',
    );
    return 127;
  }
}
