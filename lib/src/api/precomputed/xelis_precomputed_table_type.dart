/// Kind of precomputed discrete-log table used by the native wallet.
enum XelisPrecomputedTableKind { l1Low, l1Medium, l1Full, custom }

/// Authored configuration for the native wallet's precomputed tables.
///
/// A custom value is the exact L1 size accepted by `xelis-wallet`, currently
/// from 16 through 32 inclusive. Native validation remains authoritative.
final class XelisPrecomputedTableType {
  const XelisPrecomputedTableType.l1Low()
    : kind = XelisPrecomputedTableKind.l1Low,
      customSize = null;

  const XelisPrecomputedTableType.l1Medium()
    : kind = XelisPrecomputedTableKind.l1Medium,
      customSize = null;

  const XelisPrecomputedTableType.l1Full()
    : kind = XelisPrecomputedTableKind.l1Full,
      customSize = null;

  const XelisPrecomputedTableType.custom(int size)
    : kind = XelisPrecomputedTableKind.custom,
      customSize = size,
      assert(size >= 16 && size <= 32);

  final XelisPrecomputedTableKind kind;
  final int? customSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisPrecomputedTableType &&
          other.kind == kind &&
          other.customSize == customSize;

  @override
  int get hashCode => Object.hash(kind, customSize);

  @override
  String toString() => switch (kind) {
    XelisPrecomputedTableKind.l1Low => 'XelisPrecomputedTableType.l1Low()',
    XelisPrecomputedTableKind.l1Medium =>
      'XelisPrecomputedTableType.l1Medium()',
    XelisPrecomputedTableKind.l1Full => 'XelisPrecomputedTableType.l1Full()',
    XelisPrecomputedTableKind.custom =>
      'XelisPrecomputedTableType.custom($customSize)',
  };
}
