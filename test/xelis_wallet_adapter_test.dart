import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_network_adapter.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_precomputed_table_type_adapter.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/network.dart'
    as generated_network;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/runtime_dtos.dart'
    as generated_runtime;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('authored wallet models', () {
    test('maps every XELIS network in both directions', () {
      for (final network in XelisNetwork.values) {
        expect(
          xelisNetworkFromGenerated(generatedNetworkFromXelis(network)),
          network,
        );
      }
    });

    test('maps every precomputed table type in both directions', () {
      const types = <XelisPrecomputedTableType>[
        XelisPrecomputedTableType.l1Low(),
        XelisPrecomputedTableType.l1Medium(),
        XelisPrecomputedTableType.l1Full(),
        XelisPrecomputedTableType.custom(24),
      ];

      for (final type in types) {
        expect(
          xelisPrecomputedTableTypeFromGenerated(
            generatedPrecomputedTableTypeFromXelis(type),
          ),
          type,
        );
      }
    });
  });

  group('NativeXelisWallet', () {
    test('rejects ambiguous recovery input before the native call', () async {
      await expectLater(
        createNativeXelisWallet(
          walletPath: r'C:\wallets\test',
          password: 'not logged',
          network: XelisNetwork.mainnet,
          precomputedTableType: const XelisPrecomputedTableType.l1Low(),
          operation: XelisWalletOperation.walletRecoverSeed,
          seed: 'not logged',
          privateKey: 'not logged',
        ),
        throwsArgumentError,
      );
    });

    test('exposes authored address and network values', () {
      final delegate = _FakeGeneratedWallet(
        address: 'xel:test-address',
        network: generated_network.Network.devnet,
      );
      final wallet = NativeXelisWallet(delegate);

      expect(wallet.address, 'xel:test-address');
      expect(wallet.network, XelisNetwork.devnet);
    });

    test('maps seed languages without exposing the native index', () async {
      final delegate = _FakeGeneratedWallet();
      final wallet = NativeXelisWallet(delegate);

      expect(await wallet.getSeed(language: SeedLanguage.french), 'test seed');
      expect(delegate.lastLanguageIndex, BigInt.one);
    });

    test('adapts password failures at the password boundary', () async {
      final delegate = _FakeGeneratedWallet(
        passwordError: const generated_error.NativeXelisError(
          version: XelisWalletErrorContract.currentVersion,
          source: generated_error.NativeXelisErrorSource.xelisWallet,
          code:
              generated_error.NativeXelisErrorCode.authenticationOrCorruptData,
          nativeKind: 'PASSWORD_VERIFICATION_FAILED',
          diagnosticMessage: r'C:\private\wallet.db',
        ),
      );
      final wallet = NativeXelisWallet(delegate);

      try {
        await wallet.verifyPassword(password: 'not logged');
        fail('verifyPassword should throw');
      } on XelisWalletException catch (error) {
        expect(error.source, XelisWalletErrorSource.xelisWallet);
        expect(error.operation, XelisWalletOperation.walletPasswordVerify);
        expect(error.code, XelisWalletErrorCode.authenticationOrCorruptData);
        expect(error.diagnosticMessage, r'C:\private\wallet.db');
        expect(error.toString(), isNot(contains('private')));
      }
    });

    test('adapts password-change failures at the authored boundary', () async {
      final delegate = _FakeGeneratedWallet(
        changePasswordError: const generated_error.NativeXelisError(
          version: XelisWalletErrorContract.currentVersion,
          source: generated_error.NativeXelisErrorSource.xelisWallet,
          code:
              generated_error.NativeXelisErrorCode.authenticationOrCorruptData,
          nativeKind: 'CRYPTO_ERROR',
          diagnosticMessage: r'C:\\private\\wallet.db',
        ),
      );
      final wallet = NativeXelisWallet(delegate);

      try {
        await wallet.changePassword(
          oldPassword: 'old password is not logged',
          newPassword: 'new password is not logged',
        );
        fail('changePassword should throw');
      } on XelisWalletException catch (error) {
        expect(error.source, XelisWalletErrorSource.xelisWallet);
        expect(error.operation, XelisWalletOperation.walletPasswordChange);
        expect(error.code, XelisWalletErrorCode.authenticationOrCorruptData);
        expect(error.nativeKind, 'CRYPTO_ERROR');
        expect(error.diagnosticMessage, r'C:\\private\\wallet.db');
        expect(error.toString(), isNot(contains('private')));
      }
    });

    test('forwards runtime operations through the authored wallet', () async {
      final delegate = _FakeGeneratedWallet(online: true, syncing: true);
      final wallet = NativeXelisWallet(delegate);

      await wallet.setOnline(daemonAddress: 'https://node.xelis.io/');
      expect(delegate.lastDaemonAddress, 'https://node.xelis.io/');

      expect(await wallet.isOnline(), isTrue);
      expect(await wallet.isSyncing(), isTrue);

      await wallet.rescan(topoheight: BigInt.parse('18446744073709551615'));
      expect(
        delegate.lastRescanTopoheight,
        BigInt.parse('18446744073709551615'),
      );

      await wallet.setOffline();
      expect(delegate.offlineCount, 1);
    });

    test(
      'maps every daemon-info field without losing large integers',
      () async {
        final delegate = _FakeGeneratedWallet(
          daemonInfo: generated_runtime.WalletDaemonInfo(
            height: BigInt.parse('9007199254740993'),
            topoheight: BigInt.from(2),
            stableHeight: BigInt.from(3),
            stableTopoheight: BigInt.from(4),
            prunedTopoheight: BigInt.from(5),
            topBlockHash: 'top-hash',
            circulatingSupply: BigInt.from(6),
            burnedSupply: BigInt.from(7),
            emittedSupply: BigInt.from(8),
            maximumSupply: BigInt.from(9),
            difficulty: '340282366920938463463374607431768211455',
            blockTimeTarget: BigInt.from(10),
            averageBlockTime: BigInt.from(11),
            blockReward: BigInt.from(12),
            devReward: BigInt.from(13),
            minerReward: BigInt.from(14),
            mempoolSize: BigInt.from(15),
            version: '1.2.3',
            network: generated_network.Network.stagenet,
            blockVersion: 7,
          ),
        );
        final wallet = NativeXelisWallet(delegate);

        final info = await wallet.getDaemonInfo();

        expect(info.height, BigInt.parse('9007199254740993'));
        expect(info.topoheight, BigInt.from(2));
        expect(info.stableHeight, BigInt.from(3));
        expect(info.stableTopoheight, BigInt.from(4));
        expect(info.prunedTopoheight, BigInt.from(5));
        expect(info.topBlockHash, 'top-hash');
        expect(info.circulatingSupply, BigInt.from(6));
        expect(info.burnedSupply, BigInt.from(7));
        expect(info.emittedSupply, BigInt.from(8));
        expect(info.maximumSupply, BigInt.from(9));
        expect(info.difficulty, '340282366920938463463374607431768211455');
        expect(info.blockTimeTarget, BigInt.from(10));
        expect(info.averageBlockTime, BigInt.from(11));
        expect(info.blockReward, BigInt.from(12));
        expect(info.devReward, BigInt.from(13));
        expect(info.minerReward, BigInt.from(14));
        expect(info.mempoolSize, BigInt.from(15));
        expect(info.version, '1.2.3');
        expect(info.network, XelisNetwork.stagenet);
        expect(info.blockVersion, 7);
      },
    );

    test('attaches the stable connect operation to native failures', () async {
      final delegate = _FakeGeneratedWallet(
        onlineError: const generated_error.NativeXelisError(
          version: XelisWalletErrorContract.currentVersion,
          source: generated_error.NativeXelisErrorSource.xelisWallet,
          code: generated_error.NativeXelisErrorCode.networkMismatch,
          nativeKind: 'NETWORK_MISMATCH',
          diagnosticMessage: 'privileged daemon context',
        ),
      );
      final wallet = NativeXelisWallet(delegate);

      try {
        await wallet.setOnline(daemonAddress: 'https://node.xelis.io');
        fail('setOnline should throw');
      } on XelisWalletException catch (error) {
        expect(error.operation, XelisWalletOperation.walletNetworkConnect);
        expect(error.code, XelisWalletErrorCode.networkMismatch);
        expect(error.nativeKind, 'NETWORK_MISMATCH');
        expect(error.toString(), isNot(contains('daemon context')));
      }
    });

    test(
      'coalesces concurrent close calls and becomes terminal immediately',
      () async {
        final closeCompleter = Completer<void>();
        final delegate = _FakeGeneratedWallet(
          closeFuture: closeCompleter.future,
        );
        final wallet = NativeXelisWallet(delegate);

        final first = wallet.close();
        final second = wallet.close();

        expect(identical(first, second), isTrue);
        expect(delegate.closeCount, 1);
        expect(() => wallet.address, throwsStateError);
        expect(wallet.dispose, throwsStateError);

        closeCompleter.complete();
        await Future.wait([first, second]);

        await wallet.close();
        expect(delegate.closeCount, 1);
      },
    );

    test('dispose requires a completed close and is then idempotent', () async {
      final delegate = _FakeGeneratedWallet();
      final wallet = NativeXelisWallet(delegate);

      expect(wallet.dispose, throwsStateError);
      expect(delegate.disposeCount, 0);

      await wallet.close();
      wallet.dispose();
      wallet.dispose();

      expect(wallet.isDisposed, isTrue);
      expect(delegate.disposeCount, 1);
      expect(() => wallet.network, throwsStateError);
      expect(wallet.isOnline, throwsStateError);
      expect(wallet.isSyncing, throwsStateError);
      expect(wallet.getDaemonInfo, throwsStateError);
      expect(
        () => wallet.setOnline(daemonAddress: 'https://node.xelis.io'),
        throwsStateError,
      );
      expect(wallet.setOffline, throwsStateError);
      expect(() => wallet.rescan(topoheight: BigInt.zero), throwsStateError);
    });

    test('dispose remains available after close fails', () async {
      final closeCompleter = Completer<void>();
      final closeError = StateError('native close failed');
      final delegate = _FakeGeneratedWallet(closeFuture: closeCompleter.future);
      final wallet = NativeXelisWallet(delegate);

      final closeFuture = wallet.close();
      closeCompleter.completeError(closeError);

      await expectLater(closeFuture, throwsA(same(closeError)));
      expect(wallet.dispose, returnsNormally);
      expect(wallet.isDisposed, isTrue);
      expect(delegate.disposeCount, 1);
    });
  });
}

