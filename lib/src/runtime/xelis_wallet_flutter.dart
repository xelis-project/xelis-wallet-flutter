import '../api/address/xelis_address_descriptor.dart';
import '../api/data/xelis_data_element.dart';
import '../api/errors/xelis_wallet_exception.dart';
import '../api/models/xelis_network.dart';
import '../api/precomputed/xelis_precomputed_table_type.dart';
import '../api/seed/seed_language.dart';
import '../api/seed/seed_search_engine.dart';
import '../api/wallet/xelis_wallet.dart';
import '../api/logging/log_entry.dart';
import '../api/progress/progress_report.dart';
import '../bridge/adapters/runtime_event_adapters.dart';
import '../bridge/adapters/seed_search_engine_adapter.dart'
    as seed_search_adapter;
import '../bridge/adapters/xelis_error_adapter.dart';
import '../bridge/adapters/xelis_runtime_utility_adapter.dart';
import '../bridge/adapters/xelis_wallet_adapter.dart';
import '../generated/rust_bridge/api/api.dart' as generated_api;
import '../generated/rust_bridge/frb_generated.dart';
import 'runtime_lifecycle.dart';

/// Stable lifecycle entrypoint for the native XELIS wallet runtime.
///
/// Call [initialize] before any other package API. Configuration, logging, and
/// the optional crypto provider remain explicit so applications retain control
/// over their startup order and platform policy.
abstract final class XelisWalletFlutter {
  static final RuntimeLifecycle _lifecycle = RuntimeLifecycle(
    initializeRuntime: () => guardXelisFuture(
      () => XelisWalletFlutterBridge.init(),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.runtimeInitialize,
      ),
    ),
  );
  static final RuntimeLifecycle _configurationLifecycle = RuntimeLifecycle(
    initializeRuntime: () => guardXelisFuture(
      generated_api.initializeXelisConfig,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisCommon,
        operation: XelisWalletOperation.configurationInitialize,
      ),
    ),
  );
  static final RuntimeLifecycle _cryptoProviderLifecycle = RuntimeLifecycle(
    initializeRuntime: () => guardXelisFuture(
      generated_api.initializeCryptoProvider,
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.cryptoProviderInitialize,
      ),
    ),
  );
  static final ConfiguredRuntimeLifecycle<
    ({XelisLogLevel minimumLevel, bool diagnosticMode})
  >
  _rustLoggerLifecycle = ConfiguredRuntimeLifecycle(
    initializeRuntime: (configuration) => guardXelisFuture(
      () => generated_api.setUpRustLogger(
        minimumLevel: adaptLogLevel(configuration.minimumLevel),
        diagnosticMode: configuration.diagnosticMode,
      ),
      boundary: const XelisErrorBoundary(
        source: XelisWalletErrorSource.xelisWalletFlutter,
        operation: XelisWalletOperation.loggingInitialize,
      ),
    ),
  );

  /// Whether the native bridge has completed initialization successfully.
  static bool get isInitialized => _lifecycle.isInitialized;

  /// Loads and initializes the native Flutter Rust Bridge runtime.
  ///
  /// Concurrent calls share one initialization. Subsequent calls after a
  /// successful initialization are no-ops. A failed attempt can be retried.
  static Future<void> initialize() => _lifecycle.initialize();

  /// Initializes the global `xelis_common` configuration.
  static Future<void> initializeConfiguration() {
    _ensureInitialized();
    return _configurationLifecycle.initialize();
  }

  /// Initializes the optional platform crypto provider.
  static Future<void> initializeCryptoProvider() {
    _ensureInitialized();
    return _cryptoProviderLifecycle.initialize();
  }

  /// Installs the Rust logger used by [createRustLogStream].
  ///
  /// Standard mode only forwards safe records explicitly authored for package
  /// consumers. [diagnosticMode] also forwards audited package-module records,
  /// which can include paths, amounts, hashes, or other operational context.
  /// Free-form upstream dependency records remain excluded. Keep diagnostic
  /// mode local to an explicit development/debugging workflow.
  ///
  /// The first successful configuration is process-wide and immutable.
  static Future<void> initializeRustLogger({
    XelisLogLevel minimumLevel = XelisLogLevel.info,
    bool diagnosticMode = false,
  }) {
    _ensureInitialized();
    return _rustLoggerLifecycle.initialize((
      minimumLevel: minimumLevel,
      diagnosticMode: diagnosticMode,
    ));
  }

  /// Creates the stream receiving Rust log entries.
  ///
  /// The native runtime owns one global sink, so applications should retain a
  /// single subscription instead of repeatedly creating streams.
  static Stream<XelisLogEntry> createRustLogStream() {
    _ensureInitialized();
    return adaptLogStream(generated_api.createLogStream);
  }

  /// Creates the stream receiving native progress reports.
  ///
  /// The native runtime owns one global sink, so applications should retain a
  /// single subscription instead of repeatedly creating streams.
  static Stream<ProgressReport> createProgressReportStream() {
    _ensureInitialized();
    return adaptProgressStream(generated_api.createProgressReportStream);
  }

  /// Creates a native mnemonic dictionary search engine for [language].
  ///
  /// The caller owns the returned handle and should dispose it when it is no
  /// longer needed. Disposing this handle does not dispose the global runtime.
  static SeedSearchEngine createSeedSearchEngine({
    required SeedLanguage language,
  }) {
    _ensureInitialized();
    return seed_search_adapter.createNativeSeedSearchEngine(language);
  }

  /// Returns whether [address] is valid for [network].
  ///
  /// A syntactically invalid address or one for another network returns
  /// `false`; bridge failures remain structured exceptions.
  static bool isAddressValid({
    required String address,
    required XelisNetwork network,
  }) {
    _ensureInitialized();
    return validateXelisAddress(address: address, network: network);
  }

  /// Parses a standard or integrated [address] without contacting a daemon.
  ///
  /// The returned descriptor preserves the complete encoded destination, its
  /// normal base address, network class, and exact typed integrated data.
  /// Invalid input throws [XelisWalletException] with operation
  /// `address.parse` and code `input.invalid`.
  static XelisAddressDescriptor parseAddress({required String address}) {
    _ensureInitialized();
    return parseXelisAddress(address: address);
  }

  /// Creates an integrated address locally from [baseAddress] and typed data.
  ///
  /// [baseAddress] must be a normal address. The native XELIS protocol limits
  /// serialized integrated data to 1,024 bytes. Invalid input throws
  /// [XelisWalletException] with operation `address.integrated.create`.
  static XelisAddressDescriptor makeIntegratedAddress({
    required String baseAddress,
    required XelisDataElement integratedData,
  }) {
    _ensureInitialized();
    return makeXelisIntegratedAddress(
      baseAddress: baseAddress,
      integratedData: integratedData,
    );
  }

  /// Checks whether the requested precomputed tables exist at [path].
  static Future<bool> hasPrecomputedTables({
    required String path,
    required XelisPrecomputedTableType type,
  }) {
    _ensureInitialized();
    return checkXelisPrecomputedTables(path: path, type: type);
  }

  /// Loads or generates the requested precomputed tables at [path].
  ///
  /// The exact path is materialized even when compatible tables are already
  /// cached in this process, so the result remains available after restart.
  static Future<void> updatePrecomputedTables({
    required String path,
    required XelisPrecomputedTableType type,
  }) {
    _ensureInitialized();
    return updateXelisPrecomputedTables(path: path, type: type);
  }

  /// Creates a new wallet at the exact [walletPath].
  ///
  /// [password] is passed directly to the native wallet and is never persisted
  /// or logged by this package.
  static Future<XelisWallet> createWallet({
    required String walletPath,
    required String password,
    required XelisNetwork network,
    required XelisPrecomputedTableType precomputedTableType,
    String? precomputedTablesPath,
  }) {
    _ensureInitialized();
    return createNativeXelisWallet(
      walletPath: walletPath,
      password: password,
      network: network,
      precomputedTableType: precomputedTableType,
      precomputedTablesPath: precomputedTablesPath,
      operation: XelisWalletOperation.walletCreate,
    );
  }

  /// Recovers a wallet from [seed] at the exact [walletPath].
  ///
  /// The seed and password are secret material. They are passed directly to
  /// the native wallet and are never persisted or logged by this package.
  static Future<XelisWallet> recoverWalletFromSeed({
    required String walletPath,
    required String password,
    required String seed,
    required XelisNetwork network,
    required XelisPrecomputedTableType precomputedTableType,
    String? precomputedTablesPath,
  }) {
    _ensureInitialized();
    return createNativeXelisWallet(
      walletPath: walletPath,
      password: password,
      seed: seed,
      network: network,
      precomputedTableType: precomputedTableType,
      precomputedTablesPath: precomputedTablesPath,
      operation: XelisWalletOperation.walletRecoverSeed,
    );
  }

  /// Recovers a wallet from [privateKey] at the exact [walletPath].
  ///
  /// The private key and password are secret material. They are passed directly
  /// to the native wallet and are never persisted or logged by this package.
  static Future<XelisWallet> recoverWalletFromPrivateKey({
    required String walletPath,
    required String password,
    required String privateKey,
    required XelisNetwork network,
    required XelisPrecomputedTableType precomputedTableType,
    String? precomputedTablesPath,
  }) {
    _ensureInitialized();
    return createNativeXelisWallet(
      walletPath: walletPath,
      password: password,
      privateKey: privateKey,
      network: network,
      precomputedTableType: precomputedTableType,
      precomputedTablesPath: precomputedTablesPath,
      operation: XelisWalletOperation.walletRecoverPrivateKey,
    );
  }

  /// Opens an existing wallet at the exact [walletPath].
  ///
  /// A wrong password and unreadable encrypted wallet data intentionally share
  /// one stable error category because the native dependency does not expose a
  /// reliable non-textual distinction between them.
  static Future<XelisWallet> openWallet({
    required String walletPath,
    required String password,
    required XelisNetwork network,
    required XelisPrecomputedTableType precomputedTableType,
    String? precomputedTablesPath,
  }) {
    _ensureInitialized();
    return openNativeXelisWallet(
      walletPath: walletPath,
      password: password,
      network: network,
      precomputedTableType: precomputedTableType,
      precomputedTablesPath: precomputedTablesPath,
    );
  }

  static void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'The XELIS wallet runtime is not initialized. '
        'Call XelisWalletFlutter.initialize() first.',
      );
    }
  }
}
