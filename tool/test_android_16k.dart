import 'dart:io';

// Hermetic command-level tests: no Flutter hooks, Android SDK, or APK build.
Future<void> main() async {
  final checker = File('tool/check_android_16k.sh').absolute;
  if (!checker.existsSync()) {
    throw StateError('Run from the XWF repository root.');
  }
  final bash = Platform.isWindows
      ? '${Platform.environment['ProgramFiles'] ?? r'C:\Program Files'}/Git/bin/bash.exe'
      : 'bash';
  final root = await Directory.systemTemp.createTemp('xwf_alignment_test_');
  final ownedPath = await root.resolveSymbolicLinks();
  try {
    final bin = Directory('${root.path}/bin');
    final buildTools = Directory('${root.path}/sdk/build-tools/36.1.0');
    final ndkBin = Directory('${root.path}/sdk/ndk/29/toolchains/bin');
    for (final directory in [bin, buildTools, ndkBin]) {
      await directory.create(recursive: true);
    }
    final apk = File('${root.path}/fixture.apk');
    await apk.writeAsBytes(const []);
    final unzip = File('${bin.path}/unzip');
    final zipalign = File('${buildTools.path}/zipalign');
    final readelf = File('${ndkBin.path}/llvm-readelf');
    await unzip.writeAsString(_unzipFixture);
    await zipalign.writeAsString(_zipalignFixture);
    await readelf.writeAsString(_readelfFixture);
    final executableFiles = [unzip, zipalign, readelf];
    final chmod = await Process.run(bash, [
      '-c',
      'chmod +x -- "\$@"',
      'fixture',
      for (final file in executableFiles) _shellPath(file.path),
    ]);
    if (chmod.exitCode != 0) throw StateError('Fixture chmod failed.');

    const cases = [
      (
        name: 'mixed ABI success',
        abis: 'arm64-v8a x86_64 armeabi-v7a',
        elf: 'ok',
        zip: '0',
        success: true,
        message: 'all 2 64-bit ELF',
      ),
      (
        name: 'unaligned ARM64',
        abis: 'arm64-v8a',
        elf: 'unaligned',
        zip: '0',
        success: false,
        message: 'below 16 KB',
      ),
      (
        name: 'unaligned x86_64',
        abis: 'x86_64',
        elf: 'unaligned',
        zip: '0',
        success: false,
        message: 'below 16 KB',
      ),
      (
        name: 'readelf failure',
        abis: 'arm64-v8a',
        elf: 'failed',
        zip: '0',
        success: false,
        message: 'Could not read ELF',
      ),
      (
        name: 'missing LOAD',
        abis: 'arm64-v8a',
        elf: 'empty',
        zip: '0',
        success: false,
        message: 'No ELF LOAD',
      ),
      (
        name: 'malformed alignment',
        abis: 'arm64-v8a',
        elf: 'malformed',
        zip: '0',
        success: false,
        message: 'Invalid ELF LOAD',
      ),
      (
        name: '32-bit only',
        abis: 'armeabi-v7a',
        elf: 'ok',
        zip: '0',
        success: false,
        message: 'No supported 64-bit',
      ),
      (
        name: 'unknown ABI',
        abis: 'unknown',
        elf: 'ok',
        zip: '0',
        success: false,
        message: 'Unsupported Android ABI',
      ),
      (
        name: 'no libraries',
        abis: '',
        elf: 'ok',
        zip: '0',
        success: false,
        message: 'does not contain any shared',
      ),
      (
        name: 'ZIP alignment failure',
        abis: 'arm64-v8a',
        elf: 'ok',
        zip: '1',
        success: false,
        message: 'ZIP_FIXTURE_FAILED',
      ),
    ];
    for (final testCase in cases) {
      final result = await Process.run(
        bash,
        [
          '-c',
          r'export PATH="$1:$PATH"; shift; exec bash "$@"',
          'fixture',
          _shellPath(bin.path),
          _shellPath(checker.path),
          _shellPath(apk.path),
        ],
        environment: {
          'ANDROID_HOME': _shellPath('${root.path}/sdk'),
          'XWF_TEST_ABIS': testCase.abis,
          'XWF_TEST_ELF': testCase.elf,
          'XWF_TEST_ZIP': testCase.zip,
        },
      );
      final output = '${result.stdout}${result.stderr}';
      if ((result.exitCode == 0) != testCase.success ||
          !output.contains(testCase.message)) {
        stderr.writeln(output);
        throw StateError('Alignment case failed: ${testCase.name}');
      }
      stdout.writeln('PASS ${testCase.name}');
    }
  } finally {
    // Delete only the exact temporary directory created and resolved above.
    if (await root.resolveSymbolicLinks() != ownedPath ||
        !root.uri.pathSegments.any(
          (part) => part.startsWith('xwf_alignment_test_'),
        )) {
      throw StateError('Refusing cleanup outside the owned fixture directory.');
    }
    await root.delete(recursive: true);
  }
}

String _shellPath(String path) {
  final normalized = path.replaceAll(r'\', '/');
  if (Platform.isWindows && normalized.length > 2 && normalized[1] == ':') {
    return '/${normalized[0].toLowerCase()}${normalized.substring(2)}';
  }
  return normalized;
}

const _unzipFixture = r'''#!/usr/bin/env bash
set -euo pipefail
for destination in "$@"; do :; done
mkdir -p "$destination/lib"
for abi in $XWF_TEST_ABIS; do
  mkdir -p "$destination/lib/$abi"
  touch "$destination/lib/$abi/libfixture.so"
done
''';

const _zipalignFixture = r'''#!/usr/bin/env bash
if [[ $# -ne 6 || "$1" != '-c' || "$2" != '-P' || "$3" != '16' || "$4" != '-v' || "$5" != '4' ]]; then
  echo INVALID_ZIPALIGN_ARGUMENTS >&2
  exit 64
fi
if [[ "$XWF_TEST_ZIP" != 0 ]]; then echo ZIP_FIXTURE_FAILED >&2; fi
exit "$XWF_TEST_ZIP"
''';

const _readelfFixture = r'''#!/usr/bin/env bash
case "$XWF_TEST_ELF" in
  failed) exit 1 ;;
  empty) echo 'No program headers'; exit 0 ;;
  malformed) echo 'LOAD 0 0 0 0 0 R E invalid'; exit 0 ;;
  unaligned) alignment=0x1000 ;;
  *) alignment=0x4000 ;;
esac
# 32-bit libraries intentionally retain their normal 4 KB alignment.
if [[ "$*" == *armeabi-v7a* ]]; then alignment=0x1000; fi
echo "LOAD 0 0 0 0 0 R E $alignment"
''';