final class _FakeGeneratedWallet implements generated_wallet.XelisWallet {
  _FakeGeneratedWallet({
    this.address = 'xel:test',
    this.network = generated_network.Network.mainnet,
    this.closeFuture,
    this.passwordError,
    this.changePasswordError,
    this.onlineError,
    this.daemonInfo,
    this.online = false,
    this.syncing = false,
  });

  final String address;
  final generated_network.Network network;
  final Future<void>? closeFuture;
  final Object? passwordError;
  final Object? changePasswordError;
  final Object? onlineError;
  final generated_runtime.WalletDaemonInfo? daemonInfo;
  final bool online;
  final bool syncing;

  int closeCount = 0;
  int disposeCount = 0;
  BigInt? lastLanguageIndex;
  String? lastDaemonAddress;
  BigInt? lastRescanTopoheight;
  int offlineCount = 0;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  String getAddressStr() => address;

  @override
  generated_network.Network getNetwork() => network;

  @override
  Future<String> getSeed({BigInt? languageIndex}) async {
    lastLanguageIndex = languageIndex;
    return 'test seed';
  }

  @override
  Future<void> isValidPassword({required String password}) async {
    if (passwordError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (changePasswordError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> onlineMode({required String daemonAddress}) async {
    lastDaemonAddress = daemonAddress;
    if (onlineError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> offlineMode() async {
    offlineCount++;
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Future<bool> isSyncing() async => syncing;

  @override
  Future<void> rescan({required BigInt topoheight}) async {
    lastRescanTopoheight = topoheight;
  }

  @override
  Future<generated_runtime.WalletDaemonInfo> getDaemonInfo() async =>
      daemonInfo ??
      generated_runtime.WalletDaemonInfo(
        height: BigInt.zero,
        topoheight: BigInt.zero,
        stableHeight: BigInt.zero,
        stableTopoheight: BigInt.zero,
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
        network: network,
        blockVersion: 0,
      );

  @override
  Future<void> close() {
    closeCount++;
    return closeFuture ?? Future<void>.value();
  }

  @override
  void dispose() {
    disposeCount++;
    _isDisposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
