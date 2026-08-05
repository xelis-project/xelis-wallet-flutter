import 'dart:io';

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

Future<void> main(List<String> arguments) async {
  final packageRoot = File.fromUri(Platform.script).parent.parent;
  final rustDirectory = Directory.fromUri(packageRoot.uri.resolve('rust/'));
  final outputDirectory = switch (arguments) {
    [] => Directory.fromUri(packageRoot.uri.resolve('web/pkg/')),
    ['--output', final path] => Directory(path).absolute,
    _ => throw ArgumentError(
      'Usage: dart run tool/build_web.dart [--output <directory>]',
    ),
  };

  final process = await Process.start(
    'wasm-pack',
    [
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
    environment: {
      ...Platform.environment,
      'RUSTUP_TOOLCHAIN': 'nightly',
      'RUSTFLAGS': _rustFlags.join(' '),
    },
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );

  final processExitCode = await process.exitCode;
  if (processExitCode != 0) {
    exitCode = processExitCode;
  }
}
