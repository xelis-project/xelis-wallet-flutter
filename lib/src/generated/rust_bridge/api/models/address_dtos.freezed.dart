// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NativeXelisAddressDescriptor {

 String get encodedAddress; String get baseAddress; bool get isMainnet; NativeXelisDataElement? get integratedData;
/// Create a copy of NativeXelisAddressDescriptor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisAddressDescriptorCopyWith<NativeXelisAddressDescriptor> get copyWith => _$NativeXelisAddressDescriptorCopyWithImpl<NativeXelisAddressDescriptor>(this as NativeXelisAddressDescriptor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisAddressDescriptor&&(identical(other.encodedAddress, encodedAddress) || other.encodedAddress == encodedAddress)&&(identical(other.baseAddress, baseAddress) || other.baseAddress == baseAddress)&&(identical(other.isMainnet, isMainnet) || other.isMainnet == isMainnet)&&(identical(other.integratedData, integratedData) || other.integratedData == integratedData));
}


@override
int get hashCode => Object.hash(runtimeType,encodedAddress,baseAddress,isMainnet,integratedData);

@override
String toString() {
  return 'NativeXelisAddressDescriptor(encodedAddress: $encodedAddress, baseAddress: $baseAddress, isMainnet: $isMainnet, integratedData: $integratedData)';
}


}

/// @nodoc
abstract mixin class $NativeXelisAddressDescriptorCopyWith<$Res>  {
  factory $NativeXelisAddressDescriptorCopyWith(NativeXelisAddressDescriptor value, $Res Function(NativeXelisAddressDescriptor) _then) = _$NativeXelisAddressDescriptorCopyWithImpl;
@useResult
$Res call({
 String encodedAddress, String baseAddress, bool isMainnet, NativeXelisDataElement? integratedData
});


$NativeXelisDataElementCopyWith<$Res>? get integratedData;

}
/// @nodoc
class _$NativeXelisAddressDescriptorCopyWithImpl<$Res>
    implements $NativeXelisAddressDescriptorCopyWith<$Res> {
  _$NativeXelisAddressDescriptorCopyWithImpl(this._self, this._then);

  final NativeXelisAddressDescriptor _self;
  final $Res Function(NativeXelisAddressDescriptor) _then;

/// Create a copy of NativeXelisAddressDescriptor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? encodedAddress = null,Object? baseAddress = null,Object? isMainnet = null,Object? integratedData = freezed,}) {
  return _then(NativeXelisAddressDescriptor(
encodedAddress: null == encodedAddress ? _self.encodedAddress : encodedAddress // ignore: cast_nullable_to_non_nullable
as String,baseAddress: null == baseAddress ? _self.baseAddress : baseAddress // ignore: cast_nullable_to_non_nullable
as String,isMainnet: null == isMainnet ? _self.isMainnet : isMainnet // ignore: cast_nullable_to_non_nullable
as bool,integratedData: freezed == integratedData ? _self.integratedData : integratedData // ignore: cast_nullable_to_non_nullable
as NativeXelisDataElement?,
  ));
}
/// Create a copy of NativeXelisAddressDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataElementCopyWith<$Res>? get integratedData {
    if (_self.integratedData == null) {
    return null;
  }

  return $NativeXelisDataElementCopyWith<$Res>(_self.integratedData!, (value) {
    return _then(_self.copyWith(integratedData: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeXelisAddressDescriptor].
extension NativeXelisAddressDescriptorPatterns on NativeXelisAddressDescriptor {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeXelisAddressDescriptor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeXelisAddressDescriptor() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeXelisAddressDescriptor value)  $default,){
final _that = this;
switch (_that) {
case _NativeXelisAddressDescriptor():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeXelisAddressDescriptor value)?  $default,){
final _that = this;
switch (_that) {
case _NativeXelisAddressDescriptor() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String encodedAddress,  String baseAddress,  bool isMainnet,  NativeXelisDataElement? integratedData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeXelisAddressDescriptor() when $default != null:
return $default(_that.encodedAddress,_that.baseAddress,_that.isMainnet,_that.integratedData);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String encodedAddress,  String baseAddress,  bool isMainnet,  NativeXelisDataElement? integratedData)  $default,) {final _that = this;
switch (_that) {
case _NativeXelisAddressDescriptor():
return $default(_that.encodedAddress,_that.baseAddress,_that.isMainnet,_that.integratedData);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String encodedAddress,  String baseAddress,  bool isMainnet,  NativeXelisDataElement? integratedData)?  $default,) {final _that = this;
switch (_that) {
case _NativeXelisAddressDescriptor() when $default != null:
return $default(_that.encodedAddress,_that.baseAddress,_that.isMainnet,_that.integratedData);case _:
  return null;

}
}

}

/// @nodoc


class _NativeXelisAddressDescriptor implements NativeXelisAddressDescriptor {
  const _NativeXelisAddressDescriptor({required this.encodedAddress, required this.baseAddress, required this.isMainnet, this.integratedData});
  

@override final  String encodedAddress;
@override final  String baseAddress;
@override final  bool isMainnet;
@override final  NativeXelisDataElement? integratedData;

/// Create a copy of NativeXelisAddressDescriptor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeXelisAddressDescriptorCopyWith<_NativeXelisAddressDescriptor> get copyWith => __$NativeXelisAddressDescriptorCopyWithImpl<_NativeXelisAddressDescriptor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeXelisAddressDescriptor&&(identical(other.encodedAddress, encodedAddress) || other.encodedAddress == encodedAddress)&&(identical(other.baseAddress, baseAddress) || other.baseAddress == baseAddress)&&(identical(other.isMainnet, isMainnet) || other.isMainnet == isMainnet)&&(identical(other.integratedData, integratedData) || other.integratedData == integratedData));
}


@override
int get hashCode => Object.hash(runtimeType,encodedAddress,baseAddress,isMainnet,integratedData);

@override
String toString() {
  return 'NativeXelisAddressDescriptor(encodedAddress: $encodedAddress, baseAddress: $baseAddress, isMainnet: $isMainnet, integratedData: $integratedData)';
}


}

