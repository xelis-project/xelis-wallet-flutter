import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('exports the stable wallet runtime facade', () {
    expect(XelisWalletFlutter.initialize, isA<Function>());
    expect(XelisWalletFlutter.isInitialized, isFalse);
    expect(XelisLogLevel.values, hasLength(5));
    expect(XelisLogSource.values, hasLength(5));
    expect(SeedLanguage.values, hasLength(11));
    expect(XelisWalletFlutter.isAddressValid, isA<Function>());
    expect(XelisWalletFlutter.hasPrecomputedTables, isA<Function>());
    expect(XelisWalletFlutter.updatePrecomputedTables, isA<Function>());
  });

  test('guards runtime services before bridge initialization', () {
    expect(
      () => XelisWalletFlutter.initializeConfiguration(),
      throwsStateError,
    );
    expect(
      () => XelisWalletFlutter.createSeedSearchEngine(
        language: SeedLanguage.english,
      ),
      throwsStateError,
    );
  });

  test('exports authored runtime event models', () {
    const logEntry = XelisLogEntry(
      level: XelisLogLevel.info,
      source: XelisLogSource.xelisWallet,
      target: 'xelis_wallet',
      message: 'ready',
    );
    const progressReport = ProgressReport(
      progress: 0.5,
      step: 'sync',
      message: 'Synchronizing',
    );

    expect(
      logEntry,
      const XelisLogEntry(
        level: XelisLogLevel.info,
        source: XelisLogSource.xelisWallet,
        target: 'xelis_wallet',
        message: 'ready',
      ),
    );
    expect(progressReport.progress, 0.5);
    expect(
      XelisDaemonInfo(
        height: BigInt.zero,
        topoheight: BigInt.zero,
        stableHeight: BigInt.zero,
        stableTopoheight: BigInt.zero,
        prunedTopoheight: null,
        topBlockHash: 'hash',
        circulatingSupply: BigInt.zero,
        burnedSupply: BigInt.zero,
        emittedSupply: BigInt.zero,
        maximumSupply: BigInt.zero,
        difficulty: '0',
        blockTimeTarget: BigInt.zero,
        averageBlockTime: BigInt.zero,
        blockReward: BigInt.zero,
        devReward: BigInt.zero,
        minerReward: BigInt.zero,
        mempoolSize: BigInt.zero,
        version: 'test',
        network: XelisNetwork.devnet,
        blockVersion: 0,
      ).network,
      XelisNetwork.devnet,
    );
  });

  test('exports the stable wallet exception contract', () {
    const error = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.seedSearch,
      code: XelisWalletErrorCode.operationFailed,
      supportId: 'XWF-1111-2222-3333-4444-5555',
      diagnosticMessage: 'Cannot open wallet\nprivate diagnostic context',
    );

    expect(error, isA<XelisWalletException>());
    expect(error.contractVersion, XelisWalletErrorContract.currentVersion);
    expect(error.source, XelisWalletErrorSource.xelisWallet);
    expect(error.operation, XelisWalletOperation.seedSearch);
    expect(error.code, XelisWalletErrorCode.operationFailed);
    expect(error.supportId, 'XWF-1111-2222-3333-4444-5555');
    expect(error.diagnosticMessage, contains('private diagnostic context'));
    expect(error.toString(), isNot(contains('private diagnostic context')));
  });
}
