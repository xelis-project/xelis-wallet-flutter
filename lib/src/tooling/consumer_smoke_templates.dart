String consumerSmokePubspecSource({required String packagePath}) =>
    '''
name: xwf_consumer_smoke
description: Ephemeral release consumer for xelis_wallet_flutter.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  xelis_wallet_flutter:
    path: '$packagePath'

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: false
''';

const nativeConsumerMainSource = '''
import 'package:flutter/widgets.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runNativeSmoke();
  debugPrint('XWF_NATIVE_CONSUMER_SMOKE_PASS');
  runApp(const Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: Text('XWF_NATIVE_CONSUMER_SMOKE_PASS')),
  ));
}
''';

const nativeConsumerIntegrationTestSource = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xwf_consumer_smoke/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads and calls the Rust library', (tester) async {
    await runNativeSmoke();
  });
}
''';

const webConsumerMainSource = r'''
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _baseAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';
const _successMarker = 'XWF_WEB_CONSUMER_SMOKE_PASS';
const _failureMarker = 'XWF_WEB_CONSUMER_SMOKE_FAIL';
final _aboveJavaScriptSafeInteger = BigInt.parse('9007199254740993');
final _maximumUnsigned64 = BigInt.parse('18446744073709551615');

@JS('xwfReportResult')
external void _reportResult(JSString result);

Future<void> runWebAddressIntegerSmoke() async {
  await XelisWalletFlutter.initialize();
  if (!XelisWalletFlutter.isInitialized) {
    throw StateError('The Web bridge did not report successful startup.');
  }

  final integrated = XelisWalletFlutter.makeIntegratedAddress(
    baseAddress: _baseAddress,
    integratedData: XelisDataElement.fields([
      XelisDataField(
        key: const XelisDataValue.string('above_javascript_safe_integer'),
        value: XelisDataElement.value(
          XelisDataValue.unsigned(
            type: XelisUnsignedIntegerType.u64,
            value: _aboveJavaScriptSafeInteger,
          ),
        ),
      ),
      XelisDataField(
        key: const XelisDataValue.string('maximum_u64'),
        value: XelisDataElement.value(
          XelisDataValue.unsigned(
            type: XelisUnsignedIntegerType.u64,
            value: _maximumUnsigned64,
          ),
        ),
      ),
    ]),
  );
  final reparsed = XelisWalletFlutter.parseAddress(
    address: integrated.encodedAddress,
  );
  if (reparsed != integrated) {
    throw StateError('The Rust address round trip changed the descriptor.');
  }

  final data = reparsed.integratedData;
  if (data is! XelisDataFields) {
    throw StateError('The integrated address did not retain field data.');
  }
  _expectUnsigned(
    data,
    key: 'above_javascript_safe_integer',
    expected: _aboveJavaScriptSafeInteger,
  );
  _expectUnsigned(data, key: 'maximum_u64', expected: _maximumUnsigned64);
}

void _expectUnsigned(
  XelisDataFields data, {
  required String key,
  required BigInt expected,
}) {
  for (final field in data.fields) {
    if (field.key case XelisDataString(value: final fieldKey)
        when fieldKey == key) {
      final element = field.value;
      if (element is! XelisDataValueElement ||
          element.value is! XelisDataUnsigned) {
        throw StateError('The $key value did not remain an unsigned integer.');
      }
      final unsigned = element.value as XelisDataUnsigned;
      if (unsigned.type != XelisUnsignedIntegerType.u64 ||
          unsigned.value != expected) {
        throw StateError('The $key value changed during the Rust round trip.');
      }
      return;
    }
  }
  throw StateError('The $key value was missing after the Rust round trip.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await runWebAddressIntegerSmoke();
    _reportResult(_successMarker.toJS);
    runApp(const SizedBox.shrink());
  } catch (_) {
    _reportResult(_failureMarker.toJS);
    rethrow;
  }
}
''';

const webConsumerIndexSource = r'''
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="XWF Web consumer smoke">
  <title>XWF Web consumer smoke</title>
  <script>
    window.xwfReportResult = function(result) {
      document.documentElement.dataset.xwfSmoke = result;
      fetch('/__xwf_smoke_result?value=' + encodeURIComponent(result), {
        cache: 'no-store'
      });
    };
  </script>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''';