/// @nodoc
abstract mixin class _$NativeXelisAddressDescriptorCopyWith<$Res> implements $NativeXelisAddressDescriptorCopyWith<$Res> {
  factory _$NativeXelisAddressDescriptorCopyWith(_NativeXelisAddressDescriptor value, $Res Function(_NativeXelisAddressDescriptor) _then) = __$NativeXelisAddressDescriptorCopyWithImpl;
@override @useResult
$Res call({
 String encodedAddress, String baseAddress, bool isMainnet, NativeXelisDataElement? integratedData
});


@override $NativeXelisDataElementCopyWith<$Res>? get integratedData;

}
/// @nodoc
class __$NativeXelisAddressDescriptorCopyWithImpl<$Res>
    implements _$NativeXelisAddressDescriptorCopyWith<$Res> {
  __$NativeXelisAddressDescriptorCopyWithImpl(this._self, this._then);

  final _NativeXelisAddressDescriptor _self;
  final $Res Function(_NativeXelisAddressDescriptor) _then;

/// Create a copy of NativeXelisAddressDescriptor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? encodedAddress = null,Object? baseAddress = null,Object? isMainnet = null,Object? integratedData = freezed,}) {
  return _then(_NativeXelisAddressDescriptor(
encodedAddress: null == encodedAddress ? _self.encodedAddress : encodedAddress // ignore: cast_nullable_to_non_nullable
as String,baseAddress: null == baseAddress ? _self.baseAddress : baseAddress // ignore: cast_nullable_to_non_nullable
as String,isMainnet: null == isMainnet ? _self.isMainnet : isMainnet // ignore: cast_nullable_to_non_nullable
as bool,integratedData: freezed == integratedData ? _self.integratedData : integratedData // ignore: cast_nullable_to_non_nullable
as NativeXelisDataElement?,
  ));
}

/// Create a copy of NativeXelisAddressDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataElementCopyWith<$Res>? get integratedData {
    if (_self.integratedData == null) {
    return null;
  }

  return $NativeXelisDataElementCopyWith<$Res>(_self.integratedData!, (value) {
    return _then(_self.copyWith(integratedData: value));
  });
}
}

