import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/api/errors/xelis_wallet_exception.dart';
import 'package:xelis_wallet_flutter/src/api/seed/seed_language.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/seed_search_engine_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/seed_search_engine.dart'
    as generated;

void main() {
  test('maps every authored seed language explicitly', () {
    const expectedIndices = <SeedLanguage, int>{
      SeedLanguage.english: 0,
      SeedLanguage.french: 1,
      SeedLanguage.italian: 2,
      SeedLanguage.spanish: 3,
      SeedLanguage.portuguese: 4,
      SeedLanguage.japanese: 5,
      SeedLanguage.chineseSimplified: 6,
      SeedLanguage.russian: 7,
      SeedLanguage.esperanto: 8,
      SeedLanguage.dutch: 9,
      SeedLanguage.german: 10,
    };

    expect(SeedLanguage.values, hasLength(expectedIndices.length));
    for (final entry in expectedIndices.entries) {
      expect(rustSeedLanguageIndex(entry.key), entry.value);
    }
  });

  test('forwards search and invalid-word checks without retaining inputs', () {
    final delegate = _FakeSearchEngine();
    final engine = NativeSeedSearchEngine(delegate);
    final words = <String>['alpha', 'invalid'];

    expect(engine.search(query: 'al'), ['alpha', 'alpine']);
    expect(engine.findInvalidWords(words: words), ['invalid']);
    expect(delegate.lastQuery, 'al');
    expect(delegate.lastSeed, same(words));
  });

  test('maps native operation errors without adding seed material', () {
    final delegate = _FakeSearchEngine(
      searchError: AnyhowException('dictionary lookup failed'),
    );
    final engine = NativeSeedSearchEngine(delegate);

    try {
      engine.search(query: 'secret-query');
      fail(
        'The native error should be rethrown through the authored contract.',
      );
    } on XelisWalletOperationException catch (error) {
      expect(error.source, XelisWalletErrorSource.xelisWallet);
      expect(error.operation, XelisWalletOperation.seedSearch);
      expect(error.code, XelisWalletErrorCode.operationFailed);
      expect(error.diagnosticMessage, 'dictionary lookup failed');
      expect(error.diagnosticMessage, isNot(contains('secret-query')));
    }
  });

  test('disposes the local handle idempotently and guards later use', () {
    final delegate = _FakeSearchEngine();
    final engine = NativeSeedSearchEngine(delegate);

    engine.dispose();
    engine.dispose();

    expect(engine.isDisposed, isTrue);
    expect(delegate.disposeCount, 1);
    expect(() => engine.search(query: 'query'), throwsA(isA<StateError>()));
    expect(
      () => engine.findInvalidWords(words: const ['word']),
      throwsA(isA<StateError>()),
    );
  });
}

final class _FakeSearchEngine implements generated.SearchEngine {
  _FakeSearchEngine({this.searchError});

  final Object? searchError;
  bool _isDisposed = false;
  int disposeCount = 0;
  String? lastQuery;
  List<String>? lastSeed;

  @override
  bool get isDisposed => _isDisposed;

  @override
  List<String> search({required String query}) {
    lastQuery = query;
    final error = searchError;
    if (error != null) {
      throw error;
    }
    return const ['alpha', 'alpine'];
  }

  @override
  List<String> checkSeed({required List<String> seed}) {
    lastSeed = seed;
    return const ['invalid'];
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    disposeCount++;
  }
}
