import 'dart:collection';

/// Lossless, immutable representation of a XELIS integrated-data element.
///
/// The native protocol distinguishes value kinds and unsigned integer widths.
/// This authored model preserves that information instead of exposing the
/// ambiguous, untagged JSON representation used by some upstream RPC methods.
sealed class XelisDataElement {
  const XelisDataElement();

  const factory XelisDataElement.value(XelisDataValue value) =
      XelisDataValueElement;

  factory XelisDataElement.array(Iterable<XelisDataElement> values) =
      XelisDataArray;

  factory XelisDataElement.fields(Iterable<XelisDataField> fields) =
      XelisDataFields;
}

/// A single typed protocol value.
final class XelisDataValueElement extends XelisDataElement {
  const XelisDataValueElement(this.value);

  final XelisDataValue value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataValueElement && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Ordered array of nested data elements.
final class XelisDataArray extends XelisDataElement {
  XelisDataArray(Iterable<XelisDataElement> values)
    : values = UnmodifiableListView(_validateCollection(values, 'array'));

  final List<XelisDataElement> values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataArray && _listEquals(values, other.values);

  @override
  int get hashCode => Object.hashAll(values);
}

/// Ordered collection of typed key/value fields.
///
/// Keys are [XelisDataValue] rather than strings because that is what the
/// native XELIS protocol supports. Field order is preserved.
final class XelisDataFields extends XelisDataElement {
  XelisDataFields(Iterable<XelisDataField> fields)
    : fields = UnmodifiableListView(_validateFields(fields));

  final List<XelisDataField> fields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataFields && _listEquals(fields, other.fields);

  @override
  int get hashCode => Object.hashAll(fields);
}

/// One ordered entry in [XelisDataFields].
final class XelisDataField {
  const XelisDataField({required this.key, required this.value});

  final XelisDataValue key;
  final XelisDataElement value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataField && key == other.key && value == other.value;

  @override
  int get hashCode => Object.hash(key, value);
}

/// A typed scalar that can be used as a value or a field key.
sealed class XelisDataValue {
  const XelisDataValue();

  const factory XelisDataValue.boolean(bool value) = XelisDataBool;

  const factory XelisDataValue.string(String value) = XelisDataString;

  factory XelisDataValue.unsigned({
    required XelisUnsignedIntegerType type,
    required BigInt value,
  }) = XelisDataUnsigned;

  factory XelisDataValue.hash(String hex) = XelisDataHash;

  factory XelisDataValue.blob(Iterable<int> bytes) = XelisDataBlob;
}

final class XelisDataBool extends XelisDataValue {
  const XelisDataBool(this.value);

  final bool value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XelisDataBool && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class XelisDataString extends XelisDataValue {
  const XelisDataString(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataString && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Exact unsigned integer value with its protocol width.
final class XelisDataUnsigned extends XelisDataValue {
  XelisDataUnsigned({required this.type, required BigInt value})
    : value = _validateUnsigned(type, value);

  final XelisUnsignedIntegerType type;
  final BigInt value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataUnsigned && type == other.type && value == other.value;

  @override
  int get hashCode => Object.hash(type, value);
}

/// A 32-byte hash represented by canonical lower-case hexadecimal text.
final class XelisDataHash extends XelisDataValue {
  XelisDataHash(String hex) : hex = _normalizeHash(hex);

  final String hex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XelisDataHash && hex == other.hex;

  @override
  int get hashCode => hex.hashCode;
}

/// Binary protocol value copied into an immutable list.
final class XelisDataBlob extends XelisDataValue {
  XelisDataBlob(Iterable<int> bytes)
    : bytes = UnmodifiableListView(_validateBlob(bytes));

  final List<int> bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisDataBlob && _listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);
}

enum XelisUnsignedIntegerType {
  u8,
  u16,
  u32,
  u64,
  u128;

  BigInt get maximum => switch (this) {
    u8 => BigInt.from(255),
    u16 => BigInt.from(65535),
    u32 => BigInt.parse('4294967295'),
    u64 => BigInt.parse('18446744073709551615'),
    u128 => BigInt.parse('340282366920938463463374607431768211455'),
  };
}

const _collectionLimit = 255;
const _blobLimit = 65535;
final _hashPattern = RegExp(r'^[0-9a-fA-F]{64}$');

List<XelisDataElement> _validateCollection(
  Iterable<XelisDataElement> source,
  String name,
) {
  final values = List<XelisDataElement>.of(source);
  if (values.length > _collectionLimit) {
    throw RangeError.range(
      values.length,
      0,
      _collectionLimit,
      name,
      'XELIS data-element collections contain at most $_collectionLimit entries',
    );
  }
  return values;
}

List<XelisDataField> _validateFields(Iterable<XelisDataField> source) {
  final fields = List<XelisDataField>.of(source);
  if (fields.length > _collectionLimit) {
    throw RangeError.range(
      fields.length,
      0,
      _collectionLimit,
      'fields',
      'XELIS data-element collections contain at most $_collectionLimit entries',
    );
  }

  final keys = <XelisDataValue>{};
  for (final field in fields) {
    if (!keys.add(field.key)) {
      throw ArgumentError.value(
        '<redacted>',
        'fields',
        'XELIS data-element field keys must be unique',
      );
    }
  }
  return fields;
}

BigInt _validateUnsigned(XelisUnsignedIntegerType type, BigInt value) {
  if (value.isNegative || value > type.maximum) {
    throw ArgumentError.value(
      value,
      'value',
      'Value does not fit the declared ${type.name} width',
    );
  }
  return value;
}

String _normalizeHash(String hex) {
  if (!_hashPattern.hasMatch(hex)) {
    throw FormatException(
      'A XELIS data hash must contain exactly 64 hex digits',
    );
  }
  return hex.toLowerCase();
}

List<int> _validateBlob(Iterable<int> source) {
  final bytes = List<int>.of(source);
  if (bytes.length > _blobLimit) {
    throw RangeError.range(
      bytes.length,
      0,
      _blobLimit,
      'bytes',
      'A XELIS data blob contains at most $_blobLimit bytes',
    );
  }
  for (final byte in bytes) {
    if (byte < 0 || byte > 255) {
      throw RangeError.range(byte, 0, 255, 'byte');
    }
  }
  return bytes;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