/// @nodoc
mixin _$NativeXelisDataElement {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataElement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeXelisDataElement()';
}


}

/// @nodoc
class $NativeXelisDataElementCopyWith<$Res>  {
$NativeXelisDataElementCopyWith(NativeXelisDataElement _, $Res Function(NativeXelisDataElement) __);
}


/// Adds pattern-matching-related methods to [NativeXelisDataElement].
extension NativeXelisDataElementPatterns on NativeXelisDataElement {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativeXelisDataElement_Value value)?  value,TResult Function( NativeXelisDataElement_Array value)?  array,TResult Function( NativeXelisDataElement_Fields value)?  fields,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativeXelisDataElement_Value() when value != null:
return value(_that);case NativeXelisDataElement_Array() when array != null:
return array(_that);case NativeXelisDataElement_Fields() when fields != null:
return fields(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativeXelisDataElement_Value value)  value,required TResult Function( NativeXelisDataElement_Array value)  array,required TResult Function( NativeXelisDataElement_Fields value)  fields,}){
final _that = this;
switch (_that) {
case NativeXelisDataElement_Value():
return value(_that);case NativeXelisDataElement_Array():
return array(_that);case NativeXelisDataElement_Fields():
return fields(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativeXelisDataElement_Value value)?  value,TResult? Function( NativeXelisDataElement_Array value)?  array,TResult? Function( NativeXelisDataElement_Fields value)?  fields,}){
final _that = this;
switch (_that) {
case NativeXelisDataElement_Value() when value != null:
return value(_that);case NativeXelisDataElement_Array() when array != null:
return array(_that);case NativeXelisDataElement_Fields() when fields != null:
return fields(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( NativeXelisDataValue value)?  value,TResult Function( List<NativeXelisDataElement> values)?  array,TResult Function( List<NativeXelisDataField> fields)?  fields,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativeXelisDataElement_Value() when value != null:
return value(_that.value);case NativeXelisDataElement_Array() when array != null:
return array(_that.values);case NativeXelisDataElement_Fields() when fields != null:
return fields(_that.fields);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( NativeXelisDataValue value)  value,required TResult Function( List<NativeXelisDataElement> values)  array,required TResult Function( List<NativeXelisDataField> fields)  fields,}) {final _that = this;
switch (_that) {
case NativeXelisDataElement_Value():
return value(_that.value);case NativeXelisDataElement_Array():
return array(_that.values);case NativeXelisDataElement_Fields():
return fields(_that.fields);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( NativeXelisDataValue value)?  value,TResult? Function( List<NativeXelisDataElement> values)?  array,TResult? Function( List<NativeXelisDataField> fields)?  fields,}) {final _that = this;
switch (_that) {
case NativeXelisDataElement_Value() when value != null:
return value(_that.value);case NativeXelisDataElement_Array() when array != null:
return array(_that.values);case NativeXelisDataElement_Fields() when fields != null:
return fields(_that.fields);case _:
  return null;

}
}

}

/// @nodoc


class NativeXelisDataElement_Value extends NativeXelisDataElement {
  const NativeXelisDataElement_Value({required this.value}): super._();
  

 final  NativeXelisDataValue value;

/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataElement_ValueCopyWith<NativeXelisDataElement_Value> get copyWith => _$NativeXelisDataElement_ValueCopyWithImpl<NativeXelisDataElement_Value>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataElement_Value&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'NativeXelisDataElement.value(value: $value)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataElement_ValueCopyWith<$Res> implements $NativeXelisDataElementCopyWith<$Res> {
  factory $NativeXelisDataElement_ValueCopyWith(NativeXelisDataElement_Value value, $Res Function(NativeXelisDataElement_Value) _then) = _$NativeXelisDataElement_ValueCopyWithImpl;
@useResult
$Res call({
 NativeXelisDataValue value
});


$NativeXelisDataValueCopyWith<$Res> get value;

}
/// @nodoc
class _$NativeXelisDataElement_ValueCopyWithImpl<$Res>
    implements $NativeXelisDataElement_ValueCopyWith<$Res> {
  _$NativeXelisDataElement_ValueCopyWithImpl(this._self, this._then);

  final NativeXelisDataElement_Value _self;
  final $Res Function(NativeXelisDataElement_Value) _then;

/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(NativeXelisDataElement_Value(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as NativeXelisDataValue,
  ));
}

