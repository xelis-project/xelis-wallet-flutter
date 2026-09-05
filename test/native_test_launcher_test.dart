import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/test_native.dart' as launcher;

void main() {
  test(
    'Linux loads the Flutter-built asset, not a stale release directory',
    () {
      final root = Directory('workspace with spaces');
      const original = {
        'PATH': 'preserved',
        launcher.nativeLibraryDirectoryVariable: 'old/rust/target/release',
      };
      final environment = launcher.nativeTestEnvironment(
        operatingSystem: 'linux',
        packageRoot: root,
        environment: original,
      );
      expect(
        environment[launcher.nativeLibraryDirectoryVariable],
        Directory.fromUri(
          root.absolute.uri.resolve('build/native_assets/linux/'),
        ).path,
      );
      expect(environment['PATH'], 'preserved');
      expect(
        original[launcher.nativeLibraryDirectoryVariable],
        'old/rust/target/release',
      );
    },
  );

  test('other hosts keep their existing loading environment', () {
    for (final host in ['windows', 'macos']) {
      expect(
        launcher.nativeTestEnvironment(
          operatingSystem: host,
          packageRoot: Directory.current,
          environment: const {'PATH': 'preserved'},
        ),
        {'PATH': 'preserved'},
      );
    }
  });
}
