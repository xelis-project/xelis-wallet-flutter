import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports only authored contracts and the stable runtime facade', () {
    final entrypoint = File('lib/xelis_wallet_flutter.dart').readAsStringSync();
    final exports = RegExp(
      r"^export '([^']+)';$",
      multiLine: true,
    ).allMatches(entrypoint).map((match) => match.group(1)!).toList();

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
    final walletApi = File(
      'lib/src/api/wallet/xelis_wallet.dart',
    ).readAsStringSync();
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