/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataValueCopyWith<$Res> get value {
  
  return $NativeXelisDataValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class NativeXelisDataElement_Array extends NativeXelisDataElement {
  const NativeXelisDataElement_Array({required  List<NativeXelisDataElement> values}): _values = values,super._();
  

 final  List<NativeXelisDataElement> _values;
 List<NativeXelisDataElement> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataElement_ArrayCopyWith<NativeXelisDataElement_Array> get copyWith => _$NativeXelisDataElement_ArrayCopyWithImpl<NativeXelisDataElement_Array>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataElement_Array&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'NativeXelisDataElement.array(values: $values)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataElement_ArrayCopyWith<$Res> implements $NativeXelisDataElementCopyWith<$Res> {
  factory $NativeXelisDataElement_ArrayCopyWith(NativeXelisDataElement_Array value, $Res Function(NativeXelisDataElement_Array) _then) = _$NativeXelisDataElement_ArrayCopyWithImpl;
@useResult
$Res call({
 List<NativeXelisDataElement> values
});




}
/// @nodoc
class _$NativeXelisDataElement_ArrayCopyWithImpl<$Res>
    implements $NativeXelisDataElement_ArrayCopyWith<$Res> {
  _$NativeXelisDataElement_ArrayCopyWithImpl(this._self, this._then);

  final NativeXelisDataElement_Array _self;
  final $Res Function(NativeXelisDataElement_Array) _then;

/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? values = null,}) {
  return _then(NativeXelisDataElement_Array(
values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<NativeXelisDataElement>,
  ));
}


}

/// @nodoc


class NativeXelisDataElement_Fields extends NativeXelisDataElement {
  const NativeXelisDataElement_Fields({required  List<NativeXelisDataField> fields}): _fields = fields,super._();
  

 final  List<NativeXelisDataField> _fields;
 List<NativeXelisDataField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataElement_FieldsCopyWith<NativeXelisDataElement_Fields> get copyWith => _$NativeXelisDataElement_FieldsCopyWithImpl<NativeXelisDataElement_Fields>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataElement_Fields&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'NativeXelisDataElement.fields(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataElement_FieldsCopyWith<$Res> implements $NativeXelisDataElementCopyWith<$Res> {
  factory $NativeXelisDataElement_FieldsCopyWith(NativeXelisDataElement_Fields value, $Res Function(NativeXelisDataElement_Fields) _then) = _$NativeXelisDataElement_FieldsCopyWithImpl;
@useResult
$Res call({
 List<NativeXelisDataField> fields
});




}
/// @nodoc
class _$NativeXelisDataElement_FieldsCopyWithImpl<$Res>
    implements $NativeXelisDataElement_FieldsCopyWith<$Res> {
  _$NativeXelisDataElement_FieldsCopyWithImpl(this._self, this._then);

  final NativeXelisDataElement_Fields _self;
  final $Res Function(NativeXelisDataElement_Fields) _then;

/// Create a copy of NativeXelisDataElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(NativeXelisDataElement_Fields(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<NativeXelisDataField>,
  ));
}


}

