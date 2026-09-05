import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('loads and calls the Rust library', () async {
    if (Platform.isLinux) {
      final assetDirectory = Directory.fromUri(
        Directory.current.uri.resolve('build/native_assets/linux/'),
      );
      expect(
        Platform.environment['FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR'],
        assetDirectory.path,
        reason: 'Run host tests with dart tool/test_native.dart.',
      );
      expect(
        File.fromUri(assetDirectory.uri.resolve('libxelis_wallet_flutter.so'))
            .existsSync(),
        isTrue,
        reason:
            'The Flutter Native Assets hook must produce the library; '
            'a Cargo release or system library is not a substitute.',
      );
    }
    await XelisWalletFlutter.initialize();

    expect(XelisWalletFlutter.isInitialized, isTrue);
    expect(
      XelisWalletFlutter.isAddressValid(
        address: 'not-a-xelis-address',
        network: XelisNetwork.mainnet,
      ),
      isFalse,
    );
  });
}
