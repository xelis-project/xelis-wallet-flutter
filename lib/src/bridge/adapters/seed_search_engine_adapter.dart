import '../../api/seed/seed_language.dart';
import '../../api/seed/seed_search_engine.dart';
import '../../api/errors/xelis_wallet_exception.dart';
import '../../generated/rust_bridge/api/seed_search_engine.dart' as generated;
import 'xelis_error_adapter.dart';

SeedSearchEngine createNativeSeedSearchEngine(SeedLanguage language) {
  final delegate = guardXelisCall(
    () => generated.SearchEngine.init(
      languageIndex: BigInt.from(rustSeedLanguageIndex(language)),
    ),
    boundary: const XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.seedSearchCreate,
    ),
  );
  return NativeSeedSearchEngine(delegate);
}

/// Private bridge implementation of the authored seed-search contract.
///
/// The class is public only for package-internal tests and is not exported by
/// the supported root library.
final class NativeSeedSearchEngine implements SeedSearchEngine {
  NativeSeedSearchEngine(this._delegate);

  final generated.SearchEngine _delegate;

  @override
  bool get isDisposed => _delegate.isDisposed;

  @override
  List<String> search({required String query}) {
    _ensureActive();
    return guardXelisCall(
      () => _delegate.search(query: query),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.seedSearch,
      ),
    );
  }

  @override
  List<String> findInvalidWords({required List<String> words}) {
    _ensureActive();
    return guardXelisCall(
      () => _delegate.checkSeed(seed: words),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.seedValidate,
      ),
    );
  }

  @override
  void dispose() {
    if (isDisposed) {
      return;
    }
    guardXelisCall(
      _delegate.dispose,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.seedSearchDispose,
      ),
    );
  }

  void _ensureActive() {
    if (isDisposed) {
      throw StateError('The seed search engine has been disposed.');
    }
  }
}

/// Explicit mapping to the order locked by `xelis_wallet::mnemonics::LANGUAGES`.
int rustSeedLanguageIndex(SeedLanguage language) => switch (language) {
  SeedLanguage.english => 0,
  SeedLanguage.french => 1,
  SeedLanguage.italian => 2,
  SeedLanguage.spanish => 3,
  SeedLanguage.portuguese => 4,
  SeedLanguage.japanese => 5,
  SeedLanguage.chineseSimplified => 6,
  SeedLanguage.russian => 7,
  SeedLanguage.esperanto => 8,
  SeedLanguage.dutch => 9,
  SeedLanguage.german => 10,
};