/// @nodoc
mixin _$NativeXelisDataField {

 NativeXelisDataValue get key; NativeXelisDataElement get value;
/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataFieldCopyWith<NativeXelisDataField> get copyWith => _$NativeXelisDataFieldCopyWithImpl<NativeXelisDataField>(this as NativeXelisDataField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataField&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'NativeXelisDataField(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataFieldCopyWith<$Res>  {
  factory $NativeXelisDataFieldCopyWith(NativeXelisDataField value, $Res Function(NativeXelisDataField) _then) = _$NativeXelisDataFieldCopyWithImpl;
@useResult
$Res call({
 NativeXelisDataValue key, NativeXelisDataElement value
});


$NativeXelisDataValueCopyWith<$Res> get key;$NativeXelisDataElementCopyWith<$Res> get value;

}
/// @nodoc
class _$NativeXelisDataFieldCopyWithImpl<$Res>
    implements $NativeXelisDataFieldCopyWith<$Res> {
  _$NativeXelisDataFieldCopyWithImpl(this._self, this._then);

  final NativeXelisDataField _self;
  final $Res Function(NativeXelisDataField) _then;

/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? value = null,}) {
  return _then(NativeXelisDataField(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as NativeXelisDataValue,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as NativeXelisDataElement,
  ));
}
/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataValueCopyWith<$Res> get key {
  
  return $NativeXelisDataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataElementCopyWith<$Res> get value {
  
  return $NativeXelisDataElementCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeXelisDataField].
extension NativeXelisDataFieldPatterns on NativeXelisDataField {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeXelisDataField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeXelisDataField() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeXelisDataField value)  $default,){
final _that = this;
switch (_that) {
case _NativeXelisDataField():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeXelisDataField value)?  $default,){
final _that = this;
switch (_that) {
case _NativeXelisDataField() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NativeXelisDataValue key,  NativeXelisDataElement value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeXelisDataField() when $default != null:
return $default(_that.key,_that.value);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NativeXelisDataValue key,  NativeXelisDataElement value)  $default,) {final _that = this;
switch (_that) {
case _NativeXelisDataField():
return $default(_that.key,_that.value);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NativeXelisDataValue key,  NativeXelisDataElement value)?  $default,) {final _that = this;
switch (_that) {
case _NativeXelisDataField() when $default != null:
return $default(_that.key,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _NativeXelisDataField implements NativeXelisDataField {
  const _NativeXelisDataField({required this.key, required this.value});
  

@override final  NativeXelisDataValue key;
@override final  NativeXelisDataElement value;

/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeXelisDataFieldCopyWith<_NativeXelisDataField> get copyWith => __$NativeXelisDataFieldCopyWithImpl<_NativeXelisDataField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeXelisDataField&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'NativeXelisDataField(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class _$NativeXelisDataFieldCopyWith<$Res> implements $NativeXelisDataFieldCopyWith<$Res> {
  factory _$NativeXelisDataFieldCopyWith(_NativeXelisDataField value, $Res Function(_NativeXelisDataField) _then) = __$NativeXelisDataFieldCopyWithImpl;
@override @useResult
$Res call({
 NativeXelisDataValue key, NativeXelisDataElement value
});


@override $NativeXelisDataValueCopyWith<$Res> get key;@override $NativeXelisDataElementCopyWith<$Res> get value;

}
/// @nodoc
class __$NativeXelisDataFieldCopyWithImpl<$Res>
    implements _$NativeXelisDataFieldCopyWith<$Res> {
  __$NativeXelisDataFieldCopyWithImpl(this._self, this._then);

  final _NativeXelisDataField _self;
  final $Res Function(_NativeXelisDataField) _then;

/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,}) {
  return _then(_NativeXelisDataField(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as NativeXelisDataValue,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as NativeXelisDataElement,
  ));
}

/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataValueCopyWith<$Res> get key {
  
  return $NativeXelisDataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of NativeXelisDataField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataElementCopyWith<$Res> get value {
  
  return $NativeXelisDataElementCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$NativeXelisDataValue {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataValue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeXelisDataValue()';
}


}

/// @nodoc
class $NativeXelisDataValueCopyWith<$Res>  {
$NativeXelisDataValueCopyWith(NativeXelisDataValue _, $Res Function(NativeXelisDataValue) __);
}


/// Adds pattern-matching-related methods to [NativeXelisDataValue].
extension NativeXelisDataValuePatterns on NativeXelisDataValue {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativeXelisDataValue_BoolValue value)?  boolValue,TResult Function( NativeXelisDataValue_StringValue value)?  stringValue,TResult Function( NativeXelisDataValue_UnsignedInteger value)?  unsignedInteger,TResult Function( NativeXelisDataValue_HashValue value)?  hashValue,TResult Function( NativeXelisDataValue_BlobValue value)?  blobValue,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativeXelisDataValue_BoolValue() when boolValue != null:
return boolValue(_that);case NativeXelisDataValue_StringValue() when stringValue != null:
return stringValue(_that);case NativeXelisDataValue_UnsignedInteger() when unsignedInteger != null:
return unsignedInteger(_that);case NativeXelisDataValue_HashValue() when hashValue != null:
return hashValue(_that);case NativeXelisDataValue_BlobValue() when blobValue != null:
return blobValue(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativeXelisDataValue_BoolValue value)  boolValue,required TResult Function( NativeXelisDataValue_StringValue value)  stringValue,required TResult Function( NativeXelisDataValue_UnsignedInteger value)  unsignedInteger,required TResult Function( NativeXelisDataValue_HashValue value)  hashValue,required TResult Function( NativeXelisDataValue_BlobValue value)  blobValue,}){
final _that = this;
switch (_that) {
case NativeXelisDataValue_BoolValue():
return boolValue(_that);case NativeXelisDataValue_StringValue():
return stringValue(_that);case NativeXelisDataValue_UnsignedInteger():
return unsignedInteger(_that);case NativeXelisDataValue_HashValue():
return hashValue(_that);case NativeXelisDataValue_BlobValue():
return blobValue(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativeXelisDataValue_BoolValue value)?  boolValue,TResult? Function( NativeXelisDataValue_StringValue value)?  stringValue,TResult? Function( NativeXelisDataValue_UnsignedInteger value)?  unsignedInteger,TResult? Function( NativeXelisDataValue_HashValue value)?  hashValue,TResult? Function( NativeXelisDataValue_BlobValue value)?  blobValue,}){
final _that = this;
switch (_that) {
case NativeXelisDataValue_BoolValue() when boolValue != null:
return boolValue(_that);case NativeXelisDataValue_StringValue() when stringValue != null:
return stringValue(_that);case NativeXelisDataValue_UnsignedInteger() when unsignedInteger != null:
return unsignedInteger(_that);case NativeXelisDataValue_HashValue() when hashValue != null:
return hashValue(_that);case NativeXelisDataValue_BlobValue() when blobValue != null:
return blobValue(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool value)?  boolValue,TResult Function( String value)?  stringValue,TResult Function( NativeXelisUnsignedIntegerType integerType,  String decimalValue)?  unsignedInteger,TResult Function( String hexValue)?  hashValue,TResult Function( Uint8List bytes)?  blobValue,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativeXelisDataValue_BoolValue() when boolValue != null:
return boolValue(_that.value);case NativeXelisDataValue_StringValue() when stringValue != null:
return stringValue(_that.value);case NativeXelisDataValue_UnsignedInteger() when unsignedInteger != null:
return unsignedInteger(_that.integerType,_that.decimalValue);case NativeXelisDataValue_HashValue() when hashValue != null:
return hashValue(_that.hexValue);case NativeXelisDataValue_BlobValue() when blobValue != null:
return blobValue(_that.bytes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool value)  boolValue,required TResult Function( String value)  stringValue,required TResult Function( NativeXelisUnsignedIntegerType integerType,  String decimalValue)  unsignedInteger,required TResult Function( String hexValue)  hashValue,required TResult Function( Uint8List bytes)  blobValue,}) {final _that = this;
switch (_that) {
case NativeXelisDataValue_BoolValue():
return boolValue(_that.value);case NativeXelisDataValue_StringValue():
return stringValue(_that.value);case NativeXelisDataValue_UnsignedInteger():
return unsignedInteger(_that.integerType,_that.decimalValue);case NativeXelisDataValue_HashValue():
return hashValue(_that.hexValue);case NativeXelisDataValue_BlobValue():
return blobValue(_that.bytes);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool value)?  boolValue,TResult? Function( String value)?  stringValue,TResult? Function( NativeXelisUnsignedIntegerType integerType,  String decimalValue)?  unsignedInteger,TResult? Function( String hexValue)?  hashValue,TResult? Function( Uint8List bytes)?  blobValue,}) {final _that = this;
switch (_that) {
case NativeXelisDataValue_BoolValue() when boolValue != null:
return boolValue(_that.value);case NativeXelisDataValue_StringValue() when stringValue != null:
return stringValue(_that.value);case NativeXelisDataValue_UnsignedInteger() when unsignedInteger != null:
return unsignedInteger(_that.integerType,_that.decimalValue);case NativeXelisDataValue_HashValue() when hashValue != null:
return hashValue(_that.hexValue);case NativeXelisDataValue_BlobValue() when blobValue != null:
return blobValue(_that.bytes);case _:
  return null;

}
}

}

