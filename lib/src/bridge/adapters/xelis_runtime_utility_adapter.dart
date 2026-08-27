import 'dart:typed_data';

import '../../api/address/xelis_address_descriptor.dart';
import '../../api/data/xelis_data_element.dart';
import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/models/xelis_network.dart';
import '../../api/precomputed/xelis_precomputed_table_type.dart';
import '../../generated/rust_bridge/api/models/address_dtos.dart'
    as generated_address;
import '../../generated/rust_bridge/api/models/network.dart'
    as generated_network;
import '../../generated/rust_bridge/api/precomputed_tables.dart'
    as generated_precomputed;
import '../../generated/rust_bridge/api/utils.dart' as generated_utils;
import '../../generated/rust_bridge/api/wallet.dart' as generated_wallet;
import 'xelis_error_adapter.dart';
import 'xelis_network_adapter.dart';
import 'xelis_precomputed_table_type_adapter.dart';

typedef GeneratedAddressValidator = bool Function({
  required String strAddress,
  required generated_network.Network network,
});
typedef GeneratedAddressParser =
    generated_address.NativeXelisAddressDescriptor Function({
      required String address,
    });
typedef GeneratedIntegratedAddressMaker =
    generated_address.NativeXelisAddressDescriptor Function({
      required String baseAddress,
      required generated_address.NativeXelisDataElement integratedData,
    });
typedef GeneratedPrecomputedTablesChecker = Future<bool> Function({
  required String precomputedTablesPath,
  required generated_precomputed.PrecomputedTableType precomputedTableType,
});
typedef GeneratedPrecomputedTablesUpdater = Future<void> Function({
  required String precomputedTablesPath,
  required generated_precomputed.PrecomputedTableType precomputedTableType,
});

bool validateXelisAddress({
  required String address,
  required XelisNetwork network,
  GeneratedAddressValidator validator = generated_utils.isAddressValid,
}) => guardXelisCall(
  () => validator(
    strAddress: address,
    network: generatedNetworkFromXelis(network),
  ),
  boundary: const XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisCommon,
    operation: XelisWalletOperation.addressValidate,
  ),
);

XelisAddressDescriptor parseXelisAddress({
  required String address,
  GeneratedAddressParser parser = generated_utils.parseAddress,
}) {
  final generated = guardXelisCall(
    () => parser(address: address),
    boundary: const XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisCommon,
      operation: XelisWalletOperation.addressParse,
    ),
  );
  return _xelisAddressDescriptorFromGeneratedForOperation(
    generated,
    operation: XelisWalletOperation.addressParse,
  );
}

XelisAddressDescriptor makeXelisIntegratedAddress({
  required String baseAddress,
  required XelisDataElement integratedData,
  GeneratedIntegratedAddressMaker maker = generated_utils.makeIntegratedAddress,
}) {
  final generated = guardXelisCall(
    () => maker(
      baseAddress: baseAddress,
      integratedData: generatedDataElementFromXelis(integratedData),
    ),
    boundary: const XelisErrorBoundary(
      source: XelisWalletErrorSource.xelisCommon,
      operation: XelisWalletOperation.addressIntegratedCreate,
    ),
  );
  return _xelisAddressDescriptorFromGeneratedForOperation(
    generated,
    operation: XelisWalletOperation.addressIntegratedCreate,
  );
}

XelisAddressDescriptor _xelisAddressDescriptorFromGeneratedForOperation(
  generated_address.NativeXelisAddressDescriptor descriptor, {
  required XelisWalletOperation operation,
}) {
  try {
    return xelisAddressDescriptorFromGenerated(descriptor);
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      xelisBridgeContractException(
        operation: operation,
        nativeKind: 'ADDRESS_DESCRIPTOR_PAYLOAD_INVALID',
        diagnosticMessage: error.toString(),
      ),
      stackTrace,
    );
  }
}

XelisAddressDescriptor xelisAddressDescriptorFromGenerated(
  generated_address.NativeXelisAddressDescriptor descriptor,
) => XelisAddressDescriptor(
  encodedAddress: descriptor.encodedAddress,
  baseAddress: descriptor.baseAddress,
  networkClass: descriptor.isMainnet
      ? XelisAddressNetworkClass.mainnet
      : XelisAddressNetworkClass.nonMainnet,
  integratedData: descriptor.integratedData == null
      ? null
      : xelisDataElementFromGenerated(descriptor.integratedData!),
);

XelisDataElement xelisDataElementFromGenerated(
  generated_address.NativeXelisDataElement element,
) => switch (element) {
  generated_address.NativeXelisDataElement_Value(:final value) =>
    XelisDataElement.value(xelisDataValueFromGenerated(value)),
  generated_address.NativeXelisDataElement_Array(:final values) =>
    XelisDataElement.array(values.map(xelisDataElementFromGenerated)),
  generated_address.NativeXelisDataElement_Fields(:final fields) =>
    XelisDataElement.fields(
      fields.map(
        (field) => XelisDataField(
          key: xelisDataValueFromGenerated(field.key),
          value: xelisDataElementFromGenerated(field.value),
        ),
      ),
    ),
};

