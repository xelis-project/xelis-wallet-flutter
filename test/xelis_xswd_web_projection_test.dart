import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_xswd_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/xswd_dtos.dart'
    as generated;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('XSWD projection preserves integers beyond JavaScript safety', () {
    const decimal = '9007199254740993';
    final request = generated.XswdRequestSummary(
      eventType: generated.XswdRequestType.permission(
        const generated.NativeXswdPayload(
          tokens: [
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectStart,
              length: 1,
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.objectKey,
              textValue: 'amount',
            ),
            generated.NativeXswdPayloadToken(
              kind: generated.NativeXswdPayloadTokenKind.integer,
              textValue: decimal,
            ),
          ],
        ),
      ),
      applicationInfo: const generated.AppInfo(
        id: 'app',
        name: 'app',
        description: '',
        url: null,
        permissions: {},
        isRelayer: true,
      ),
    );

    final authored = xelisXswdRequestFromGenerated(request);
    final payload = authored.payload as XelisXswdObjectValue;
    final amount = payload.fields['amount'] as XelisXswdIntegerValue;

    expect(amount.value, BigInt.parse(decimal));
    expect(amount.value.toString(), decimal);
    expect(authored.toString(), isNot(contains(decimal)));
    expect(payload.toString(), isNot(contains('amount')));
    expect(amount.toString(), isNot(contains(decimal)));
  });
}