/// @nodoc


class NativeXelisDataValue_BoolValue extends NativeXelisDataValue {
  const NativeXelisDataValue_BoolValue({required this.value}): super._();
  

 final  bool value;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataValue_BoolValueCopyWith<NativeXelisDataValue_BoolValue> get copyWith => _$NativeXelisDataValue_BoolValueCopyWithImpl<NativeXelisDataValue_BoolValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataValue_BoolValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'NativeXelisDataValue.boolValue(value: $value)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataValue_BoolValueCopyWith<$Res> implements $NativeXelisDataValueCopyWith<$Res> {
  factory $NativeXelisDataValue_BoolValueCopyWith(NativeXelisDataValue_BoolValue value, $Res Function(NativeXelisDataValue_BoolValue) _then) = _$NativeXelisDataValue_BoolValueCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$NativeXelisDataValue_BoolValueCopyWithImpl<$Res>
    implements $NativeXelisDataValue_BoolValueCopyWith<$Res> {
  _$NativeXelisDataValue_BoolValueCopyWithImpl(this._self, this._then);

  final NativeXelisDataValue_BoolValue _self;
  final $Res Function(NativeXelisDataValue_BoolValue) _then;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(NativeXelisDataValue_BoolValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class NativeXelisDataValue_StringValue extends NativeXelisDataValue {
  const NativeXelisDataValue_StringValue({required this.value}): super._();
  

 final  String value;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataValue_StringValueCopyWith<NativeXelisDataValue_StringValue> get copyWith => _$NativeXelisDataValue_StringValueCopyWithImpl<NativeXelisDataValue_StringValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataValue_StringValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'NativeXelisDataValue.stringValue(value: $value)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataValue_StringValueCopyWith<$Res> implements $NativeXelisDataValueCopyWith<$Res> {
  factory $NativeXelisDataValue_StringValueCopyWith(NativeXelisDataValue_StringValue value, $Res Function(NativeXelisDataValue_StringValue) _then) = _$NativeXelisDataValue_StringValueCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$NativeXelisDataValue_StringValueCopyWithImpl<$Res>
    implements $NativeXelisDataValue_StringValueCopyWith<$Res> {
  _$NativeXelisDataValue_StringValueCopyWithImpl(this._self, this._then);

  final NativeXelisDataValue_StringValue _self;
  final $Res Function(NativeXelisDataValue_StringValue) _then;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(NativeXelisDataValue_StringValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NativeXelisDataValue_UnsignedInteger extends NativeXelisDataValue {
  const NativeXelisDataValue_UnsignedInteger({required this.integerType, required this.decimalValue}): super._();
  

 final  NativeXelisUnsignedIntegerType integerType;
 final  String decimalValue;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataValue_UnsignedIntegerCopyWith<NativeXelisDataValue_UnsignedInteger> get copyWith => _$NativeXelisDataValue_UnsignedIntegerCopyWithImpl<NativeXelisDataValue_UnsignedInteger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataValue_UnsignedInteger&&(identical(other.integerType, integerType) || other.integerType == integerType)&&(identical(other.decimalValue, decimalValue) || other.decimalValue == decimalValue));
}


@override
int get hashCode => Object.hash(runtimeType,integerType,decimalValue);

@override
String toString() {
  return 'NativeXelisDataValue.unsignedInteger(integerType: $integerType, decimalValue: $decimalValue)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataValue_UnsignedIntegerCopyWith<$Res> implements $NativeXelisDataValueCopyWith<$Res> {
  factory $NativeXelisDataValue_UnsignedIntegerCopyWith(NativeXelisDataValue_UnsignedInteger value, $Res Function(NativeXelisDataValue_UnsignedInteger) _then) = _$NativeXelisDataValue_UnsignedIntegerCopyWithImpl;
@useResult
$Res call({
 NativeXelisUnsignedIntegerType integerType, String decimalValue
});




}
/// @nodoc
class _$NativeXelisDataValue_UnsignedIntegerCopyWithImpl<$Res>
    implements $NativeXelisDataValue_UnsignedIntegerCopyWith<$Res> {
  _$NativeXelisDataValue_UnsignedIntegerCopyWithImpl(this._self, this._then);

  final NativeXelisDataValue_UnsignedInteger _self;
  final $Res Function(NativeXelisDataValue_UnsignedInteger) _then;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? integerType = null,Object? decimalValue = null,}) {
  return _then(NativeXelisDataValue_UnsignedInteger(
integerType: null == integerType ? _self.integerType : integerType // ignore: cast_nullable_to_non_nullable
as NativeXelisUnsignedIntegerType,decimalValue: null == decimalValue ? _self.decimalValue : decimalValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NativeXelisDataValue_HashValue extends NativeXelisDataValue {
  const NativeXelisDataValue_HashValue({required this.hexValue}): super._();
  

 final  String hexValue;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataValue_HashValueCopyWith<NativeXelisDataValue_HashValue> get copyWith => _$NativeXelisDataValue_HashValueCopyWithImpl<NativeXelisDataValue_HashValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataValue_HashValue&&(identical(other.hexValue, hexValue) || other.hexValue == hexValue));
}


@override
int get hashCode => Object.hash(runtimeType,hexValue);

@override
String toString() {
  return 'NativeXelisDataValue.hashValue(hexValue: $hexValue)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataValue_HashValueCopyWith<$Res> implements $NativeXelisDataValueCopyWith<$Res> {
  factory $NativeXelisDataValue_HashValueCopyWith(NativeXelisDataValue_HashValue value, $Res Function(NativeXelisDataValue_HashValue) _then) = _$NativeXelisDataValue_HashValueCopyWithImpl;
@useResult
$Res call({
 String hexValue
});




}
/// @nodoc
class _$NativeXelisDataValue_HashValueCopyWithImpl<$Res>
    implements $NativeXelisDataValue_HashValueCopyWith<$Res> {
  _$NativeXelisDataValue_HashValueCopyWithImpl(this._self, this._then);

  final NativeXelisDataValue_HashValue _self;
  final $Res Function(NativeXelisDataValue_HashValue) _then;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hexValue = null,}) {
  return _then(NativeXelisDataValue_HashValue(
hexValue: null == hexValue ? _self.hexValue : hexValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NativeXelisDataValue_BlobValue extends NativeXelisDataValue {
  const NativeXelisDataValue_BlobValue({required this.bytes}): super._();
  

 final  Uint8List bytes;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeXelisDataValue_BlobValueCopyWith<NativeXelisDataValue_BlobValue> get copyWith => _$NativeXelisDataValue_BlobValueCopyWithImpl<NativeXelisDataValue_BlobValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeXelisDataValue_BlobValue&&const DeepCollectionEquality().equals(other.bytes, bytes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes));

@override
String toString() {
  return 'NativeXelisDataValue.blobValue(bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $NativeXelisDataValue_BlobValueCopyWith<$Res> implements $NativeXelisDataValueCopyWith<$Res> {
  factory $NativeXelisDataValue_BlobValueCopyWith(NativeXelisDataValue_BlobValue value, $Res Function(NativeXelisDataValue_BlobValue) _then) = _$NativeXelisDataValue_BlobValueCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes
});




}
/// @nodoc
class _$NativeXelisDataValue_BlobValueCopyWithImpl<$Res>
    implements $NativeXelisDataValue_BlobValueCopyWith<$Res> {
  _$NativeXelisDataValue_BlobValueCopyWithImpl(this._self, this._then);

  final NativeXelisDataValue_BlobValue _self;
  final $Res Function(NativeXelisDataValue_BlobValue) _then;

/// Create a copy of NativeXelisDataValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,}) {
  return _then(NativeXelisDataValue_BlobValue(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

// dart format on
