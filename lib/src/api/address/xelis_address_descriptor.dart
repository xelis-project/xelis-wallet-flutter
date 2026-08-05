import '../data/xelis_data_element.dart';

/// Network information encoded directly in a XELIS address.
///
/// The address format distinguishes mainnet from every non-mainnet network; it
/// cannot by itself distinguish testnet, devnet, and stagenet.
enum XelisAddressNetworkClass { mainnet, nonMainnet }

/// Stable, lossless description of a standard or integrated XELIS address.
final class XelisAddressDescriptor {
  const XelisAddressDescriptor({
    required this.encodedAddress,
    required this.baseAddress,
    required this.networkClass,
    required this.integratedData,
  });

  /// Complete address to use as a transaction destination.
  final String encodedAddress;

  /// Normal address for the same public key, without integrated data.
  final String baseAddress;

  /// Network class encoded in the address prefix.
  final XelisAddressNetworkClass networkClass;

  /// Exact typed integrated data, or `null` for a standard address.
  final XelisDataElement? integratedData;

  bool get isIntegrated => integratedData != null;

  bool get isMainnet => networkClass == XelisAddressNetworkClass.mainnet;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisAddressDescriptor &&
          encodedAddress == other.encodedAddress &&
          baseAddress == other.baseAddress &&
          networkClass == other.networkClass &&
          integratedData == other.integratedData;

  @override
  int get hashCode =>
      Object.hash(encodedAddress, baseAddress, networkClass, integratedData);
}
