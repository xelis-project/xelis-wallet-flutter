/// Lossless asset payload owned by the stable wallet package API.
///
/// [assetHash] is canonical hexadecimal text, [topoheight] is the topological
/// height at which this metadata applies, and all supply amounts are expressed
/// in the asset's atomic units.
final class XelisWalletAsset {
  const XelisWalletAsset({
    required this.assetHash,
    required this.topoheight,
    required this.metadata,
  });

  final String assetHash;
  final BigInt topoheight;
  final XelisWalletAssetMetadata metadata;
}

/// Human-readable metadata and supply/ownership policy for an asset.
final class XelisWalletAssetMetadata {
  const XelisWalletAssetMetadata({
    required this.name,
    required this.ticker,
    required this.decimals,
    required this.maxSupply,
    required this.owner,
  });

  final String name;
  final String ticker;

  /// Decimal precision used to render atomic asset amounts.
  final int decimals;

  /// Maximum-supply policy; finite amounts are expressed in atomic units.
  final XelisWalletMaxSupply maxSupply;

  /// Ownership state reported by XELIS.
  ///
  /// Absence of an active owner is represented explicitly by
  /// [XelisWalletNoAssetOwner], never by `null`.
  final XelisWalletAssetOwner owner;
}

/// Maximum-supply policy reported by the native wallet.
sealed class XelisWalletMaxSupply {
  const XelisWalletMaxSupply();
}

/// Asset with no fixed maximum supply.
final class XelisWalletNoMaxSupply extends XelisWalletMaxSupply {
  const XelisWalletNoMaxSupply();
}

/// Asset with a fixed maximum supply in atomic units.
final class XelisWalletFixedMaxSupply extends XelisWalletMaxSupply {
  const XelisWalletFixedMaxSupply({required this.amount});

  final BigInt amount;
}

/// Mintable asset whose current maximum supply is in atomic units.
final class XelisWalletMintableMaxSupply extends XelisWalletMaxSupply {
  const XelisWalletMintableMaxSupply({required this.amount});

  final BigInt amount;
}

/// Exhaustive asset-ownership state reported by XELIS.
sealed class XelisWalletAssetOwner {
  const XelisWalletAssetOwner();
}

/// Native asset or asset whose active creator link no longer exists.
final class XelisWalletNoAssetOwner extends XelisWalletAssetOwner {
  const XelisWalletNoAssetOwner();
}

/// Asset still owned by its creating contract.
final class XelisWalletAssetCreator extends XelisWalletAssetOwner {
  const XelisWalletAssetCreator({required this.contract, required this.id});

  /// Canonical hexadecimal contract hash.
  final String contract;

  /// Creator-defined asset identifier.
  final BigInt id;
}

/// Asset transferred to a current owner public key.
final class XelisWalletCurrentAssetOwner extends XelisWalletAssetOwner {
  const XelisWalletCurrentAssetOwner({
    required this.origin,
    required this.originId,
    required this.owner,
  });

  /// Canonical hexadecimal origin contract hash.
  final String origin;

  /// Origin-defined asset identifier.
  final BigInt originId;

  /// Canonical hexadecimal public key of the current owner.
  final String owner;
}
