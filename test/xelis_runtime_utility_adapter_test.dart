import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_runtime_utility_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/address_dtos.dart'
    as generated_address;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('locks the stable authored address operation identifiers', () {
    expect(XelisWalletOperation.addressValidate.id, 'address.validate');
    expect(XelisWalletOperation.addressParse.id, 'address.parse');
    expect(
      XelisWalletOperation.addressIntegratedCreate.id,
      'address.integrated.create',
    );
  });

  test('validates addresses through authored network values', () {
    expect(
      validateXelisAddress(
        address: 'address',
        network: XelisNetwork.devnet,
        validator: ({required strAddress, required network}) {
          expect(strAddress, 'address');
          expect(network.name, 'devnet');
          return true;
        },
      ),
      isTrue,
    );
  });

  test('parses a lossless address descriptor from the generated wire', () {
    final descriptor = parseXelisAddress(
      address: 'integrated',
      parser: ({required address}) {
        expect(address, 'integrated');
        return generated_address.NativeXelisAddressDescriptor(
          encodedAddress: 'integrated',
          baseAddress: 'base',
          isMainnet: false,
          integratedData: generated_address.NativeXelisDataElement.fields(
            fields: [
              generated_address.NativeXelisDataField(
                key:
                    const generated_address.NativeXelisDataValue.unsignedInteger(
                      integerType:
                          generated_address.NativeXelisUnsignedIntegerType.u8,
                      decimalValue: '7',
                    ),
                value: generated_address.NativeXelisDataElement.array(
                  values: [
                    const generated_address.NativeXelisDataElement.value(
                      value:
                          generated_address
                              .NativeXelisDataValue.unsignedInteger(
                            integerType: generated_address
                                .NativeXelisUnsignedIntegerType
                                .u128,
                            decimalValue:
                                '340282366920938463463374607431768211455',
                          ),
                    ),
                    generated_address.NativeXelisDataElement.value(
                      value: generated_address.NativeXelisDataValue.blobValue(
                        bytes: Uint8List.fromList([0, 1, 255]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    expect(descriptor.encodedAddress, 'integrated');
    expect(descriptor.baseAddress, 'base');
    expect(descriptor.isMainnet, isFalse);
    expect(descriptor.isIntegrated, isTrue);

    final fields = descriptor.integratedData! as XelisDataFields;
    final key = fields.fields.single.key as XelisDataUnsigned;
    expect(key.type, XelisUnsignedIntegerType.u8);
    expect(key.value, BigInt.from(7));
    final array = fields.fields.single.value as XelisDataArray;
    final maximum = (array.values.first as XelisDataValueElement).value;
    expect(maximum, isA<XelisDataUnsigned>());
    expect(
      (maximum as XelisDataUnsigned).value,
      XelisUnsignedIntegerType.u128.maximum,
    );
    expect(
      ((array.values.last as XelisDataValueElement).value as XelisDataBlob)
          .bytes,
      [0, 1, 255],
    );
  });

  test(
    'creates the generated integrated-address wire without numeric loss',
    () {
      final data = XelisDataElement.fields([
        XelisDataField(
          key: const XelisDataValue.string('payment_id'),
          value: XelisDataElement.value(
            XelisDataValue.unsigned(
              type: XelisUnsignedIntegerType.u64,
              value: XelisUnsignedIntegerType.u64.maximum,
            ),
          ),
        ),
      ]);

      final descriptor = makeXelisIntegratedAddress(
        baseAddress: 'base',
        integratedData: data,
        maker: ({required baseAddress, required integratedData}) {
          expect(baseAddress, 'base');
          final fields =
              integratedData as generated_address.NativeXelisDataElement_Fields;
          final value =
              fields.fields.single.value
                  as generated_address.NativeXelisDataElement_Value;
          final unsigned =
              value.value
                  as generated_address.NativeXelisDataValue_UnsignedInteger;
          expect(
            unsigned.integerType,
            generated_address.NativeXelisUnsignedIntegerType.u64,
          );
          expect(unsigned.decimalValue, '18446744073709551615');

          return generated_address.NativeXelisAddressDescriptor(
            encodedAddress: 'integrated',
            baseAddress: baseAddress,
            isMainnet: true,
            integratedData: integratedData,
          );
        },
      );

      expect(descriptor.encodedAddress, 'integrated');
      expect(descriptor.baseAddress, 'base');
      expect(descriptor.isMainnet, isTrue);
      expect(descriptor.integratedData, data);
    },
  );

  test(
    'assigns stable operations to parse and integrated creation failures',
    () {
      const nativeError = generated_error.NativeXelisError(
        version: XelisWalletErrorContract.currentVersion,
        source: generated_error.NativeXelisErrorSource.xelisCommon,
        code: generated_error.NativeXelisErrorCode.invalidInput,
        nativeKind: 'ADDRESS_INVALID',
        diagnosticMessage: 'invalid address',
      );

      expect(
        () => parseXelisAddress(
          address: 'invalid',
          parser: ({required address}) => throw nativeError,
        ),
        throwsA(
          isA<XelisWalletOperationException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.addressParse,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              ),
        ),
      );

      expect(
        () => makeXelisIntegratedAddress(
          baseAddress: 'invalid',
          integratedData: const XelisDataElement.value(
            XelisDataValue.boolean(true),
          ),
          maker: ({required baseAddress, required integratedData}) =>
              throw nativeError,
        ),
        throwsA(
          isA<XelisWalletOperationException>().having(
            (error) => error.operation,
            'operation',
            XelisWalletOperation.addressIntegratedCreate,
          ),
        ),
      );
    },
  );

  test('classifies malformed typed address wire as a bridge failure', () {
    expect(
      () => parseXelisAddress(
        address: 'integrated',
        parser: ({required address}) =>
            const generated_address.NativeXelisAddressDescriptor(
              encodedAddress: 'integrated',
              baseAddress: 'base',
              isMainnet: false,
              integratedData: generated_address.NativeXelisDataElement.value(
                value: generated_address.NativeXelisDataValue.unsignedInteger(
                  integerType:
                      generated_address.NativeXelisUnsignedIntegerType.u128,
                  decimalValue: 'not-an-integer',
                ),
              ),
            ),
      ),
      throwsA(
        isA<XelisWalletBridgeException>()
            .having(
              (error) => error.operation,
              'operation',
              XelisWalletOperation.addressParse,
            )
            .having(
              (error) => error.code,
              'code',
              XelisWalletErrorCode.bridgeFailure,
            )
            .having(
              (error) => error.nativeKind,
              'nativeKind',
              'ADDRESS_DESCRIPTOR_PAYLOAD_INVALID',
            ),
      ),
    );
  });

  test('maps precomputed table check and update operations', () async {
    const type = XelisPrecomputedTableType.custom(16);

    final available = await checkXelisPrecomputedTables(
      path: 'tables',
      type: type,
      checker:
          ({
            required precomputedTablesPath,
            required precomputedTableType,
          }) async {
            expect(precomputedTablesPath, 'tables');
            expect(precomputedTableType.toString(), contains('custom'));
            return true;
          },
    );
    expect(available, isTrue);

    await expectLater(
      updateXelisPrecomputedTables(
        path: 'tables',
        type: const XelisPrecomputedTableType.custom(32),
        updater:
            ({
              required precomputedTablesPath,
              required precomputedTableType,
            }) async {
              throw const generated_error.NativeXelisError(
                version: XelisWalletErrorContract.currentVersion,
                source: generated_error.NativeXelisErrorSource.xelisWallet,
                code: generated_error.NativeXelisErrorCode.storage,
                nativeKind: 'PRECOMPUTED_TABLES_UPDATE_FAILED',
                diagnosticMessage: 'disk error',
              );
            },
      ),
      throwsA(
        isA<XelisWalletOperationException>()
            .having(
              (error) => error.operation,
              'operation',
              XelisWalletOperation.precomputedTablesUpdate,
            )
            .having(
              (error) => error.code,
              'code',
              XelisWalletErrorCode.storageFailure,
            ),
      ),
    );
  });
}
