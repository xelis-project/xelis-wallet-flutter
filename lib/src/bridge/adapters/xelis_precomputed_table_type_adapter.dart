import '../../api/precomputed/xelis_precomputed_table_type.dart';
import '../../generated/rust_bridge/api/precomputed_tables.dart' as generated;

generated.PrecomputedTableType generatedPrecomputedTableTypeFromXelis(
  XelisPrecomputedTableType type,
) => switch (type.kind) {
  XelisPrecomputedTableKind.l1Low =>
    const generated.PrecomputedTableType.l1Low(),
  XelisPrecomputedTableKind.l1Medium =>
    const generated.PrecomputedTableType.l1Medium(),
  XelisPrecomputedTableKind.l1Full =>
    const generated.PrecomputedTableType.l1Full(),
  XelisPrecomputedTableKind.custom => generated.PrecomputedTableType.custom(
    BigInt.from(type.customSize!),
  ),
};

XelisPrecomputedTableType xelisPrecomputedTableTypeFromGenerated(
  generated.PrecomputedTableType type,
) => switch (type) {
  generated.PrecomputedTableType_L1Low() =>
    const XelisPrecomputedTableType.l1Low(),
  generated.PrecomputedTableType_L1Medium() =>
    const XelisPrecomputedTableType.l1Medium(),
  generated.PrecomputedTableType_L1Full() =>
    const XelisPrecomputedTableType.l1Full(),
  generated.PrecomputedTableType_Custom(:final field0) =>
    XelisPrecomputedTableType.custom(field0.toInt()),
};
