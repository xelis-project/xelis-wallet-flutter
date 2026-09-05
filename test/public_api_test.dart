import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports only authored contracts and the stable runtime facade', () {
    final entrypoint = File('lib/xelis_wallet_flutter.dart').readAsStringSync();
    final exportDirectives = RegExp(
      r"^export\s+'([^']+)'([^;]*);",
      multiLine: true,
    ).allMatches(entrypoint).toList();
    final exports = exportDirectives.map((match) => match.group(1)!).toList();

    expect(exports, isNotEmpty);
    expect(
      exports,
      everyElement(
        anyOf(
          startsWith('src/api/'),
          equals('src/runtime/xelis_wallet_flutter.dart'),
        ),
      ),
    );
    final xswdExport = exportDirectives.singleWhere(
      (match) => match.group(1) == 'src/api/xswd/xelis_xswd.dart',
    );
    expect(
      xswdExport.group(2),
      matches(RegExp(r'\bhide\s+xelisXswdApplicationWithSessionIdentity\b')),
      reason:
          'The package-owned XSWD session identity helper must stay private.',
    );
    expect(Directory('lib/api').existsSync(), isFalse);
  });

  test('keeps all authored public API models independent from FRB', () {
    final authoredApiFiles = Directory('lib/src/api')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in authoredApiFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('generated/')), reason: file.path);
      expect(source, isNot(contains('flutter_rust_bridge')), reason: file.path);
    }
  });

  test('keeps derived and runtime-internal helpers out of the wallet', () {
    final walletApi = File('lib/src/api/wallet/xelis_wallet.dart')
        .readAsStringSync();
    for (final method in <String>[
      'getNonce',
      'formatCoin',
      'hasAssetBalance',
    ]) {
      expect(
        RegExp('\\b${RegExp.escape(method)}\\s*\\(').hasMatch(walletApi),
        isFalse,
        reason: method,
      );
    }
  });
}
