import 'package:flutter/material.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

typedef NativeSmokeRunner = Future<void> Function();

Future<void> runNativeSmoke() async {
  await XelisWalletFlutter.initialize();
  if (!XelisWalletFlutter.isInitialized) {
    throw StateError('The native bridge did not report successful startup.');
  }

  final valid = XelisWalletFlutter.isAddressValid(
    address: 'not-a-xelis-address',
    network: XelisNetwork.mainnet,
  );
  if (valid) {
    throw StateError('The native address validator accepted invalid input.');
  }
}

void main() => runApp(const NativeSmokeApp());

class NativeSmokeApp extends StatefulWidget {
  const NativeSmokeApp({this.runSmoke = runNativeSmoke, super.key});

  final NativeSmokeRunner runSmoke;

  @override
  State<NativeSmokeApp> createState() => _NativeSmokeAppState();
}

class _NativeSmokeAppState extends State<NativeSmokeApp> {
  String _status = 'Loading native bridge…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await widget.runSmoke();
      if (mounted) {
        setState(() => _status = 'Native bridge ready');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Native bridge failed: $error');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text(_status))),
    );
  }
}
