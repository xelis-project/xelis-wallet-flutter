import 'package:build_tool/src/android_environment.dart';
import 'package:build_tool/src/target.dart';
import 'package:test/test.dart';

void main() {
  test('adds 16 KB linker flags to 64-bit Android targets', () {
    for (final flutterTarget in ['android-arm64', 'android-x64']) {
      final flags = buildAndroidRustFlags(
        inheritedRustFlags: 'inherited',
        workaroundDir: 'workaround',
        target: Target.forFlutterName(flutterTarget)!,
      ).split('\x1f');

      expect(flags, [
        'inherited',
        '-L',
        'workaround',
        '-C',
        'link-arg=-Wl,--hash-style=both',
        '-C',
        'link-arg=-Wl,-z,max-page-size=16384',
      ]);
    }
  });

  test('does not add 16 KB linker flags to 32-bit Android targets', () {
    for (final flutterTarget in ['android-arm', 'android-x86']) {
      final flags = buildAndroidRustFlags(
        inheritedRustFlags: '',
        workaroundDir: 'workaround',
        target: Target.forFlutterName(flutterTarget)!,
      ).split('\x1f');

      expect(flags, ['-L', 'workaround']);
    }
  });
}