XelisDataValue xelisDataValueFromGenerated(
  generated_address.NativeXelisDataValue value,
) => switch (value) {
  generated_address.NativeXelisDataValue_BoolValue(:final value) =>
    XelisDataValue.boolean(value),
  generated_address.NativeXelisDataValue_StringValue(:final value) =>
    XelisDataValue.string(value),
  generated_address.NativeXelisDataValue_UnsignedInteger(
    :final integerType,
    :final decimalValue,
  ) =>
    XelisDataValue.unsigned(
      type: xelisUnsignedIntegerTypeFromGenerated(integerType),
      value: BigInt.parse(decimalValue),
    ),
  generated_address.NativeXelisDataValue_HashValue(:final hexValue) =>
    XelisDataValue.hash(hexValue),
  generated_address.NativeXelisDataValue_BlobValue(:final bytes) =>
    XelisDataValue.blob(bytes),
};

generated_address.NativeXelisDataElement generatedDataElementFromXelis(
  XelisDataElement element,
) => switch (element) {
  XelisDataValueElement(:final value) =>
    generated_address.NativeXelisDataElement.value(
      value: generatedDataValueFromXelis(value),
    ),
  XelisDataArray(:final values) =>
    generated_address.NativeXelisDataElement.array(
      values: values.map(generatedDataElementFromXelis).toList(),
    ),
  XelisDataFields(:final fields) =>
    generated_address.NativeXelisDataElement.fields(
      fields: fields
          .map(
            (field) => generated_address.NativeXelisDataField(
              key: generatedDataValueFromXelis(field.key),
              value: generatedDataElementFromXelis(field.value),
            ),
          )
          .toList(),
    ),
};

generated_address.NativeXelisDataValue generatedDataValueFromXelis(
  XelisDataValue value,
) => switch (value) {
  XelisDataBool(:final value) =>
    generated_address.NativeXelisDataValue.boolValue(value: value),
  XelisDataString(:final value) =>
    generated_address.NativeXelisDataValue.stringValue(value: value),
  XelisDataUnsigned(:final type, :final value) =>
    generated_address.NativeXelisDataValue.unsignedInteger(
      integerType: generatedUnsignedIntegerTypeFromXelis(type),
      decimalValue: value.toString(),
    ),
  XelisDataHash(:final hex) => generated_address.NativeXelisDataValue.hashValue(
    hexValue: hex,
  ),
  XelisDataBlob(:final bytes) =>
    generated_address.NativeXelisDataValue.blobValue(
      bytes: Uint8List.fromList(bytes),
    ),
};

XelisUnsignedIntegerType xelisUnsignedIntegerTypeFromGenerated(
  generated_address.NativeXelisUnsignedIntegerType type,
) => switch (type) {
  generated_address.NativeXelisUnsignedIntegerType.u8 =>
    XelisUnsignedIntegerType.u8,
  generated_address.NativeXelisUnsignedIntegerType.u16 =>
    XelisUnsignedIntegerType.u16,
  generated_address.NativeXelisUnsignedIntegerType.u32 =>
    XelisUnsignedIntegerType.u32,
  generated_address.NativeXelisUnsignedIntegerType.u64 =>
    XelisUnsignedIntegerType.u64,
  generated_address.NativeXelisUnsignedIntegerType.u128 =>
    XelisUnsignedIntegerType.u128,
};

generated_address.NativeXelisUnsignedIntegerType
generatedUnsignedIntegerTypeFromXelis(XelisUnsignedIntegerType type) =>
    switch (type) {
      XelisUnsignedIntegerType.u8 =>
        generated_address.NativeXelisUnsignedIntegerType.u8,
      XelisUnsignedIntegerType.u16 =>
        generated_address.NativeXelisUnsignedIntegerType.u16,
      XelisUnsignedIntegerType.u32 =>
        generated_address.NativeXelisUnsignedIntegerType.u32,
      XelisUnsignedIntegerType.u64 =>
        generated_address.NativeXelisUnsignedIntegerType.u64,
      XelisUnsignedIntegerType.u128 =>
        generated_address.NativeXelisUnsignedIntegerType.u128,
    };

Future<bool> checkXelisPrecomputedTables({
  required String path,
  required XelisPrecomputedTableType type,
  GeneratedPrecomputedTablesChecker checker =
      generated_precomputed.arePrecomputedTablesAvailable,
}) => guardXelisFuture(
  () => checker(
    precomputedTablesPath: path,
    precomputedTableType: generatedPrecomputedTableTypeFromXelis(type),
  ),
  boundary: const XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWallet,
    operation: XelisWalletOperation.precomputedTablesCheck,
  ),
);

Future<void> updateXelisPrecomputedTables({
  required String path,
  required XelisPrecomputedTableType type,
  GeneratedPrecomputedTablesUpdater updater = generated_wallet.updateTables,
}) => guardXelisFuture(
  () => updater(
    precomputedTablesPath: path,
    precomputedTableType: generatedPrecomputedTableTypeFromXelis(type),
  ),
  boundary: const XelisErrorBoundary(
    source: XelisWalletErrorSource.xelisWallet,
    operation: XelisWalletOperation.precomputedTablesUpdate,
  ),
);
