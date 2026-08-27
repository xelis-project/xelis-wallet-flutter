import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('preserves exact unsigned widths and values', () {
    final maximum = XelisDataValue.unsigned(
      type: XelisUnsignedIntegerType.u128,
      value: XelisUnsignedIntegerType.u128.maximum,
    );
    final same = XelisDataValue.unsigned(
      type: XelisUnsignedIntegerType.u128,
      value: BigInt.parse('340282366920938463463374607431768211455'),
    );
    final otherWidth = XelisDataValue.unsigned(
      type: XelisUnsignedIntegerType.u64,
      value: BigInt.one,
    );
    final u8 = XelisDataValue.unsigned(
      type: XelisUnsignedIntegerType.u8,
      value: BigInt.one,
    );

    expect(maximum, same);
    expect(otherWidth, isNot(u8));
  });

  test('copies arrays, fields, and blobs into immutable storage', () {
    final blobSource = <int>[1, 2];
    final blob = XelisDataValue.blob(blobSource) as XelisDataBlob;
    blobSource.add(3);
    expect(blob.bytes, [1, 2]);
    expect(() => blob.bytes.add(4), throwsUnsupportedError);

    final arraySource = <XelisDataElement>[
      const XelisDataElement.value(XelisDataValue.boolean(true)),
    ];
    final array = XelisDataElement.array(arraySource) as XelisDataArray;
    arraySource.clear();
    expect(array.values, hasLength(1));
    expect(
      () => array.values.add(
        const XelisDataElement.value(XelisDataValue.boolean(false)),
      ),
      throwsUnsupportedError,
    );
  });

  test('preserves ordered non-string field keys', () {
    final fields = XelisDataElement.fields([
      XelisDataField(
        key: XelisDataValue.unsigned(
          type: XelisUnsignedIntegerType.u8,
          value: BigInt.from(7),
        ),
        value: const XelisDataElement.value(XelisDataValue.string('first')),
      ),
      const XelisDataField(
        key: XelisDataValue.boolean(true),
        value: XelisDataElement.value(XelisDataValue.string('second')),
      ),
    ]) as XelisDataFields;

    expect(fields.fields.first.key, isA<XelisDataUnsigned>());
    expect(fields.fields.last.key, const XelisDataValue.boolean(true));
  });

  test('rejects values that cannot be serialized faithfully', () {
    expect(
      () => XelisDataValue.unsigned(
        type: XelisUnsignedIntegerType.u8,
        value: BigInt.from(256),
      ),
      throwsArgumentError,
    );
    expect(
      () => XelisDataValue.unsigned(
        type: XelisUnsignedIntegerType.u128,
        value: BigInt.from(-1),
      ),
      throwsArgumentError,
    );
    expect(() => XelisDataValue.hash('abcd'), throwsFormatException);
    expect(() => XelisDataValue.blob([256]), throwsRangeError);
    expect(
      () => XelisDataElement.fields([
        const XelisDataField(
          key: XelisDataValue.string('duplicate'),
          value: XelisDataElement.value(XelisDataValue.boolean(true)),
        ),
        const XelisDataField(
          key: XelisDataValue.string('duplicate'),
          value: XelisDataElement.value(XelisDataValue.boolean(false)),
        ),
      ]),
      throwsArgumentError,
    );
  });
}
