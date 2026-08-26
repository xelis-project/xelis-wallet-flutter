import 'package:build_tool/src/build_gradle.dart';
import 'package:test/test.dart';

void main() {
  test('deduplicates Flutter target platforms without reordering them', () {
    final targets = resolveGradleTargets([
      'android-arm64',
      'android-x64',
      'android-arm64',
    ]);

    expect(targets.map((target) => target.flutter), [
      'android-arm64',
      'android-x64',
    ]);
  });

  test('rejects an unknown Flutter target platform', () {
    expect(
      () => resolveGradleTargets(['android-unknown']),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('android-unknown'),
        ),
      ),
    );
  });
}
