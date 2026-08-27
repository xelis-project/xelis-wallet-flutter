import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('loads and calls the Rust library', () async {
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
