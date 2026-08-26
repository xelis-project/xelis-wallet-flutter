// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryPageFilter {

 BigInt get page; BigInt? get limit; String? get assetHash; String? get address; BigInt? get minTopoheight; BigInt? get maxTopoheight; bool get acceptIncoming; bool get acceptOutgoing; bool get acceptCoinbase; bool get acceptBurn; bool get acceptBlob; BigInt? get minTimestamp; BigInt? get maxTimestamp;
/// Create a copy of HistoryPageFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryPageFilterCopyWith<HistoryPageFilter> get copyWith => _$HistoryPageFilterCopyWithImpl<HistoryPageFilter>(this as HistoryPageFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryPageFilter&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.assetHash, assetHash) || other.assetHash == assetHash)&&(identical(other.address, address) || other.address == address)&&(identical(other.minTopoheight, minTopoheight) || other.minTopoheight == minTopoheight)&&(identical(other.maxTopoheight, maxTopoheight) || other.maxTopoheight == maxTopoheight)&&(identical(other.acceptIncoming, acceptIncoming) || other.acceptIncoming == acceptIncoming)&&(identical(other.acceptOutgoing, acceptOutgoing) || other.acceptOutgoing == acceptOutgoing)&&(identical(other.acceptCoinbase, acceptCoinbase) || other.acceptCoinbase == acceptCoinbase)&&(identical(other.acceptBurn, acceptBurn) || other.acceptBurn == acceptBurn)&&(identical(other.acceptBlob, acceptBlob) || other.acceptBlob == acceptBlob)&&(identical(other.minTimestamp, minTimestamp) || other.minTimestamp == minTimestamp)&&(identical(other.maxTimestamp, maxTimestamp) || other.maxTimestamp == maxTimestamp));
}


@override
int get hashCode => Object.hash(runtimeType,page,limit,assetHash,address,minTopoheight,maxTopoheight,acceptIncoming,acceptOutgoing,acceptCoinbase,acceptBurn,acceptBlob,minTimestamp,maxTimestamp);

@override
String toString() {
  return 'HistoryPageFilter(page: $page, limit: $limit, assetHash: $assetHash, address: $address, minTopoheight: $minTopoheight, maxTopoheight: $maxTopoheight, acceptIncoming: $acceptIncoming, acceptOutgoing: $acceptOutgoing, acceptCoinbase: $acceptCoinbase, acceptBurn: $acceptBurn, acceptBlob: $acceptBlob, minTimestamp: $minTimestamp, maxTimestamp: $maxTimestamp)';
}


}

/// @nodoc
abstract mixin class $HistoryPageFilterCopyWith<$Res>  {
  factory $HistoryPageFilterCopyWith(HistoryPageFilter value, $Res Function(HistoryPageFilter) _then) = _$HistoryPageFilterCopyWithImpl;
@useResult
$Res call({
 BigInt page, BigInt? limit, String? assetHash, String? address, BigInt? minTopoheight, BigInt? maxTopoheight, bool acceptIncoming, bool acceptOutgoing, bool acceptCoinbase, bool acceptBurn, bool acceptBlob, BigInt? minTimestamp, BigInt? maxTimestamp
});




}
/// @nodoc
class _$HistoryPageFilterCopyWithImpl<$Res>
    implements $HistoryPageFilterCopyWith<$Res> {
  _$HistoryPageFilterCopyWithImpl(this._self, this._then);

  final HistoryPageFilter _self;
  final $Res Function(HistoryPageFilter) _then;

/// Create a copy of HistoryPageFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? limit = freezed,Object? assetHash = freezed,Object? address = freezed,Object? minTopoheight = freezed,Object? maxTopoheight = freezed,Object? acceptIncoming = null,Object? acceptOutgoing = null,Object? acceptCoinbase = null,Object? acceptBurn = null,Object? acceptBlob = null,Object? minTimestamp = freezed,Object? maxTimestamp = freezed,}) {
  return _then(HistoryPageFilter(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as BigInt,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as BigInt?,assetHash: freezed == assetHash ? _self.assetHash : assetHash // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,minTopoheight: freezed == minTopoheight ? _self.minTopoheight : minTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt?,maxTopoheight: freezed == maxTopoheight ? _self.maxTopoheight : maxTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt?,acceptIncoming: null == acceptIncoming ? _self.acceptIncoming : acceptIncoming // ignore: cast_nullable_to_non_nullable
as bool,acceptOutgoing: null == acceptOutgoing ? _self.acceptOutgoing : acceptOutgoing // ignore: cast_nullable_to_non_nullable
as bool,acceptCoinbase: null == acceptCoinbase ? _self.acceptCoinbase : acceptCoinbase // ignore: cast_nullable_to_non_nullable
as bool,acceptBurn: null == acceptBurn ? _self.acceptBurn : acceptBurn // ignore: cast_nullable_to_non_nullable
as bool,acceptBlob: null == acceptBlob ? _self.acceptBlob : acceptBlob // ignore: cast_nullable_to_non_nullable
as bool,minTimestamp: freezed == minTimestamp ? _self.minTimestamp : minTimestamp // ignore: cast_nullable_to_non_nullable
as BigInt?,maxTimestamp: freezed == maxTimestamp ? _self.maxTimestamp : maxTimestamp // ignore: cast_nullable_to_non_nullable
as BigInt?,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryPageFilter].
extension HistoryPageFilterPatterns on HistoryPageFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryPageFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryPageFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryPageFilter value)  $default,){
final _that = this;
switch (_that) {
case _HistoryPageFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryPageFilter value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryPageFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt page,  BigInt? limit,  String? assetHash,  String? address,  BigInt? minTopoheight,  BigInt? maxTopoheight,  bool acceptIncoming,  bool acceptOutgoing,  bool acceptCoinbase,  bool acceptBurn,  bool acceptBlob,  BigInt? minTimestamp,  BigInt? maxTimestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryPageFilter() when $default != null:
return $default(_that.page,_that.limit,_that.assetHash,_that.address,_that.minTopoheight,_that.maxTopoheight,_that.acceptIncoming,_that.acceptOutgoing,_that.acceptCoinbase,_that.acceptBurn,_that.acceptBlob,_that.minTimestamp,_that.maxTimestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt page,  BigInt? limit,  String? assetHash,  String? address,  BigInt? minTopoheight,  BigInt? maxTopoheight,  bool acceptIncoming,  bool acceptOutgoing,  bool acceptCoinbase,  bool acceptBurn,  bool acceptBlob,  BigInt? minTimestamp,  BigInt? maxTimestamp)  $default,) {final _that = this;
switch (_that) {
case _HistoryPageFilter():
return $default(_that.page,_that.limit,_that.assetHash,_that.address,_that.minTopoheight,_that.maxTopoheight,_that.acceptIncoming,_that.acceptOutgoing,_that.acceptCoinbase,_that.acceptBurn,_that.acceptBlob,_that.minTimestamp,_that.maxTimestamp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt page,  BigInt? limit,  String? assetHash,  String? address,  BigInt? minTopoheight,  BigInt? maxTopoheight,  bool acceptIncoming,  bool acceptOutgoing,  bool acceptCoinbase,  bool acceptBurn,  bool acceptBlob,  BigInt? minTimestamp,  BigInt? maxTimestamp)?  $default,) {final _that = this;
switch (_that) {
case _HistoryPageFilter() when $default != null:
return $default(_that.page,_that.limit,_that.assetHash,_that.address,_that.minTopoheight,_that.maxTopoheight,_that.acceptIncoming,_that.acceptOutgoing,_that.acceptCoinbase,_that.acceptBurn,_that.acceptBlob,_that.minTimestamp,_that.maxTimestamp);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryPageFilter implements HistoryPageFilter {
  const _HistoryPageFilter({required this.page, this.limit, this.assetHash, this.address, this.minTopoheight, this.maxTopoheight, required this.acceptIncoming, required this.acceptOutgoing, required this.acceptCoinbase, required this.acceptBurn, required this.acceptBlob, this.minTimestamp, this.maxTimestamp});
  

@override final  BigInt page;
@override final  BigInt? limit;
@override final  String? assetHash;
@override final  String? address;
@override final  BigInt? minTopoheight;
@override final  BigInt? maxTopoheight;
@override final  bool acceptIncoming;
@override final  bool acceptOutgoing;
@override final  bool acceptCoinbase;
@override final  bool acceptBurn;
@override final  bool acceptBlob;
@override final  BigInt? minTimestamp;
@override final  BigInt? maxTimestamp;

/// Create a copy of HistoryPageFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryPageFilterCopyWith<_HistoryPageFilter> get copyWith => __$HistoryPageFilterCopyWithImpl<_HistoryPageFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryPageFilter&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.assetHash, assetHash) || other.assetHash == assetHash)&&(identical(other.address, address) || other.address == address)&&(identical(other.minTopoheight, minTopoheight) || other.minTopoheight == minTopoheight)&&(identical(other.maxTopoheight, maxTopoheight) || other.maxTopoheight == maxTopoheight)&&(identical(other.acceptIncoming, acceptIncoming) || other.acceptIncoming == acceptIncoming)&&(identical(other.acceptOutgoing, acceptOutgoing) || other.acceptOutgoing == acceptOutgoing)&&(identical(other.acceptCoinbase, acceptCoinbase) || other.acceptCoinbase == acceptCoinbase)&&(identical(other.acceptBurn, acceptBurn) || other.acceptBurn == acceptBurn)&&(identical(other.acceptBlob, acceptBlob) || other.acceptBlob == acceptBlob)&&(identical(other.minTimestamp, minTimestamp) || other.minTimestamp == minTimestamp)&&(identical(other.maxTimestamp, maxTimestamp) || other.maxTimestamp == maxTimestamp));
}


@override
int get hashCode => Object.hash(runtimeType,page,limit,assetHash,address,minTopoheight,maxTopoheight,acceptIncoming,acceptOutgoing,acceptCoinbase,acceptBurn,acceptBlob,minTimestamp,maxTimestamp);

@override
String toString() {
  return 'HistoryPageFilter(page: $page, limit: $limit, assetHash: $assetHash, address: $address, minTopoheight: $minTopoheight, maxTopoheight: $maxTopoheight, acceptIncoming: $acceptIncoming, acceptOutgoing: $acceptOutgoing, acceptCoinbase: $acceptCoinbase, acceptBurn: $acceptBurn, acceptBlob: $acceptBlob, minTimestamp: $minTimestamp, maxTimestamp: $maxTimestamp)';
}


}

/// @nodoc
abstract mixin class _$HistoryPageFilterCopyWith<$Res> implements $HistoryPageFilterCopyWith<$Res> {
  factory _$HistoryPageFilterCopyWith(_HistoryPageFilter value, $Res Function(_HistoryPageFilter) _then) = __$HistoryPageFilterCopyWithImpl;
@override @useResult
$Res call({
 BigInt page, BigInt? limit, String? assetHash, String? address, BigInt? minTopoheight, BigInt? maxTopoheight, bool acceptIncoming, bool acceptOutgoing, bool acceptCoinbase, bool acceptBurn, bool acceptBlob, BigInt? minTimestamp, BigInt? maxTimestamp
});




}
/// @nodoc
class __$HistoryPageFilterCopyWithImpl<$Res>
    implements _$HistoryPageFilterCopyWith<$Res> {
  __$HistoryPageFilterCopyWithImpl(this._self, this._then);

  final _HistoryPageFilter _self;
  final $Res Function(_HistoryPageFilter) _then;

/// Create a copy of HistoryPageFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? limit = freezed,Object? assetHash = freezed,Object? address = freezed,Object? minTopoheight = freezed,Object? maxTopoheight = freezed,Object? acceptIncoming = null,Object? acceptOutgoing = null,Object? acceptCoinbase = null,Object? acceptBurn = null,Object? acceptBlob = null,Object? minTimestamp = freezed,Object? maxTimestamp = freezed,}) {
  return _then(_HistoryPageFilter(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as BigInt,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as BigInt?,assetHash: freezed == assetHash ? _self.assetHash : assetHash // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,minTopoheight: freezed == minTopoheight ? _self.minTopoheight : minTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt?,maxTopoheight: freezed == maxTopoheight ? _self.maxTopoheight : maxTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt?,acceptIncoming: null == acceptIncoming ? _self.acceptIncoming : acceptIncoming // ignore: cast_nullable_to_non_nullable
as bool,acceptOutgoing: null == acceptOutgoing ? _self.acceptOutgoing : acceptOutgoing // ignore: cast_nullable_to_non_nullable
as bool,acceptCoinbase: null == acceptCoinbase ? _self.acceptCoinbase : acceptCoinbase // ignore: cast_nullable_to_non_nullable
as bool,acceptBurn: null == acceptBurn ? _self.acceptBurn : acceptBurn // ignore: cast_nullable_to_non_nullable
as bool,acceptBlob: null == acceptBlob ? _self.acceptBlob : acceptBlob // ignore: cast_nullable_to_non_nullable
as bool,minTimestamp: freezed == minTimestamp ? _self.minTimestamp : minTimestamp // ignore: cast_nullable_to_non_nullable
as BigInt?,maxTimestamp: freezed == maxTimestamp ? _self.maxTimestamp : maxTimestamp // ignore: cast_nullable_to_non_nullable
as BigInt?,
  ));
}


}

/// @nodoc
mixin _$NativeMultisigParticipant {

 int get id; String get address;
/// Create a copy of NativeMultisigParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigParticipantCopyWith<NativeMultisigParticipant> get copyWith => _$NativeMultisigParticipantCopyWithImpl<NativeMultisigParticipant>(this as NativeMultisigParticipant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,id,address);

@override
String toString() {
  return 'NativeMultisigParticipant(id: $id, address: $address)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigParticipantCopyWith<$Res>  {
  factory $NativeMultisigParticipantCopyWith(NativeMultisigParticipant value, $Res Function(NativeMultisigParticipant) _then) = _$NativeMultisigParticipantCopyWithImpl;
@useResult
$Res call({
 int id, String address
});




}
/// @nodoc
class _$NativeMultisigParticipantCopyWithImpl<$Res>
    implements $NativeMultisigParticipantCopyWith<$Res> {
  _$NativeMultisigParticipantCopyWithImpl(this._self, this._then);

  final NativeMultisigParticipant _self;
  final $Res Function(NativeMultisigParticipant) _then;

/// Create a copy of NativeMultisigParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? address = null,}) {
  return _then(NativeMultisigParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeMultisigParticipant].
extension NativeMultisigParticipantPatterns on NativeMultisigParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeMultisigParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeMultisigParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeMultisigParticipant value)  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeMultisigParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeMultisigParticipant() when $default != null:
return $default(_that.id,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String address)  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigParticipant():
return $default(_that.id,_that.address);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String address)?  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigParticipant() when $default != null:
return $default(_that.id,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _NativeMultisigParticipant implements NativeMultisigParticipant {
  const _NativeMultisigParticipant({required this.id, required this.address});
  

@override final  int id;
@override final  String address;

/// Create a copy of NativeMultisigParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeMultisigParticipantCopyWith<_NativeMultisigParticipant> get copyWith => __$NativeMultisigParticipantCopyWithImpl<_NativeMultisigParticipant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeMultisigParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,id,address);

@override
String toString() {
  return 'NativeMultisigParticipant(id: $id, address: $address)';
}


}

/// @nodoc
abstract mixin class _$NativeMultisigParticipantCopyWith<$Res> implements $NativeMultisigParticipantCopyWith<$Res> {
  factory _$NativeMultisigParticipantCopyWith(_NativeMultisigParticipant value, $Res Function(_NativeMultisigParticipant) _then) = __$NativeMultisigParticipantCopyWithImpl;
@override @useResult
$Res call({
 int id, String address
});




}
/// @nodoc
class __$NativeMultisigParticipantCopyWithImpl<$Res>
    implements _$NativeMultisigParticipantCopyWith<$Res> {
  __$NativeMultisigParticipantCopyWithImpl(this._self, this._then);

  final _NativeMultisigParticipant _self;
  final $Res Function(_NativeMultisigParticipant) _then;

/// Create a copy of NativeMultisigParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? address = null,}) {
  return _then(_NativeMultisigParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$NativeMultisigSignatureShare {

 String get encoded; String get signingHash; int get signerId; String get signature;
/// Create a copy of NativeMultisigSignatureShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigSignatureShareCopyWith<NativeMultisigSignatureShare> get copyWith => _$NativeMultisigSignatureShareCopyWithImpl<NativeMultisigSignatureShare>(this as NativeMultisigSignatureShare, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSignatureShare&&(identical(other.encoded, encoded) || other.encoded == encoded)&&(identical(other.signingHash, signingHash) || other.signingHash == signingHash)&&(identical(other.signerId, signerId) || other.signerId == signerId)&&(identical(other.signature, signature) || other.signature == signature));
}


@override
int get hashCode => Object.hash(runtimeType,encoded,signingHash,signerId,signature);

@override
String toString() {
  return 'NativeMultisigSignatureShare(encoded: $encoded, signingHash: $signingHash, signerId: $signerId, signature: $signature)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigSignatureShareCopyWith<$Res>  {
  factory $NativeMultisigSignatureShareCopyWith(NativeMultisigSignatureShare value, $Res Function(NativeMultisigSignatureShare) _then) = _$NativeMultisigSignatureShareCopyWithImpl;
@useResult
$Res call({
 String encoded, String signingHash, int signerId, String signature
});




}
/// @nodoc
class _$NativeMultisigSignatureShareCopyWithImpl<$Res>
    implements $NativeMultisigSignatureShareCopyWith<$Res> {
  _$NativeMultisigSignatureShareCopyWithImpl(this._self, this._then);

  final NativeMultisigSignatureShare _self;
  final $Res Function(NativeMultisigSignatureShare) _then;

/// Create a copy of NativeMultisigSignatureShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? encoded = null,Object? signingHash = null,Object? signerId = null,Object? signature = null,}) {
  return _then(NativeMultisigSignatureShare(
encoded: null == encoded ? _self.encoded : encoded // ignore: cast_nullable_to_non_nullable
as String,signingHash: null == signingHash ? _self.signingHash : signingHash // ignore: cast_nullable_to_non_nullable
as String,signerId: null == signerId ? _self.signerId : signerId // ignore: cast_nullable_to_non_nullable
as int,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeMultisigSignatureShare].
extension NativeMultisigSignatureSharePatterns on NativeMultisigSignatureShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeMultisigSignatureShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeMultisigSignatureShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeMultisigSignatureShare value)  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigSignatureShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeMultisigSignatureShare value)?  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigSignatureShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String encoded,  String signingHash,  int signerId,  String signature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeMultisigSignatureShare() when $default != null:
return $default(_that.encoded,_that.signingHash,_that.signerId,_that.signature);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String encoded,  String signingHash,  int signerId,  String signature)  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigSignatureShare():
return $default(_that.encoded,_that.signingHash,_that.signerId,_that.signature);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String encoded,  String signingHash,  int signerId,  String signature)?  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigSignatureShare() when $default != null:
return $default(_that.encoded,_that.signingHash,_that.signerId,_that.signature);case _:
  return null;

}
}

}

/// @nodoc


class _NativeMultisigSignatureShare implements NativeMultisigSignatureShare {
  const _NativeMultisigSignatureShare({required this.encoded, required this.signingHash, required this.signerId, required this.signature});
  

@override final  String encoded;
@override final  String signingHash;
@override final  int signerId;
@override final  String signature;

/// Create a copy of NativeMultisigSignatureShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeMultisigSignatureShareCopyWith<_NativeMultisigSignatureShare> get copyWith => __$NativeMultisigSignatureShareCopyWithImpl<_NativeMultisigSignatureShare>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeMultisigSignatureShare&&(identical(other.encoded, encoded) || other.encoded == encoded)&&(identical(other.signingHash, signingHash) || other.signingHash == signingHash)&&(identical(other.signerId, signerId) || other.signerId == signerId)&&(identical(other.signature, signature) || other.signature == signature));
}


@override
int get hashCode => Object.hash(runtimeType,encoded,signingHash,signerId,signature);

@override
String toString() {
  return 'NativeMultisigSignatureShare(encoded: $encoded, signingHash: $signingHash, signerId: $signerId, signature: $signature)';
}


}

/// @nodoc
abstract mixin class _$NativeMultisigSignatureShareCopyWith<$Res> implements $NativeMultisigSignatureShareCopyWith<$Res> {
  factory _$NativeMultisigSignatureShareCopyWith(_NativeMultisigSignatureShare value, $Res Function(_NativeMultisigSignatureShare) _then) = __$NativeMultisigSignatureShareCopyWithImpl;
@override @useResult
$Res call({
 String encoded, String signingHash, int signerId, String signature
});




}
/// @nodoc
class __$NativeMultisigSignatureShareCopyWithImpl<$Res>
    implements _$NativeMultisigSignatureShareCopyWith<$Res> {
  __$NativeMultisigSignatureShareCopyWithImpl(this._self, this._then);

  final _NativeMultisigSignatureShare _self;
  final $Res Function(_NativeMultisigSignatureShare) _then;

/// Create a copy of NativeMultisigSignatureShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? encoded = null,Object? signingHash = null,Object? signerId = null,Object? signature = null,}) {
  return _then(_NativeMultisigSignatureShare(
encoded: null == encoded ? _self.encoded : encoded // ignore: cast_nullable_to_non_nullable
as String,signingHash: null == signingHash ? _self.signingHash : signingHash // ignore: cast_nullable_to_non_nullable
as String,signerId: null == signerId ? _self.signerId : signerId // ignore: cast_nullable_to_non_nullable
as int,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$NativeMultisigSigningRequest {

 BigInt? get requestId; String get encoded; String get signingHash; String get source; String get network; BigInt get fee; BigInt get feeLimit; BigInt get nonce; BigInt get referenceTopoheight; int get threshold; List<NativeMultisigParticipant> get participants; int? get signerId; NativeMultisigSigningTransaction get transaction;
/// Create a copy of NativeMultisigSigningRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigSigningRequestCopyWith<NativeMultisigSigningRequest> get copyWith => _$NativeMultisigSigningRequestCopyWithImpl<NativeMultisigSigningRequest>(this as NativeMultisigSigningRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSigningRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.encoded, encoded) || other.encoded == encoded)&&(identical(other.signingHash, signingHash) || other.signingHash == signingHash)&&(identical(other.source, source) || other.source == source)&&(identical(other.network, network) || other.network == network)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.feeLimit, feeLimit) || other.feeLimit == feeLimit)&&(identical(other.nonce, nonce) || other.nonce == nonce)&&(identical(other.referenceTopoheight, referenceTopoheight) || other.referenceTopoheight == referenceTopoheight)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.signerId, signerId) || other.signerId == signerId)&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,encoded,signingHash,source,network,fee,feeLimit,nonce,referenceTopoheight,threshold,const DeepCollectionEquality().hash(participants),signerId,transaction);

@override
String toString() {
  return 'NativeMultisigSigningRequest(requestId: $requestId, encoded: $encoded, signingHash: $signingHash, source: $source, network: $network, fee: $fee, feeLimit: $feeLimit, nonce: $nonce, referenceTopoheight: $referenceTopoheight, threshold: $threshold, participants: $participants, signerId: $signerId, transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigSigningRequestCopyWith<$Res>  {
  factory $NativeMultisigSigningRequestCopyWith(NativeMultisigSigningRequest value, $Res Function(NativeMultisigSigningRequest) _then) = _$NativeMultisigSigningRequestCopyWithImpl;
@useResult
$Res call({
 BigInt? requestId, String encoded, String signingHash, String source, String network, BigInt fee, BigInt feeLimit, BigInt nonce, BigInt referenceTopoheight, int threshold, List<NativeMultisigParticipant> participants, int? signerId, NativeMultisigSigningTransaction transaction
});


$NativeMultisigSigningTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class _$NativeMultisigSigningRequestCopyWithImpl<$Res>
    implements $NativeMultisigSigningRequestCopyWith<$Res> {
  _$NativeMultisigSigningRequestCopyWithImpl(this._self, this._then);

  final NativeMultisigSigningRequest _self;
  final $Res Function(NativeMultisigSigningRequest) _then;

/// Create a copy of NativeMultisigSigningRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = freezed,Object? encoded = null,Object? signingHash = null,Object? source = null,Object? network = null,Object? fee = null,Object? feeLimit = null,Object? nonce = null,Object? referenceTopoheight = null,Object? threshold = null,Object? participants = null,Object? signerId = freezed,Object? transaction = null,}) {
  return _then(NativeMultisigSigningRequest(
requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as BigInt?,encoded: null == encoded ? _self.encoded : encoded // ignore: cast_nullable_to_non_nullable
as String,signingHash: null == signingHash ? _self.signingHash : signingHash // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,feeLimit: null == feeLimit ? _self.feeLimit : feeLimit // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,referenceTopoheight: null == referenceTopoheight ? _self.referenceTopoheight : referenceTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<NativeMultisigParticipant>,signerId: freezed == signerId ? _self.signerId : signerId // ignore: cast_nullable_to_non_nullable
as int?,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativeMultisigSigningTransaction,
  ));
}
/// Create a copy of NativeMultisigSigningRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeMultisigSigningTransactionCopyWith<$Res> get transaction {
  
  return $NativeMultisigSigningTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeMultisigSigningRequest].
extension NativeMultisigSigningRequestPatterns on NativeMultisigSigningRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeMultisigSigningRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeMultisigSigningRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeMultisigSigningRequest value)  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigSigningRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeMultisigSigningRequest value)?  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigSigningRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt? requestId,  String encoded,  String signingHash,  String source,  String network,  BigInt fee,  BigInt feeLimit,  BigInt nonce,  BigInt referenceTopoheight,  int threshold,  List<NativeMultisigParticipant> participants,  int? signerId,  NativeMultisigSigningTransaction transaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeMultisigSigningRequest() when $default != null:
return $default(_that.requestId,_that.encoded,_that.signingHash,_that.source,_that.network,_that.fee,_that.feeLimit,_that.nonce,_that.referenceTopoheight,_that.threshold,_that.participants,_that.signerId,_that.transaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt? requestId,  String encoded,  String signingHash,  String source,  String network,  BigInt fee,  BigInt feeLimit,  BigInt nonce,  BigInt referenceTopoheight,  int threshold,  List<NativeMultisigParticipant> participants,  int? signerId,  NativeMultisigSigningTransaction transaction)  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigSigningRequest():
return $default(_that.requestId,_that.encoded,_that.signingHash,_that.source,_that.network,_that.fee,_that.feeLimit,_that.nonce,_that.referenceTopoheight,_that.threshold,_that.participants,_that.signerId,_that.transaction);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt? requestId,  String encoded,  String signingHash,  String source,  String network,  BigInt fee,  BigInt feeLimit,  BigInt nonce,  BigInt referenceTopoheight,  int threshold,  List<NativeMultisigParticipant> participants,  int? signerId,  NativeMultisigSigningTransaction transaction)?  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigSigningRequest() when $default != null:
return $default(_that.requestId,_that.encoded,_that.signingHash,_that.source,_that.network,_that.fee,_that.feeLimit,_that.nonce,_that.referenceTopoheight,_that.threshold,_that.participants,_that.signerId,_that.transaction);case _:
  return null;

}
}

}

/// @nodoc


class _NativeMultisigSigningRequest implements NativeMultisigSigningRequest {
  const _NativeMultisigSigningRequest({this.requestId, required this.encoded, required this.signingHash, required this.source, required this.network, required this.fee, required this.feeLimit, required this.nonce, required this.referenceTopoheight, required this.threshold, required  List<NativeMultisigParticipant> participants, this.signerId, required this.transaction}): _participants = participants;
  

@override final  BigInt? requestId;
@override final  String encoded;
@override final  String signingHash;
@override final  String source;
@override final  String network;
@override final  BigInt fee;
@override final  BigInt feeLimit;
@override final  BigInt nonce;
@override final  BigInt referenceTopoheight;
@override final  int threshold;
 final  List<NativeMultisigParticipant> _participants;
@override List<NativeMultisigParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

@override final  int? signerId;
@override final  NativeMultisigSigningTransaction transaction;

/// Create a copy of NativeMultisigSigningRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeMultisigSigningRequestCopyWith<_NativeMultisigSigningRequest> get copyWith => __$NativeMultisigSigningRequestCopyWithImpl<_NativeMultisigSigningRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeMultisigSigningRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.encoded, encoded) || other.encoded == encoded)&&(identical(other.signingHash, signingHash) || other.signingHash == signingHash)&&(identical(other.source, source) || other.source == source)&&(identical(other.network, network) || other.network == network)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.feeLimit, feeLimit) || other.feeLimit == feeLimit)&&(identical(other.nonce, nonce) || other.nonce == nonce)&&(identical(other.referenceTopoheight, referenceTopoheight) || other.referenceTopoheight == referenceTopoheight)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.signerId, signerId) || other.signerId == signerId)&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,encoded,signingHash,source,network,fee,feeLimit,nonce,referenceTopoheight,threshold,const DeepCollectionEquality().hash(_participants),signerId,transaction);

@override
String toString() {
  return 'NativeMultisigSigningRequest(requestId: $requestId, encoded: $encoded, signingHash: $signingHash, source: $source, network: $network, fee: $fee, feeLimit: $feeLimit, nonce: $nonce, referenceTopoheight: $referenceTopoheight, threshold: $threshold, participants: $participants, signerId: $signerId, transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class _$NativeMultisigSigningRequestCopyWith<$Res> implements $NativeMultisigSigningRequestCopyWith<$Res> {
  factory _$NativeMultisigSigningRequestCopyWith(_NativeMultisigSigningRequest value, $Res Function(_NativeMultisigSigningRequest) _then) = __$NativeMultisigSigningRequestCopyWithImpl;
@override @useResult
$Res call({
 BigInt? requestId, String encoded, String signingHash, String source, String network, BigInt fee, BigInt feeLimit, BigInt nonce, BigInt referenceTopoheight, int threshold, List<NativeMultisigParticipant> participants, int? signerId, NativeMultisigSigningTransaction transaction
});


@override $NativeMultisigSigningTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class __$NativeMultisigSigningRequestCopyWithImpl<$Res>
    implements _$NativeMultisigSigningRequestCopyWith<$Res> {
  __$NativeMultisigSigningRequestCopyWithImpl(this._self, this._then);

  final _NativeMultisigSigningRequest _self;
  final $Res Function(_NativeMultisigSigningRequest) _then;

/// Create a copy of NativeMultisigSigningRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = freezed,Object? encoded = null,Object? signingHash = null,Object? source = null,Object? network = null,Object? fee = null,Object? feeLimit = null,Object? nonce = null,Object? referenceTopoheight = null,Object? threshold = null,Object? participants = null,Object? signerId = freezed,Object? transaction = null,}) {
  return _then(_NativeMultisigSigningRequest(
requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as BigInt?,encoded: null == encoded ? _self.encoded : encoded // ignore: cast_nullable_to_non_nullable
as String,signingHash: null == signingHash ? _self.signingHash : signingHash // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,feeLimit: null == feeLimit ? _self.feeLimit : feeLimit // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,referenceTopoheight: null == referenceTopoheight ? _self.referenceTopoheight : referenceTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<NativeMultisigParticipant>,signerId: freezed == signerId ? _self.signerId : signerId // ignore: cast_nullable_to_non_nullable
as int?,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativeMultisigSigningTransaction,
  ));
}

/// Create a copy of NativeMultisigSigningRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeMultisigSigningTransactionCopyWith<$Res> get transaction {
  
  return $NativeMultisigSigningTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

/// @nodoc
mixin _$NativeMultisigSigningTransaction {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSigningTransaction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeMultisigSigningTransaction()';
}


}

/// @nodoc
class $NativeMultisigSigningTransactionCopyWith<$Res>  {
$NativeMultisigSigningTransactionCopyWith(NativeMultisigSigningTransaction _, $Res Function(NativeMultisigSigningTransaction) __);
}


/// Adds pattern-matching-related methods to [NativeMultisigSigningTransaction].
extension NativeMultisigSigningTransactionPatterns on NativeMultisigSigningTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativeMultisigSigningTransaction_Transfers value)?  transfers,TResult Function( NativeMultisigSigningTransaction_Burn value)?  burn,TResult Function( NativeMultisigSigningTransaction_DeleteMultisig value)?  deleteMultisig,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativeMultisigSigningTransaction_Transfers() when transfers != null:
return transfers(_that);case NativeMultisigSigningTransaction_Burn() when burn != null:
return burn(_that);case NativeMultisigSigningTransaction_DeleteMultisig() when deleteMultisig != null:
return deleteMultisig(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativeMultisigSigningTransaction_Transfers value)  transfers,required TResult Function( NativeMultisigSigningTransaction_Burn value)  burn,required TResult Function( NativeMultisigSigningTransaction_DeleteMultisig value)  deleteMultisig,}){
final _that = this;
switch (_that) {
case NativeMultisigSigningTransaction_Transfers():
return transfers(_that);case NativeMultisigSigningTransaction_Burn():
return burn(_that);case NativeMultisigSigningTransaction_DeleteMultisig():
return deleteMultisig(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativeMultisigSigningTransaction_Transfers value)?  transfers,TResult? Function( NativeMultisigSigningTransaction_Burn value)?  burn,TResult? Function( NativeMultisigSigningTransaction_DeleteMultisig value)?  deleteMultisig,}){
final _that = this;
switch (_that) {
case NativeMultisigSigningTransaction_Transfers() when transfers != null:
return transfers(_that);case NativeMultisigSigningTransaction_Burn() when burn != null:
return burn(_that);case NativeMultisigSigningTransaction_DeleteMultisig() when deleteMultisig != null:
return deleteMultisig(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<NativeMultisigSigningTransfer> transfers)?  transfers,TResult Function( String asset,  BigInt amount)?  burn,TResult Function()?  deleteMultisig,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativeMultisigSigningTransaction_Transfers() when transfers != null:
return transfers(_that.transfers);case NativeMultisigSigningTransaction_Burn() when burn != null:
return burn(_that.asset,_that.amount);case NativeMultisigSigningTransaction_DeleteMultisig() when deleteMultisig != null:
return deleteMultisig();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<NativeMultisigSigningTransfer> transfers)  transfers,required TResult Function( String asset,  BigInt amount)  burn,required TResult Function()  deleteMultisig,}) {final _that = this;
switch (_that) {
case NativeMultisigSigningTransaction_Transfers():
return transfers(_that.transfers);case NativeMultisigSigningTransaction_Burn():
return burn(_that.asset,_that.amount);case NativeMultisigSigningTransaction_DeleteMultisig():
return deleteMultisig();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<NativeMultisigSigningTransfer> transfers)?  transfers,TResult? Function( String asset,  BigInt amount)?  burn,TResult? Function()?  deleteMultisig,}) {final _that = this;
switch (_that) {
case NativeMultisigSigningTransaction_Transfers() when transfers != null:
return transfers(_that.transfers);case NativeMultisigSigningTransaction_Burn() when burn != null:
return burn(_that.asset,_that.amount);case NativeMultisigSigningTransaction_DeleteMultisig() when deleteMultisig != null:
return deleteMultisig();case _:
  return null;

}
}

}

/// @nodoc


class NativeMultisigSigningTransaction_Transfers extends NativeMultisigSigningTransaction {
  const NativeMultisigSigningTransaction_Transfers({required  List<NativeMultisigSigningTransfer> transfers}): _transfers = transfers,super._();
  

 final  List<NativeMultisigSigningTransfer> _transfers;
 List<NativeMultisigSigningTransfer> get transfers {
  if (_transfers is EqualUnmodifiableListView) return _transfers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transfers);
}


/// Create a copy of NativeMultisigSigningTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigSigningTransaction_TransfersCopyWith<NativeMultisigSigningTransaction_Transfers> get copyWith => _$NativeMultisigSigningTransaction_TransfersCopyWithImpl<NativeMultisigSigningTransaction_Transfers>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSigningTransaction_Transfers&&const DeepCollectionEquality().equals(other._transfers, _transfers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transfers));

@override
String toString() {
  return 'NativeMultisigSigningTransaction.transfers(transfers: $transfers)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigSigningTransaction_TransfersCopyWith<$Res> implements $NativeMultisigSigningTransactionCopyWith<$Res> {
  factory $NativeMultisigSigningTransaction_TransfersCopyWith(NativeMultisigSigningTransaction_Transfers value, $Res Function(NativeMultisigSigningTransaction_Transfers) _then) = _$NativeMultisigSigningTransaction_TransfersCopyWithImpl;
@useResult
$Res call({
 List<NativeMultisigSigningTransfer> transfers
});




}
/// @nodoc
class _$NativeMultisigSigningTransaction_TransfersCopyWithImpl<$Res>
    implements $NativeMultisigSigningTransaction_TransfersCopyWith<$Res> {
  _$NativeMultisigSigningTransaction_TransfersCopyWithImpl(this._self, this._then);

  final NativeMultisigSigningTransaction_Transfers _self;
  final $Res Function(NativeMultisigSigningTransaction_Transfers) _then;

/// Create a copy of NativeMultisigSigningTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transfers = null,}) {
  return _then(NativeMultisigSigningTransaction_Transfers(
transfers: null == transfers ? _self._transfers : transfers // ignore: cast_nullable_to_non_nullable
as List<NativeMultisigSigningTransfer>,
  ));
}


}

/// @nodoc


class NativeMultisigSigningTransaction_Burn extends NativeMultisigSigningTransaction {
  const NativeMultisigSigningTransaction_Burn({required this.asset, required this.amount}): super._();
  

 final  String asset;
 final  BigInt amount;

/// Create a copy of NativeMultisigSigningTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigSigningTransaction_BurnCopyWith<NativeMultisigSigningTransaction_Burn> get copyWith => _$NativeMultisigSigningTransaction_BurnCopyWithImpl<NativeMultisigSigningTransaction_Burn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSigningTransaction_Burn&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,asset,amount);

@override
String toString() {
  return 'NativeMultisigSigningTransaction.burn(asset: $asset, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigSigningTransaction_BurnCopyWith<$Res> implements $NativeMultisigSigningTransactionCopyWith<$Res> {
  factory $NativeMultisigSigningTransaction_BurnCopyWith(NativeMultisigSigningTransaction_Burn value, $Res Function(NativeMultisigSigningTransaction_Burn) _then) = _$NativeMultisigSigningTransaction_BurnCopyWithImpl;
@useResult
$Res call({
 String asset, BigInt amount
});




}
/// @nodoc
class _$NativeMultisigSigningTransaction_BurnCopyWithImpl<$Res>
    implements $NativeMultisigSigningTransaction_BurnCopyWith<$Res> {
  _$NativeMultisigSigningTransaction_BurnCopyWithImpl(this._self, this._then);

  final NativeMultisigSigningTransaction_Burn _self;
  final $Res Function(NativeMultisigSigningTransaction_Burn) _then;

/// Create a copy of NativeMultisigSigningTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,Object? amount = null,}) {
  return _then(NativeMultisigSigningTransaction_Burn(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeMultisigSigningTransaction_DeleteMultisig extends NativeMultisigSigningTransaction {
  const NativeMultisigSigningTransaction_DeleteMultisig(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSigningTransaction_DeleteMultisig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeMultisigSigningTransaction.deleteMultisig()';
}


}




/// @nodoc
mixin _$NativeMultisigSigningTransfer {

 BigInt get amount; String get asset; String get destination; bool get hasExtraData;
/// Create a copy of NativeMultisigSigningTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigSigningTransferCopyWith<NativeMultisigSigningTransfer> get copyWith => _$NativeMultisigSigningTransferCopyWithImpl<NativeMultisigSigningTransfer>(this as NativeMultisigSigningTransfer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigSigningTransfer&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.hasExtraData, hasExtraData) || other.hasExtraData == hasExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,amount,asset,destination,hasExtraData);

@override
String toString() {
  return 'NativeMultisigSigningTransfer(amount: $amount, asset: $asset, destination: $destination, hasExtraData: $hasExtraData)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigSigningTransferCopyWith<$Res>  {
  factory $NativeMultisigSigningTransferCopyWith(NativeMultisigSigningTransfer value, $Res Function(NativeMultisigSigningTransfer) _then) = _$NativeMultisigSigningTransferCopyWithImpl;
@useResult
$Res call({
 BigInt amount, String asset, String destination, bool hasExtraData
});




}
/// @nodoc
class _$NativeMultisigSigningTransferCopyWithImpl<$Res>
    implements $NativeMultisigSigningTransferCopyWith<$Res> {
  _$NativeMultisigSigningTransferCopyWithImpl(this._self, this._then);

  final NativeMultisigSigningTransfer _self;
  final $Res Function(NativeMultisigSigningTransfer) _then;

/// Create a copy of NativeMultisigSigningTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? asset = null,Object? destination = null,Object? hasExtraData = null,}) {
  return _then(NativeMultisigSigningTransfer(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,hasExtraData: null == hasExtraData ? _self.hasExtraData : hasExtraData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeMultisigSigningTransfer].
extension NativeMultisigSigningTransferPatterns on NativeMultisigSigningTransfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeMultisigSigningTransfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeMultisigSigningTransfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeMultisigSigningTransfer value)  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigSigningTransfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeMultisigSigningTransfer value)?  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigSigningTransfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt amount,  String asset,  String destination,  bool hasExtraData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeMultisigSigningTransfer() when $default != null:
return $default(_that.amount,_that.asset,_that.destination,_that.hasExtraData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt amount,  String asset,  String destination,  bool hasExtraData)  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigSigningTransfer():
return $default(_that.amount,_that.asset,_that.destination,_that.hasExtraData);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt amount,  String asset,  String destination,  bool hasExtraData)?  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigSigningTransfer() when $default != null:
return $default(_that.amount,_that.asset,_that.destination,_that.hasExtraData);case _:
  return null;

}
}

}

/// @nodoc


class _NativeMultisigSigningTransfer implements NativeMultisigSigningTransfer {
  const _NativeMultisigSigningTransfer({required this.amount, required this.asset, required this.destination, required this.hasExtraData});
  

@override final  BigInt amount;
@override final  String asset;
@override final  String destination;
@override final  bool hasExtraData;

/// Create a copy of NativeMultisigSigningTransfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeMultisigSigningTransferCopyWith<_NativeMultisigSigningTransfer> get copyWith => __$NativeMultisigSigningTransferCopyWithImpl<_NativeMultisigSigningTransfer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeMultisigSigningTransfer&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.hasExtraData, hasExtraData) || other.hasExtraData == hasExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,amount,asset,destination,hasExtraData);

@override
String toString() {
  return 'NativeMultisigSigningTransfer(amount: $amount, asset: $asset, destination: $destination, hasExtraData: $hasExtraData)';
}


}

/// @nodoc
abstract mixin class _$NativeMultisigSigningTransferCopyWith<$Res> implements $NativeMultisigSigningTransferCopyWith<$Res> {
  factory _$NativeMultisigSigningTransferCopyWith(_NativeMultisigSigningTransfer value, $Res Function(_NativeMultisigSigningTransfer) _then) = __$NativeMultisigSigningTransferCopyWithImpl;
@override @useResult
$Res call({
 BigInt amount, String asset, String destination, bool hasExtraData
});




}
/// @nodoc
class __$NativeMultisigSigningTransferCopyWithImpl<$Res>
    implements _$NativeMultisigSigningTransferCopyWith<$Res> {
  __$NativeMultisigSigningTransferCopyWithImpl(this._self, this._then);

  final _NativeMultisigSigningTransfer _self;
  final $Res Function(_NativeMultisigSigningTransfer) _then;

/// Create a copy of NativeMultisigSigningTransfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? asset = null,Object? destination = null,Object? hasExtraData = null,}) {
  return _then(_NativeMultisigSigningTransfer(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,hasExtraData: null == hasExtraData ? _self.hasExtraData : hasExtraData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$NativeMultisigState {

 int get threshold; List<NativeMultisigParticipant> get participants; BigInt get topoheight;
/// Create a copy of NativeMultisigState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeMultisigStateCopyWith<NativeMultisigState> get copyWith => _$NativeMultisigStateCopyWithImpl<NativeMultisigState>(this as NativeMultisigState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeMultisigState&&(identical(other.threshold, threshold) || other.threshold == threshold)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.topoheight, topoheight) || other.topoheight == topoheight));
}


@override
int get hashCode => Object.hash(runtimeType,threshold,const DeepCollectionEquality().hash(participants),topoheight);

@override
String toString() {
  return 'NativeMultisigState(threshold: $threshold, participants: $participants, topoheight: $topoheight)';
}


}

/// @nodoc
abstract mixin class $NativeMultisigStateCopyWith<$Res>  {
  factory $NativeMultisigStateCopyWith(NativeMultisigState value, $Res Function(NativeMultisigState) _then) = _$NativeMultisigStateCopyWithImpl;
@useResult
$Res call({
 int threshold, List<NativeMultisigParticipant> participants, BigInt topoheight
});




}
/// @nodoc
class _$NativeMultisigStateCopyWithImpl<$Res>
    implements $NativeMultisigStateCopyWith<$Res> {
  _$NativeMultisigStateCopyWithImpl(this._self, this._then);

  final NativeMultisigState _self;
  final $Res Function(NativeMultisigState) _then;

/// Create a copy of NativeMultisigState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? threshold = null,Object? participants = null,Object? topoheight = null,}) {
  return _then(NativeMultisigState(
threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<NativeMultisigParticipant>,topoheight: null == topoheight ? _self.topoheight : topoheight // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeMultisigState].
extension NativeMultisigStatePatterns on NativeMultisigState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeMultisigState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeMultisigState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeMultisigState value)  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeMultisigState value)?  $default,){
final _that = this;
switch (_that) {
case _NativeMultisigState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int threshold,  List<NativeMultisigParticipant> participants,  BigInt topoheight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeMultisigState() when $default != null:
return $default(_that.threshold,_that.participants,_that.topoheight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int threshold,  List<NativeMultisigParticipant> participants,  BigInt topoheight)  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigState():
return $default(_that.threshold,_that.participants,_that.topoheight);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int threshold,  List<NativeMultisigParticipant> participants,  BigInt topoheight)?  $default,) {final _that = this;
switch (_that) {
case _NativeMultisigState() when $default != null:
return $default(_that.threshold,_that.participants,_that.topoheight);case _:
  return null;

}
}

}

/// @nodoc


class _NativeMultisigState implements NativeMultisigState {
  const _NativeMultisigState({required this.threshold, required  List<NativeMultisigParticipant> participants, required this.topoheight}): _participants = participants;
  

@override final  int threshold;
 final  List<NativeMultisigParticipant> _participants;
@override List<NativeMultisigParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

@override final  BigInt topoheight;

/// Create a copy of NativeMultisigState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeMultisigStateCopyWith<_NativeMultisigState> get copyWith => __$NativeMultisigStateCopyWithImpl<_NativeMultisigState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeMultisigState&&(identical(other.threshold, threshold) || other.threshold == threshold)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.topoheight, topoheight) || other.topoheight == topoheight));
}


@override
int get hashCode => Object.hash(runtimeType,threshold,const DeepCollectionEquality().hash(_participants),topoheight);

@override
String toString() {
  return 'NativeMultisigState(threshold: $threshold, participants: $participants, topoheight: $topoheight)';
}


}

/// @nodoc
abstract mixin class _$NativeMultisigStateCopyWith<$Res> implements $NativeMultisigStateCopyWith<$Res> {
  factory _$NativeMultisigStateCopyWith(_NativeMultisigState value, $Res Function(_NativeMultisigState) _then) = __$NativeMultisigStateCopyWithImpl;
@override @useResult
$Res call({
 int threshold, List<NativeMultisigParticipant> participants, BigInt topoheight
});




}
/// @nodoc
class __$NativeMultisigStateCopyWithImpl<$Res>
    implements _$NativeMultisigStateCopyWith<$Res> {
  __$NativeMultisigStateCopyWithImpl(this._self, this._then);

  final _NativeMultisigState _self;
  final $Res Function(_NativeMultisigState) _then;

/// Create a copy of NativeMultisigState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? threshold = null,Object? participants = null,Object? topoheight = null,}) {
  return _then(_NativeMultisigState(
threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<NativeMultisigParticipant>,topoheight: null == topoheight ? _self.topoheight : topoheight // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc
mixin _$NativePreparedTransaction {

 String get hash; BigInt get preparationId; BigInt get fee; NativePreparedTransactionKind get transaction;
/// Create a copy of NativePreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionCopyWith<NativePreparedTransaction> get copyWith => _$NativePreparedTransactionCopyWithImpl<NativePreparedTransaction>(this as NativePreparedTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransaction&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.preparationId, preparationId) || other.preparationId == preparationId)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,hash,preparationId,fee,transaction);

@override
String toString() {
  return 'NativePreparedTransaction(hash: $hash, preparationId: $preparationId, fee: $fee, transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionCopyWith<$Res>  {
  factory $NativePreparedTransactionCopyWith(NativePreparedTransaction value, $Res Function(NativePreparedTransaction) _then) = _$NativePreparedTransactionCopyWithImpl;
@useResult
$Res call({
 String hash, BigInt preparationId, BigInt fee, NativePreparedTransactionKind transaction
});


$NativePreparedTransactionKindCopyWith<$Res> get transaction;

}
/// @nodoc
class _$NativePreparedTransactionCopyWithImpl<$Res>
    implements $NativePreparedTransactionCopyWith<$Res> {
  _$NativePreparedTransactionCopyWithImpl(this._self, this._then);

  final NativePreparedTransaction _self;
  final $Res Function(NativePreparedTransaction) _then;

/// Create a copy of NativePreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hash = null,Object? preparationId = null,Object? fee = null,Object? transaction = null,}) {
  return _then(NativePreparedTransaction(
hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,preparationId: null == preparationId ? _self.preparationId : preparationId // ignore: cast_nullable_to_non_nullable
as BigInt,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativePreparedTransactionKind,
  ));
}
/// Create a copy of NativePreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativePreparedTransactionKindCopyWith<$Res> get transaction {
  
  return $NativePreparedTransactionKindCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativePreparedTransaction].
extension NativePreparedTransactionPatterns on NativePreparedTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativePreparedTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativePreparedTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativePreparedTransaction value)  $default,){
final _that = this;
switch (_that) {
case _NativePreparedTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativePreparedTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _NativePreparedTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String hash,  BigInt preparationId,  BigInt fee,  NativePreparedTransactionKind transaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativePreparedTransaction() when $default != null:
return $default(_that.hash,_that.preparationId,_that.fee,_that.transaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String hash,  BigInt preparationId,  BigInt fee,  NativePreparedTransactionKind transaction)  $default,) {final _that = this;
switch (_that) {
case _NativePreparedTransaction():
return $default(_that.hash,_that.preparationId,_that.fee,_that.transaction);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String hash,  BigInt preparationId,  BigInt fee,  NativePreparedTransactionKind transaction)?  $default,) {final _that = this;
switch (_that) {
case _NativePreparedTransaction() when $default != null:
return $default(_that.hash,_that.preparationId,_that.fee,_that.transaction);case _:
  return null;

}
}

}

/// @nodoc


class _NativePreparedTransaction implements NativePreparedTransaction {
  const _NativePreparedTransaction({required this.hash, required this.preparationId, required this.fee, required this.transaction});
  

@override final  String hash;
@override final  BigInt preparationId;
@override final  BigInt fee;
@override final  NativePreparedTransactionKind transaction;

/// Create a copy of NativePreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativePreparedTransactionCopyWith<_NativePreparedTransaction> get copyWith => __$NativePreparedTransactionCopyWithImpl<_NativePreparedTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativePreparedTransaction&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.preparationId, preparationId) || other.preparationId == preparationId)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,hash,preparationId,fee,transaction);

@override
String toString() {
  return 'NativePreparedTransaction(hash: $hash, preparationId: $preparationId, fee: $fee, transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class _$NativePreparedTransactionCopyWith<$Res> implements $NativePreparedTransactionCopyWith<$Res> {
  factory _$NativePreparedTransactionCopyWith(_NativePreparedTransaction value, $Res Function(_NativePreparedTransaction) _then) = __$NativePreparedTransactionCopyWithImpl;
@override @useResult
$Res call({
 String hash, BigInt preparationId, BigInt fee, NativePreparedTransactionKind transaction
});


@override $NativePreparedTransactionKindCopyWith<$Res> get transaction;

}
/// @nodoc
class __$NativePreparedTransactionCopyWithImpl<$Res>
    implements _$NativePreparedTransactionCopyWith<$Res> {
  __$NativePreparedTransactionCopyWithImpl(this._self, this._then);

  final _NativePreparedTransaction _self;
  final $Res Function(_NativePreparedTransaction) _then;

/// Create a copy of NativePreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hash = null,Object? preparationId = null,Object? fee = null,Object? transaction = null,}) {
  return _then(_NativePreparedTransaction(
hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,preparationId: null == preparationId ? _self.preparationId : preparationId // ignore: cast_nullable_to_non_nullable
as BigInt,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativePreparedTransactionKind,
  ));
}

/// Create a copy of NativePreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativePreparedTransactionKindCopyWith<$Res> get transaction {
  
  return $NativePreparedTransactionKindCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

/// @nodoc
mixin _$NativePreparedTransactionBroadcastOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionBroadcastOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativePreparedTransactionBroadcastOutcome()';
}


}

/// @nodoc
class $NativePreparedTransactionBroadcastOutcomeCopyWith<$Res>  {
$NativePreparedTransactionBroadcastOutcomeCopyWith(NativePreparedTransactionBroadcastOutcome _, $Res Function(NativePreparedTransactionBroadcastOutcome) __);
}


/// Adds pattern-matching-related methods to [NativePreparedTransactionBroadcastOutcome].
extension NativePreparedTransactionBroadcastOutcomePatterns on NativePreparedTransactionBroadcastOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativePreparedTransactionBroadcastOutcome_Submitted value)?  submitted,TResult Function( NativePreparedTransactionBroadcastOutcome_Retryable value)?  retryable,TResult Function( NativePreparedTransactionBroadcastOutcome_Rejected value)?  rejected,TResult Function( NativePreparedTransactionBroadcastOutcome_LocalFailure value)?  localFailure,TResult Function( NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync value)?  submittedNeedsResync,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativePreparedTransactionBroadcastOutcome_Submitted() when submitted != null:
return submitted(_that);case NativePreparedTransactionBroadcastOutcome_Retryable() when retryable != null:
return retryable(_that);case NativePreparedTransactionBroadcastOutcome_Rejected() when rejected != null:
return rejected(_that);case NativePreparedTransactionBroadcastOutcome_LocalFailure() when localFailure != null:
return localFailure(_that);case NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync() when submittedNeedsResync != null:
return submittedNeedsResync(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativePreparedTransactionBroadcastOutcome_Submitted value)  submitted,required TResult Function( NativePreparedTransactionBroadcastOutcome_Retryable value)  retryable,required TResult Function( NativePreparedTransactionBroadcastOutcome_Rejected value)  rejected,required TResult Function( NativePreparedTransactionBroadcastOutcome_LocalFailure value)  localFailure,required TResult Function( NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync value)  submittedNeedsResync,}){
final _that = this;
switch (_that) {
case NativePreparedTransactionBroadcastOutcome_Submitted():
return submitted(_that);case NativePreparedTransactionBroadcastOutcome_Retryable():
return retryable(_that);case NativePreparedTransactionBroadcastOutcome_Rejected():
return rejected(_that);case NativePreparedTransactionBroadcastOutcome_LocalFailure():
return localFailure(_that);case NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync():
return submittedNeedsResync(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativePreparedTransactionBroadcastOutcome_Submitted value)?  submitted,TResult? Function( NativePreparedTransactionBroadcastOutcome_Retryable value)?  retryable,TResult? Function( NativePreparedTransactionBroadcastOutcome_Rejected value)?  rejected,TResult? Function( NativePreparedTransactionBroadcastOutcome_LocalFailure value)?  localFailure,TResult? Function( NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync value)?  submittedNeedsResync,}){
final _that = this;
switch (_that) {
case NativePreparedTransactionBroadcastOutcome_Submitted() when submitted != null:
return submitted(_that);case NativePreparedTransactionBroadcastOutcome_Retryable() when retryable != null:
return retryable(_that);case NativePreparedTransactionBroadcastOutcome_Rejected() when rejected != null:
return rejected(_that);case NativePreparedTransactionBroadcastOutcome_LocalFailure() when localFailure != null:
return localFailure(_that);case NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync() when submittedNeedsResync != null:
return submittedNeedsResync(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  submitted,TResult Function( NativeXelisError failure)?  retryable,TResult Function( NativeXelisError failure)?  rejected,TResult Function( NativeXelisError failure)?  localFailure,TResult Function( NativeXelisError failure)?  submittedNeedsResync,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativePreparedTransactionBroadcastOutcome_Submitted() when submitted != null:
return submitted();case NativePreparedTransactionBroadcastOutcome_Retryable() when retryable != null:
return retryable(_that.failure);case NativePreparedTransactionBroadcastOutcome_Rejected() when rejected != null:
return rejected(_that.failure);case NativePreparedTransactionBroadcastOutcome_LocalFailure() when localFailure != null:
return localFailure(_that.failure);case NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync() when submittedNeedsResync != null:
return submittedNeedsResync(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  submitted,required TResult Function( NativeXelisError failure)  retryable,required TResult Function( NativeXelisError failure)  rejected,required TResult Function( NativeXelisError failure)  localFailure,required TResult Function( NativeXelisError failure)  submittedNeedsResync,}) {final _that = this;
switch (_that) {
case NativePreparedTransactionBroadcastOutcome_Submitted():
return submitted();case NativePreparedTransactionBroadcastOutcome_Retryable():
return retryable(_that.failure);case NativePreparedTransactionBroadcastOutcome_Rejected():
return rejected(_that.failure);case NativePreparedTransactionBroadcastOutcome_LocalFailure():
return localFailure(_that.failure);case NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync():
return submittedNeedsResync(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  submitted,TResult? Function( NativeXelisError failure)?  retryable,TResult? Function( NativeXelisError failure)?  rejected,TResult? Function( NativeXelisError failure)?  localFailure,TResult? Function( NativeXelisError failure)?  submittedNeedsResync,}) {final _that = this;
switch (_that) {
case NativePreparedTransactionBroadcastOutcome_Submitted() when submitted != null:
return submitted();case NativePreparedTransactionBroadcastOutcome_Retryable() when retryable != null:
return retryable(_that.failure);case NativePreparedTransactionBroadcastOutcome_Rejected() when rejected != null:
return rejected(_that.failure);case NativePreparedTransactionBroadcastOutcome_LocalFailure() when localFailure != null:
return localFailure(_that.failure);case NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync() when submittedNeedsResync != null:
return submittedNeedsResync(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class NativePreparedTransactionBroadcastOutcome_Submitted extends NativePreparedTransactionBroadcastOutcome {
  const NativePreparedTransactionBroadcastOutcome_Submitted(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionBroadcastOutcome_Submitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativePreparedTransactionBroadcastOutcome.submitted()';
}


}




/// @nodoc


class NativePreparedTransactionBroadcastOutcome_Retryable extends NativePreparedTransactionBroadcastOutcome {
  const NativePreparedTransactionBroadcastOutcome_Retryable({required this.failure}): super._();
  

 final  NativeXelisError failure;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionBroadcastOutcome_RetryableCopyWith<NativePreparedTransactionBroadcastOutcome_Retryable> get copyWith => _$NativePreparedTransactionBroadcastOutcome_RetryableCopyWithImpl<NativePreparedTransactionBroadcastOutcome_Retryable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionBroadcastOutcome_Retryable&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NativePreparedTransactionBroadcastOutcome.retryable(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionBroadcastOutcome_RetryableCopyWith<$Res> implements $NativePreparedTransactionBroadcastOutcomeCopyWith<$Res> {
  factory $NativePreparedTransactionBroadcastOutcome_RetryableCopyWith(NativePreparedTransactionBroadcastOutcome_Retryable value, $Res Function(NativePreparedTransactionBroadcastOutcome_Retryable) _then) = _$NativePreparedTransactionBroadcastOutcome_RetryableCopyWithImpl;
@useResult
$Res call({
 NativeXelisError failure
});




}
/// @nodoc
class _$NativePreparedTransactionBroadcastOutcome_RetryableCopyWithImpl<$Res>
    implements $NativePreparedTransactionBroadcastOutcome_RetryableCopyWith<$Res> {
  _$NativePreparedTransactionBroadcastOutcome_RetryableCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionBroadcastOutcome_Retryable _self;
  final $Res Function(NativePreparedTransactionBroadcastOutcome_Retryable) _then;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NativePreparedTransactionBroadcastOutcome_Retryable(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc


class NativePreparedTransactionBroadcastOutcome_Rejected extends NativePreparedTransactionBroadcastOutcome {
  const NativePreparedTransactionBroadcastOutcome_Rejected({required this.failure}): super._();
  

 final  NativeXelisError failure;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionBroadcastOutcome_RejectedCopyWith<NativePreparedTransactionBroadcastOutcome_Rejected> get copyWith => _$NativePreparedTransactionBroadcastOutcome_RejectedCopyWithImpl<NativePreparedTransactionBroadcastOutcome_Rejected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionBroadcastOutcome_Rejected&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NativePreparedTransactionBroadcastOutcome.rejected(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionBroadcastOutcome_RejectedCopyWith<$Res> implements $NativePreparedTransactionBroadcastOutcomeCopyWith<$Res> {
  factory $NativePreparedTransactionBroadcastOutcome_RejectedCopyWith(NativePreparedTransactionBroadcastOutcome_Rejected value, $Res Function(NativePreparedTransactionBroadcastOutcome_Rejected) _then) = _$NativePreparedTransactionBroadcastOutcome_RejectedCopyWithImpl;
@useResult
$Res call({
 NativeXelisError failure
});




}
/// @nodoc
class _$NativePreparedTransactionBroadcastOutcome_RejectedCopyWithImpl<$Res>
    implements $NativePreparedTransactionBroadcastOutcome_RejectedCopyWith<$Res> {
  _$NativePreparedTransactionBroadcastOutcome_RejectedCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionBroadcastOutcome_Rejected _self;
  final $Res Function(NativePreparedTransactionBroadcastOutcome_Rejected) _then;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NativePreparedTransactionBroadcastOutcome_Rejected(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc


class NativePreparedTransactionBroadcastOutcome_LocalFailure extends NativePreparedTransactionBroadcastOutcome {
  const NativePreparedTransactionBroadcastOutcome_LocalFailure({required this.failure}): super._();
  

 final  NativeXelisError failure;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWith<NativePreparedTransactionBroadcastOutcome_LocalFailure> get copyWith => _$NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWithImpl<NativePreparedTransactionBroadcastOutcome_LocalFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionBroadcastOutcome_LocalFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NativePreparedTransactionBroadcastOutcome.localFailure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWith<$Res> implements $NativePreparedTransactionBroadcastOutcomeCopyWith<$Res> {
  factory $NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWith(NativePreparedTransactionBroadcastOutcome_LocalFailure value, $Res Function(NativePreparedTransactionBroadcastOutcome_LocalFailure) _then) = _$NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWithImpl;
@useResult
$Res call({
 NativeXelisError failure
});




}
/// @nodoc
class _$NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWithImpl<$Res>
    implements $NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWith<$Res> {
  _$NativePreparedTransactionBroadcastOutcome_LocalFailureCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionBroadcastOutcome_LocalFailure _self;
  final $Res Function(NativePreparedTransactionBroadcastOutcome_LocalFailure) _then;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NativePreparedTransactionBroadcastOutcome_LocalFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc


class NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync extends NativePreparedTransactionBroadcastOutcome {
  const NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync({required this.failure}): super._();
  

 final  NativeXelisError failure;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWith<NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync> get copyWith => _$NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWithImpl<NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NativePreparedTransactionBroadcastOutcome.submittedNeedsResync(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWith<$Res> implements $NativePreparedTransactionBroadcastOutcomeCopyWith<$Res> {
  factory $NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWith(NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync value, $Res Function(NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync) _then) = _$NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWithImpl;
@useResult
$Res call({
 NativeXelisError failure
});




}
/// @nodoc
class _$NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWithImpl<$Res>
    implements $NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWith<$Res> {
  _$NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResyncCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync _self;
  final $Res Function(NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync) _then;

/// Create a copy of NativePreparedTransactionBroadcastOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NativePreparedTransactionBroadcastOutcome_SubmittedNeedsResync(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc
mixin _$NativePreparedTransactionKind {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionKind);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativePreparedTransactionKind()';
}


}

/// @nodoc
class $NativePreparedTransactionKindCopyWith<$Res>  {
$NativePreparedTransactionKindCopyWith(NativePreparedTransactionKind _, $Res Function(NativePreparedTransactionKind) __);
}


/// Adds pattern-matching-related methods to [NativePreparedTransactionKind].
extension NativePreparedTransactionKindPatterns on NativePreparedTransactionKind {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativePreparedTransactionKind_Transfers value)?  transfers,TResult Function( NativePreparedTransactionKind_Burn value)?  burn,TResult Function( NativePreparedTransactionKind_MultisigSetup value)?  multisigSetup,TResult Function( NativePreparedTransactionKind_MultisigFinalized value)?  multisigFinalized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativePreparedTransactionKind_Transfers() when transfers != null:
return transfers(_that);case NativePreparedTransactionKind_Burn() when burn != null:
return burn(_that);case NativePreparedTransactionKind_MultisigSetup() when multisigSetup != null:
return multisigSetup(_that);case NativePreparedTransactionKind_MultisigFinalized() when multisigFinalized != null:
return multisigFinalized(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativePreparedTransactionKind_Transfers value)  transfers,required TResult Function( NativePreparedTransactionKind_Burn value)  burn,required TResult Function( NativePreparedTransactionKind_MultisigSetup value)  multisigSetup,required TResult Function( NativePreparedTransactionKind_MultisigFinalized value)  multisigFinalized,}){
final _that = this;
switch (_that) {
case NativePreparedTransactionKind_Transfers():
return transfers(_that);case NativePreparedTransactionKind_Burn():
return burn(_that);case NativePreparedTransactionKind_MultisigSetup():
return multisigSetup(_that);case NativePreparedTransactionKind_MultisigFinalized():
return multisigFinalized(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativePreparedTransactionKind_Transfers value)?  transfers,TResult? Function( NativePreparedTransactionKind_Burn value)?  burn,TResult? Function( NativePreparedTransactionKind_MultisigSetup value)?  multisigSetup,TResult? Function( NativePreparedTransactionKind_MultisigFinalized value)?  multisigFinalized,}){
final _that = this;
switch (_that) {
case NativePreparedTransactionKind_Transfers() when transfers != null:
return transfers(_that);case NativePreparedTransactionKind_Burn() when burn != null:
return burn(_that);case NativePreparedTransactionKind_MultisigSetup() when multisigSetup != null:
return multisigSetup(_that);case NativePreparedTransactionKind_MultisigFinalized() when multisigFinalized != null:
return multisigFinalized(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<NativePreparedTransfer> transfers)?  transfers,TResult Function( String asset,  BigInt amount)?  burn,TResult Function( int threshold,  List<NativeMultisigParticipant> participants)?  multisigSetup,TResult Function( NativeMultisigSigningTransaction transaction)?  multisigFinalized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativePreparedTransactionKind_Transfers() when transfers != null:
return transfers(_that.transfers);case NativePreparedTransactionKind_Burn() when burn != null:
return burn(_that.asset,_that.amount);case NativePreparedTransactionKind_MultisigSetup() when multisigSetup != null:
return multisigSetup(_that.threshold,_that.participants);case NativePreparedTransactionKind_MultisigFinalized() when multisigFinalized != null:
return multisigFinalized(_that.transaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<NativePreparedTransfer> transfers)  transfers,required TResult Function( String asset,  BigInt amount)  burn,required TResult Function( int threshold,  List<NativeMultisigParticipant> participants)  multisigSetup,required TResult Function( NativeMultisigSigningTransaction transaction)  multisigFinalized,}) {final _that = this;
switch (_that) {
case NativePreparedTransactionKind_Transfers():
return transfers(_that.transfers);case NativePreparedTransactionKind_Burn():
return burn(_that.asset,_that.amount);case NativePreparedTransactionKind_MultisigSetup():
return multisigSetup(_that.threshold,_that.participants);case NativePreparedTransactionKind_MultisigFinalized():
return multisigFinalized(_that.transaction);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<NativePreparedTransfer> transfers)?  transfers,TResult? Function( String asset,  BigInt amount)?  burn,TResult? Function( int threshold,  List<NativeMultisigParticipant> participants)?  multisigSetup,TResult? Function( NativeMultisigSigningTransaction transaction)?  multisigFinalized,}) {final _that = this;
switch (_that) {
case NativePreparedTransactionKind_Transfers() when transfers != null:
return transfers(_that.transfers);case NativePreparedTransactionKind_Burn() when burn != null:
return burn(_that.asset,_that.amount);case NativePreparedTransactionKind_MultisigSetup() when multisigSetup != null:
return multisigSetup(_that.threshold,_that.participants);case NativePreparedTransactionKind_MultisigFinalized() when multisigFinalized != null:
return multisigFinalized(_that.transaction);case _:
  return null;

}
}

}

/// @nodoc


class NativePreparedTransactionKind_Transfers extends NativePreparedTransactionKind {
  const NativePreparedTransactionKind_Transfers({required  List<NativePreparedTransfer> transfers}): _transfers = transfers,super._();
  

 final  List<NativePreparedTransfer> _transfers;
 List<NativePreparedTransfer> get transfers {
  if (_transfers is EqualUnmodifiableListView) return _transfers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transfers);
}


/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionKind_TransfersCopyWith<NativePreparedTransactionKind_Transfers> get copyWith => _$NativePreparedTransactionKind_TransfersCopyWithImpl<NativePreparedTransactionKind_Transfers>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionKind_Transfers&&const DeepCollectionEquality().equals(other._transfers, _transfers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transfers));

@override
String toString() {
  return 'NativePreparedTransactionKind.transfers(transfers: $transfers)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionKind_TransfersCopyWith<$Res> implements $NativePreparedTransactionKindCopyWith<$Res> {
  factory $NativePreparedTransactionKind_TransfersCopyWith(NativePreparedTransactionKind_Transfers value, $Res Function(NativePreparedTransactionKind_Transfers) _then) = _$NativePreparedTransactionKind_TransfersCopyWithImpl;
@useResult
$Res call({
 List<NativePreparedTransfer> transfers
});




}
/// @nodoc
class _$NativePreparedTransactionKind_TransfersCopyWithImpl<$Res>
    implements $NativePreparedTransactionKind_TransfersCopyWith<$Res> {
  _$NativePreparedTransactionKind_TransfersCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionKind_Transfers _self;
  final $Res Function(NativePreparedTransactionKind_Transfers) _then;

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transfers = null,}) {
  return _then(NativePreparedTransactionKind_Transfers(
transfers: null == transfers ? _self._transfers : transfers // ignore: cast_nullable_to_non_nullable
as List<NativePreparedTransfer>,
  ));
}


}

/// @nodoc


class NativePreparedTransactionKind_Burn extends NativePreparedTransactionKind {
  const NativePreparedTransactionKind_Burn({required this.asset, required this.amount}): super._();
  

 final  String asset;
 final  BigInt amount;

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionKind_BurnCopyWith<NativePreparedTransactionKind_Burn> get copyWith => _$NativePreparedTransactionKind_BurnCopyWithImpl<NativePreparedTransactionKind_Burn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionKind_Burn&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,asset,amount);

@override
String toString() {
  return 'NativePreparedTransactionKind.burn(asset: $asset, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionKind_BurnCopyWith<$Res> implements $NativePreparedTransactionKindCopyWith<$Res> {
  factory $NativePreparedTransactionKind_BurnCopyWith(NativePreparedTransactionKind_Burn value, $Res Function(NativePreparedTransactionKind_Burn) _then) = _$NativePreparedTransactionKind_BurnCopyWithImpl;
@useResult
$Res call({
 String asset, BigInt amount
});




}
/// @nodoc
class _$NativePreparedTransactionKind_BurnCopyWithImpl<$Res>
    implements $NativePreparedTransactionKind_BurnCopyWith<$Res> {
  _$NativePreparedTransactionKind_BurnCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionKind_Burn _self;
  final $Res Function(NativePreparedTransactionKind_Burn) _then;

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,Object? amount = null,}) {
  return _then(NativePreparedTransactionKind_Burn(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativePreparedTransactionKind_MultisigSetup extends NativePreparedTransactionKind {
  const NativePreparedTransactionKind_MultisigSetup({required this.threshold, required  List<NativeMultisigParticipant> participants}): _participants = participants,super._();
  

 final  int threshold;
 final  List<NativeMultisigParticipant> _participants;
 List<NativeMultisigParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionKind_MultisigSetupCopyWith<NativePreparedTransactionKind_MultisigSetup> get copyWith => _$NativePreparedTransactionKind_MultisigSetupCopyWithImpl<NativePreparedTransactionKind_MultisigSetup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionKind_MultisigSetup&&(identical(other.threshold, threshold) || other.threshold == threshold)&&const DeepCollectionEquality().equals(other._participants, _participants));
}


@override
int get hashCode => Object.hash(runtimeType,threshold,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'NativePreparedTransactionKind.multisigSetup(threshold: $threshold, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionKind_MultisigSetupCopyWith<$Res> implements $NativePreparedTransactionKindCopyWith<$Res> {
  factory $NativePreparedTransactionKind_MultisigSetupCopyWith(NativePreparedTransactionKind_MultisigSetup value, $Res Function(NativePreparedTransactionKind_MultisigSetup) _then) = _$NativePreparedTransactionKind_MultisigSetupCopyWithImpl;
@useResult
$Res call({
 int threshold, List<NativeMultisigParticipant> participants
});




}
/// @nodoc
class _$NativePreparedTransactionKind_MultisigSetupCopyWithImpl<$Res>
    implements $NativePreparedTransactionKind_MultisigSetupCopyWith<$Res> {
  _$NativePreparedTransactionKind_MultisigSetupCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionKind_MultisigSetup _self;
  final $Res Function(NativePreparedTransactionKind_MultisigSetup) _then;

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? threshold = null,Object? participants = null,}) {
  return _then(NativePreparedTransactionKind_MultisigSetup(
threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<NativeMultisigParticipant>,
  ));
}


}

/// @nodoc


class NativePreparedTransactionKind_MultisigFinalized extends NativePreparedTransactionKind {
  const NativePreparedTransactionKind_MultisigFinalized({required this.transaction}): super._();
  

 final  NativeMultisigSigningTransaction transaction;

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransactionKind_MultisigFinalizedCopyWith<NativePreparedTransactionKind_MultisigFinalized> get copyWith => _$NativePreparedTransactionKind_MultisigFinalizedCopyWithImpl<NativePreparedTransactionKind_MultisigFinalized>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransactionKind_MultisigFinalized&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,transaction);

@override
String toString() {
  return 'NativePreparedTransactionKind.multisigFinalized(transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransactionKind_MultisigFinalizedCopyWith<$Res> implements $NativePreparedTransactionKindCopyWith<$Res> {
  factory $NativePreparedTransactionKind_MultisigFinalizedCopyWith(NativePreparedTransactionKind_MultisigFinalized value, $Res Function(NativePreparedTransactionKind_MultisigFinalized) _then) = _$NativePreparedTransactionKind_MultisigFinalizedCopyWithImpl;
@useResult
$Res call({
 NativeMultisigSigningTransaction transaction
});


$NativeMultisigSigningTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class _$NativePreparedTransactionKind_MultisigFinalizedCopyWithImpl<$Res>
    implements $NativePreparedTransactionKind_MultisigFinalizedCopyWith<$Res> {
  _$NativePreparedTransactionKind_MultisigFinalizedCopyWithImpl(this._self, this._then);

  final NativePreparedTransactionKind_MultisigFinalized _self;
  final $Res Function(NativePreparedTransactionKind_MultisigFinalized) _then;

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transaction = null,}) {
  return _then(NativePreparedTransactionKind_MultisigFinalized(
transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativeMultisigSigningTransaction,
  ));
}

/// Create a copy of NativePreparedTransactionKind
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeMultisigSigningTransactionCopyWith<$Res> get transaction {
  
  return $NativeMultisigSigningTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

/// @nodoc
mixin _$NativePreparedTransfer {

 BigInt get amount; String get destination; String get asset; bool get hasExtraData; bool get encryptExtraData;
/// Create a copy of NativePreparedTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransferCopyWith<NativePreparedTransfer> get copyWith => _$NativePreparedTransferCopyWithImpl<NativePreparedTransfer>(this as NativePreparedTransfer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransfer&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.hasExtraData, hasExtraData) || other.hasExtraData == hasExtraData)&&(identical(other.encryptExtraData, encryptExtraData) || other.encryptExtraData == encryptExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,amount,destination,asset,hasExtraData,encryptExtraData);

@override
String toString() {
  return 'NativePreparedTransfer(amount: $amount, destination: $destination, asset: $asset, hasExtraData: $hasExtraData, encryptExtraData: $encryptExtraData)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransferCopyWith<$Res>  {
  factory $NativePreparedTransferCopyWith(NativePreparedTransfer value, $Res Function(NativePreparedTransfer) _then) = _$NativePreparedTransferCopyWithImpl;
@useResult
$Res call({
 BigInt amount, String destination, String asset, bool hasExtraData, bool encryptExtraData
});




}
/// @nodoc
class _$NativePreparedTransferCopyWithImpl<$Res>
    implements $NativePreparedTransferCopyWith<$Res> {
  _$NativePreparedTransferCopyWithImpl(this._self, this._then);

  final NativePreparedTransfer _self;
  final $Res Function(NativePreparedTransfer) _then;

/// Create a copy of NativePreparedTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? destination = null,Object? asset = null,Object? hasExtraData = null,Object? encryptExtraData = null,}) {
  return _then(NativePreparedTransfer(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,hasExtraData: null == hasExtraData ? _self.hasExtraData : hasExtraData // ignore: cast_nullable_to_non_nullable
as bool,encryptExtraData: null == encryptExtraData ? _self.encryptExtraData : encryptExtraData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativePreparedTransfer].
extension NativePreparedTransferPatterns on NativePreparedTransfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativePreparedTransfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativePreparedTransfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativePreparedTransfer value)  $default,){
final _that = this;
switch (_that) {
case _NativePreparedTransfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativePreparedTransfer value)?  $default,){
final _that = this;
switch (_that) {
case _NativePreparedTransfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt amount,  String destination,  String asset,  bool hasExtraData,  bool encryptExtraData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativePreparedTransfer() when $default != null:
return $default(_that.amount,_that.destination,_that.asset,_that.hasExtraData,_that.encryptExtraData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt amount,  String destination,  String asset,  bool hasExtraData,  bool encryptExtraData)  $default,) {final _that = this;
switch (_that) {
case _NativePreparedTransfer():
return $default(_that.amount,_that.destination,_that.asset,_that.hasExtraData,_that.encryptExtraData);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt amount,  String destination,  String asset,  bool hasExtraData,  bool encryptExtraData)?  $default,) {final _that = this;
switch (_that) {
case _NativePreparedTransfer() when $default != null:
return $default(_that.amount,_that.destination,_that.asset,_that.hasExtraData,_that.encryptExtraData);case _:
  return null;

}
}

}

/// @nodoc


class _NativePreparedTransfer implements NativePreparedTransfer {
  const _NativePreparedTransfer({required this.amount, required this.destination, required this.asset, required this.hasExtraData, required this.encryptExtraData});
  

@override final  BigInt amount;
@override final  String destination;
@override final  String asset;
@override final  bool hasExtraData;
@override final  bool encryptExtraData;

/// Create a copy of NativePreparedTransfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativePreparedTransferCopyWith<_NativePreparedTransfer> get copyWith => __$NativePreparedTransferCopyWithImpl<_NativePreparedTransfer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativePreparedTransfer&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.hasExtraData, hasExtraData) || other.hasExtraData == hasExtraData)&&(identical(other.encryptExtraData, encryptExtraData) || other.encryptExtraData == encryptExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,amount,destination,asset,hasExtraData,encryptExtraData);

@override
String toString() {
  return 'NativePreparedTransfer(amount: $amount, destination: $destination, asset: $asset, hasExtraData: $hasExtraData, encryptExtraData: $encryptExtraData)';
}


}

/// @nodoc
abstract mixin class _$NativePreparedTransferCopyWith<$Res> implements $NativePreparedTransferCopyWith<$Res> {
  factory _$NativePreparedTransferCopyWith(_NativePreparedTransfer value, $Res Function(_NativePreparedTransfer) _then) = __$NativePreparedTransferCopyWithImpl;
@override @useResult
$Res call({
 BigInt amount, String destination, String asset, bool hasExtraData, bool encryptExtraData
});




}
/// @nodoc
class __$NativePreparedTransferCopyWithImpl<$Res>
    implements _$NativePreparedTransferCopyWith<$Res> {
  __$NativePreparedTransferCopyWithImpl(this._self, this._then);

  final _NativePreparedTransfer _self;
  final $Res Function(_NativePreparedTransfer) _then;

/// Create a copy of NativePreparedTransfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? destination = null,Object? asset = null,Object? hasExtraData = null,Object? encryptExtraData = null,}) {
  return _then(_NativePreparedTransfer(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,hasExtraData: null == hasExtraData ? _self.hasExtraData : hasExtraData // ignore: cast_nullable_to_non_nullable
as bool,encryptExtraData: null == encryptExtraData ? _self.encryptExtraData : encryptExtraData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$NativePreparedTransferExtraData {

 NativeXelisDataElement get data; NativePreparedExtraDataSource get source; bool get encrypted;
/// Create a copy of NativePreparedTransferExtraData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePreparedTransferExtraDataCopyWith<NativePreparedTransferExtraData> get copyWith => _$NativePreparedTransferExtraDataCopyWithImpl<NativePreparedTransferExtraData>(this as NativePreparedTransferExtraData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePreparedTransferExtraData&&(identical(other.data, data) || other.data == data)&&(identical(other.source, source) || other.source == source)&&(identical(other.encrypted, encrypted) || other.encrypted == encrypted));
}


@override
int get hashCode => Object.hash(runtimeType,data,source,encrypted);

@override
String toString() {
  return 'NativePreparedTransferExtraData(data: $data, source: $source, encrypted: $encrypted)';
}


}

/// @nodoc
abstract mixin class $NativePreparedTransferExtraDataCopyWith<$Res>  {
  factory $NativePreparedTransferExtraDataCopyWith(NativePreparedTransferExtraData value, $Res Function(NativePreparedTransferExtraData) _then) = _$NativePreparedTransferExtraDataCopyWithImpl;
@useResult
$Res call({
 NativeXelisDataElement data, NativePreparedExtraDataSource source, bool encrypted
});


$NativeXelisDataElementCopyWith<$Res> get data;

}
/// @nodoc
class _$NativePreparedTransferExtraDataCopyWithImpl<$Res>
    implements $NativePreparedTransferExtraDataCopyWith<$Res> {
  _$NativePreparedTransferExtraDataCopyWithImpl(this._self, this._then);

  final NativePreparedTransferExtraData _self;
  final $Res Function(NativePreparedTransferExtraData) _then;

/// Create a copy of NativePreparedTransferExtraData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? source = null,Object? encrypted = null,}) {
  return _then(NativePreparedTransferExtraData(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NativeXelisDataElement,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NativePreparedExtraDataSource,encrypted: null == encrypted ? _self.encrypted : encrypted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of NativePreparedTransferExtraData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataElementCopyWith<$Res> get data {
  
  return $NativeXelisDataElementCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativePreparedTransferExtraData].
extension NativePreparedTransferExtraDataPatterns on NativePreparedTransferExtraData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativePreparedTransferExtraData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativePreparedTransferExtraData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativePreparedTransferExtraData value)  $default,){
final _that = this;
switch (_that) {
case _NativePreparedTransferExtraData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativePreparedTransferExtraData value)?  $default,){
final _that = this;
switch (_that) {
case _NativePreparedTransferExtraData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NativeXelisDataElement data,  NativePreparedExtraDataSource source,  bool encrypted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativePreparedTransferExtraData() when $default != null:
return $default(_that.data,_that.source,_that.encrypted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NativeXelisDataElement data,  NativePreparedExtraDataSource source,  bool encrypted)  $default,) {final _that = this;
switch (_that) {
case _NativePreparedTransferExtraData():
return $default(_that.data,_that.source,_that.encrypted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NativeXelisDataElement data,  NativePreparedExtraDataSource source,  bool encrypted)?  $default,) {final _that = this;
switch (_that) {
case _NativePreparedTransferExtraData() when $default != null:
return $default(_that.data,_that.source,_that.encrypted);case _:
  return null;

}
}

}

/// @nodoc


class _NativePreparedTransferExtraData implements NativePreparedTransferExtraData {
  const _NativePreparedTransferExtraData({required this.data, required this.source, required this.encrypted});
  

@override final  NativeXelisDataElement data;
@override final  NativePreparedExtraDataSource source;
@override final  bool encrypted;

/// Create a copy of NativePreparedTransferExtraData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativePreparedTransferExtraDataCopyWith<_NativePreparedTransferExtraData> get copyWith => __$NativePreparedTransferExtraDataCopyWithImpl<_NativePreparedTransferExtraData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativePreparedTransferExtraData&&(identical(other.data, data) || other.data == data)&&(identical(other.source, source) || other.source == source)&&(identical(other.encrypted, encrypted) || other.encrypted == encrypted));
}


@override
int get hashCode => Object.hash(runtimeType,data,source,encrypted);

@override
String toString() {
  return 'NativePreparedTransferExtraData(data: $data, source: $source, encrypted: $encrypted)';
}


}

/// @nodoc
abstract mixin class _$NativePreparedTransferExtraDataCopyWith<$Res> implements $NativePreparedTransferExtraDataCopyWith<$Res> {
  factory _$NativePreparedTransferExtraDataCopyWith(_NativePreparedTransferExtraData value, $Res Function(_NativePreparedTransferExtraData) _then) = __$NativePreparedTransferExtraDataCopyWithImpl;
@override @useResult
$Res call({
 NativeXelisDataElement data, NativePreparedExtraDataSource source, bool encrypted
});


@override $NativeXelisDataElementCopyWith<$Res> get data;

}
/// @nodoc
class __$NativePreparedTransferExtraDataCopyWithImpl<$Res>
    implements _$NativePreparedTransferExtraDataCopyWith<$Res> {
  __$NativePreparedTransferExtraDataCopyWithImpl(this._self, this._then);

  final _NativePreparedTransferExtraData _self;
  final $Res Function(_NativePreparedTransferExtraData) _then;

/// Create a copy of NativePreparedTransferExtraData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? source = null,Object? encrypted = null,}) {
  return _then(_NativePreparedTransferExtraData(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NativeXelisDataElement,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NativePreparedExtraDataSource,encrypted: null == encrypted ? _self.encrypted : encrypted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of NativePreparedTransferExtraData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeXelisDataElementCopyWith<$Res> get data {
  
  return $NativeXelisDataElementCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
mixin _$NativeTransactionFeePolicy {

 int get basisPoints;
/// Create a copy of NativeTransactionFeePolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeTransactionFeePolicyCopyWith<NativeTransactionFeePolicy> get copyWith => _$NativeTransactionFeePolicyCopyWithImpl<NativeTransactionFeePolicy>(this as NativeTransactionFeePolicy, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeTransactionFeePolicy&&(identical(other.basisPoints, basisPoints) || other.basisPoints == basisPoints));
}


@override
int get hashCode => Object.hash(runtimeType,basisPoints);

@override
String toString() {
  return 'NativeTransactionFeePolicy(basisPoints: $basisPoints)';
}


}

/// @nodoc
abstract mixin class $NativeTransactionFeePolicyCopyWith<$Res>  {
  factory $NativeTransactionFeePolicyCopyWith(NativeTransactionFeePolicy value, $Res Function(NativeTransactionFeePolicy) _then) = _$NativeTransactionFeePolicyCopyWithImpl;
@useResult
$Res call({
 int basisPoints
});




}
/// @nodoc
class _$NativeTransactionFeePolicyCopyWithImpl<$Res>
    implements $NativeTransactionFeePolicyCopyWith<$Res> {
  _$NativeTransactionFeePolicyCopyWithImpl(this._self, this._then);

  final NativeTransactionFeePolicy _self;
  final $Res Function(NativeTransactionFeePolicy) _then;

/// Create a copy of NativeTransactionFeePolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? basisPoints = null,}) {
  return _then(NativeTransactionFeePolicy(
basisPoints: null == basisPoints ? _self.basisPoints : basisPoints // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeTransactionFeePolicy].
extension NativeTransactionFeePolicyPatterns on NativeTransactionFeePolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeTransactionFeePolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeTransactionFeePolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeTransactionFeePolicy value)  $default,){
final _that = this;
switch (_that) {
case _NativeTransactionFeePolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeTransactionFeePolicy value)?  $default,){
final _that = this;
switch (_that) {
case _NativeTransactionFeePolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int basisPoints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeTransactionFeePolicy() when $default != null:
return $default(_that.basisPoints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int basisPoints)  $default,) {final _that = this;
switch (_that) {
case _NativeTransactionFeePolicy():
return $default(_that.basisPoints);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int basisPoints)?  $default,) {final _that = this;
switch (_that) {
case _NativeTransactionFeePolicy() when $default != null:
return $default(_that.basisPoints);case _:
  return null;

}
}

}

/// @nodoc


class _NativeTransactionFeePolicy implements NativeTransactionFeePolicy {
  const _NativeTransactionFeePolicy({required this.basisPoints});
  

@override final  int basisPoints;

/// Create a copy of NativeTransactionFeePolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeTransactionFeePolicyCopyWith<_NativeTransactionFeePolicy> get copyWith => __$NativeTransactionFeePolicyCopyWithImpl<_NativeTransactionFeePolicy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeTransactionFeePolicy&&(identical(other.basisPoints, basisPoints) || other.basisPoints == basisPoints));
}


@override
int get hashCode => Object.hash(runtimeType,basisPoints);

@override
String toString() {
  return 'NativeTransactionFeePolicy(basisPoints: $basisPoints)';
}


}

/// @nodoc
abstract mixin class _$NativeTransactionFeePolicyCopyWith<$Res> implements $NativeTransactionFeePolicyCopyWith<$Res> {
  factory _$NativeTransactionFeePolicyCopyWith(_NativeTransactionFeePolicy value, $Res Function(_NativeTransactionFeePolicy) _then) = __$NativeTransactionFeePolicyCopyWithImpl;
@override @useResult
$Res call({
 int basisPoints
});




}
/// @nodoc
class __$NativeTransactionFeePolicyCopyWithImpl<$Res>
    implements _$NativeTransactionFeePolicyCopyWith<$Res> {
  __$NativeTransactionFeePolicyCopyWithImpl(this._self, this._then);

  final _NativeTransactionFeePolicy _self;
  final $Res Function(_NativeTransactionFeePolicy) _then;

/// Create a copy of NativeTransactionFeePolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? basisPoints = null,}) {
  return _then(_NativeTransactionFeePolicy(
basisPoints: null == basisPoints ? _self.basisPoints : basisPoints // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$NativeTransactionTransferRequest {

 BigInt get amount; String get destination; String get asset; String? get extraData; bool get encryptExtraData;
/// Create a copy of NativeTransactionTransferRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeTransactionTransferRequestCopyWith<NativeTransactionTransferRequest> get copyWith => _$NativeTransactionTransferRequestCopyWithImpl<NativeTransactionTransferRequest>(this as NativeTransactionTransferRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeTransactionTransferRequest&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.extraData, extraData) || other.extraData == extraData)&&(identical(other.encryptExtraData, encryptExtraData) || other.encryptExtraData == encryptExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,amount,destination,asset,extraData,encryptExtraData);

@override
String toString() {
  return 'NativeTransactionTransferRequest(amount: $amount, destination: $destination, asset: $asset, extraData: $extraData, encryptExtraData: $encryptExtraData)';
}


}

/// @nodoc
abstract mixin class $NativeTransactionTransferRequestCopyWith<$Res>  {
  factory $NativeTransactionTransferRequestCopyWith(NativeTransactionTransferRequest value, $Res Function(NativeTransactionTransferRequest) _then) = _$NativeTransactionTransferRequestCopyWithImpl;
@useResult
$Res call({
 BigInt amount, String destination, String asset, String? extraData, bool encryptExtraData
});




}
/// @nodoc
class _$NativeTransactionTransferRequestCopyWithImpl<$Res>
    implements $NativeTransactionTransferRequestCopyWith<$Res> {
  _$NativeTransactionTransferRequestCopyWithImpl(this._self, this._then);

  final NativeTransactionTransferRequest _self;
  final $Res Function(NativeTransactionTransferRequest) _then;

/// Create a copy of NativeTransactionTransferRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? destination = null,Object? asset = null,Object? extraData = freezed,Object? encryptExtraData = null,}) {
  return _then(NativeTransactionTransferRequest(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,extraData: freezed == extraData ? _self.extraData : extraData // ignore: cast_nullable_to_non_nullable
as String?,encryptExtraData: null == encryptExtraData ? _self.encryptExtraData : encryptExtraData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeTransactionTransferRequest].
extension NativeTransactionTransferRequestPatterns on NativeTransactionTransferRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeTransactionTransferRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeTransactionTransferRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeTransactionTransferRequest value)  $default,){
final _that = this;
switch (_that) {
case _NativeTransactionTransferRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeTransactionTransferRequest value)?  $default,){
final _that = this;
switch (_that) {
case _NativeTransactionTransferRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt amount,  String destination,  String asset,  String? extraData,  bool encryptExtraData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeTransactionTransferRequest() when $default != null:
return $default(_that.amount,_that.destination,_that.asset,_that.extraData,_that.encryptExtraData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt amount,  String destination,  String asset,  String? extraData,  bool encryptExtraData)  $default,) {final _that = this;
switch (_that) {
case _NativeTransactionTransferRequest():
return $default(_that.amount,_that.destination,_that.asset,_that.extraData,_that.encryptExtraData);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt amount,  String destination,  String asset,  String? extraData,  bool encryptExtraData)?  $default,) {final _that = this;
switch (_that) {
case _NativeTransactionTransferRequest() when $default != null:
return $default(_that.amount,_that.destination,_that.asset,_that.extraData,_that.encryptExtraData);case _:
  return null;

}
}

}

/// @nodoc


class _NativeTransactionTransferRequest implements NativeTransactionTransferRequest {
  const _NativeTransactionTransferRequest({required this.amount, required this.destination, required this.asset, this.extraData, required this.encryptExtraData});
  

@override final  BigInt amount;
@override final  String destination;
@override final  String asset;
@override final  String? extraData;
@override final  bool encryptExtraData;

/// Create a copy of NativeTransactionTransferRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeTransactionTransferRequestCopyWith<_NativeTransactionTransferRequest> get copyWith => __$NativeTransactionTransferRequestCopyWithImpl<_NativeTransactionTransferRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeTransactionTransferRequest&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.extraData, extraData) || other.extraData == extraData)&&(identical(other.encryptExtraData, encryptExtraData) || other.encryptExtraData == encryptExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,amount,destination,asset,extraData,encryptExtraData);

@override
String toString() {
  return 'NativeTransactionTransferRequest(amount: $amount, destination: $destination, asset: $asset, extraData: $extraData, encryptExtraData: $encryptExtraData)';
}


}

/// @nodoc
abstract mixin class _$NativeTransactionTransferRequestCopyWith<$Res> implements $NativeTransactionTransferRequestCopyWith<$Res> {
  factory _$NativeTransactionTransferRequestCopyWith(_NativeTransactionTransferRequest value, $Res Function(_NativeTransactionTransferRequest) _then) = __$NativeTransactionTransferRequestCopyWithImpl;
@override @useResult
$Res call({
 BigInt amount, String destination, String asset, String? extraData, bool encryptExtraData
});




}
/// @nodoc
class __$NativeTransactionTransferRequestCopyWithImpl<$Res>
    implements _$NativeTransactionTransferRequestCopyWith<$Res> {
  __$NativeTransactionTransferRequestCopyWithImpl(this._self, this._then);

  final _NativeTransactionTransferRequest _self;
  final $Res Function(_NativeTransactionTransferRequest) _then;

/// Create a copy of NativeTransactionTransferRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? destination = null,Object? asset = null,Object? extraData = freezed,Object? encryptExtraData = null,}) {
  return _then(_NativeTransactionTransferRequest(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,extraData: freezed == extraData ? _self.extraData : extraData // ignore: cast_nullable_to_non_nullable
as String?,encryptExtraData: null == encryptExtraData ? _self.encryptExtraData : encryptExtraData // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Transfer {

 double get floatAmount; String get strAddress; String get assetHash; String? get extraData; bool? get encryptExtraData;
/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferCopyWith<Transfer> get copyWith => _$TransferCopyWithImpl<Transfer>(this as Transfer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transfer&&(identical(other.floatAmount, floatAmount) || other.floatAmount == floatAmount)&&(identical(other.strAddress, strAddress) || other.strAddress == strAddress)&&(identical(other.assetHash, assetHash) || other.assetHash == assetHash)&&(identical(other.extraData, extraData) || other.extraData == extraData)&&(identical(other.encryptExtraData, encryptExtraData) || other.encryptExtraData == encryptExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,floatAmount,strAddress,assetHash,extraData,encryptExtraData);

@override
String toString() {
  return 'Transfer(floatAmount: $floatAmount, strAddress: $strAddress, assetHash: $assetHash, extraData: $extraData, encryptExtraData: $encryptExtraData)';
}


}

/// @nodoc
abstract mixin class $TransferCopyWith<$Res>  {
  factory $TransferCopyWith(Transfer value, $Res Function(Transfer) _then) = _$TransferCopyWithImpl;
@useResult
$Res call({
 double floatAmount, String strAddress, String assetHash, String? extraData, bool? encryptExtraData
});




}
/// @nodoc
class _$TransferCopyWithImpl<$Res>
    implements $TransferCopyWith<$Res> {
  _$TransferCopyWithImpl(this._self, this._then);

  final Transfer _self;
  final $Res Function(Transfer) _then;

/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? floatAmount = null,Object? strAddress = null,Object? assetHash = null,Object? extraData = freezed,Object? encryptExtraData = freezed,}) {
  return _then(Transfer(
floatAmount: null == floatAmount ? _self.floatAmount : floatAmount // ignore: cast_nullable_to_non_nullable
as double,strAddress: null == strAddress ? _self.strAddress : strAddress // ignore: cast_nullable_to_non_nullable
as String,assetHash: null == assetHash ? _self.assetHash : assetHash // ignore: cast_nullable_to_non_nullable
as String,extraData: freezed == extraData ? _self.extraData : extraData // ignore: cast_nullable_to_non_nullable
as String?,encryptExtraData: freezed == encryptExtraData ? _self.encryptExtraData : encryptExtraData // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transfer].
extension TransferPatterns on Transfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transfer value)  $default,){
final _that = this;
switch (_that) {
case _Transfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transfer value)?  $default,){
final _that = this;
switch (_that) {
case _Transfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double floatAmount,  String strAddress,  String assetHash,  String? extraData,  bool? encryptExtraData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transfer() when $default != null:
return $default(_that.floatAmount,_that.strAddress,_that.assetHash,_that.extraData,_that.encryptExtraData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double floatAmount,  String strAddress,  String assetHash,  String? extraData,  bool? encryptExtraData)  $default,) {final _that = this;
switch (_that) {
case _Transfer():
return $default(_that.floatAmount,_that.strAddress,_that.assetHash,_that.extraData,_that.encryptExtraData);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double floatAmount,  String strAddress,  String assetHash,  String? extraData,  bool? encryptExtraData)?  $default,) {final _that = this;
switch (_that) {
case _Transfer() when $default != null:
return $default(_that.floatAmount,_that.strAddress,_that.assetHash,_that.extraData,_that.encryptExtraData);case _:
  return null;

}
}

}

/// @nodoc


class _Transfer implements Transfer {
  const _Transfer({required this.floatAmount, required this.strAddress, required this.assetHash, this.extraData, this.encryptExtraData});
  

@override final  double floatAmount;
@override final  String strAddress;
@override final  String assetHash;
@override final  String? extraData;
@override final  bool? encryptExtraData;

/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferCopyWith<_Transfer> get copyWith => __$TransferCopyWithImpl<_Transfer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transfer&&(identical(other.floatAmount, floatAmount) || other.floatAmount == floatAmount)&&(identical(other.strAddress, strAddress) || other.strAddress == strAddress)&&(identical(other.assetHash, assetHash) || other.assetHash == assetHash)&&(identical(other.extraData, extraData) || other.extraData == extraData)&&(identical(other.encryptExtraData, encryptExtraData) || other.encryptExtraData == encryptExtraData));
}


@override
int get hashCode => Object.hash(runtimeType,floatAmount,strAddress,assetHash,extraData,encryptExtraData);

@override
String toString() {
  return 'Transfer(floatAmount: $floatAmount, strAddress: $strAddress, assetHash: $assetHash, extraData: $extraData, encryptExtraData: $encryptExtraData)';
}


}

/// @nodoc
abstract mixin class _$TransferCopyWith<$Res> implements $TransferCopyWith<$Res> {
  factory _$TransferCopyWith(_Transfer value, $Res Function(_Transfer) _then) = __$TransferCopyWithImpl;
@override @useResult
$Res call({
 double floatAmount, String strAddress, String assetHash, String? extraData, bool? encryptExtraData
});




}
/// @nodoc
class __$TransferCopyWithImpl<$Res>
    implements _$TransferCopyWith<$Res> {
  __$TransferCopyWithImpl(this._self, this._then);

  final _Transfer _self;
  final $Res Function(_Transfer) _then;

/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? floatAmount = null,Object? strAddress = null,Object? assetHash = null,Object? extraData = freezed,Object? encryptExtraData = freezed,}) {
  return _then(_Transfer(
floatAmount: null == floatAmount ? _self.floatAmount : floatAmount // ignore: cast_nullable_to_non_nullable
as double,strAddress: null == strAddress ? _self.strAddress : strAddress // ignore: cast_nullable_to_non_nullable
as String,assetHash: null == assetHash ? _self.assetHash : assetHash // ignore: cast_nullable_to_non_nullable
as String,extraData: freezed == extraData ? _self.extraData : extraData // ignore: cast_nullable_to_non_nullable
as String?,encryptExtraData: freezed == encryptExtraData ? _self.encryptExtraData : encryptExtraData // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$XelisAssetMetadata {

 String get name; String get ticker; int get decimals; XelisMaxSupplyMode get maxSupply; XelisAssetOwner get owner;
/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XelisAssetMetadataCopyWith<XelisAssetMetadata> get copyWith => _$XelisAssetMetadataCopyWithImpl<XelisAssetMetadata>(this as XelisAssetMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisAssetMetadata&&(identical(other.name, name) || other.name == name)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.decimals, decimals) || other.decimals == decimals)&&(identical(other.maxSupply, maxSupply) || other.maxSupply == maxSupply)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,name,ticker,decimals,maxSupply,owner);

@override
String toString() {
  return 'XelisAssetMetadata(name: $name, ticker: $ticker, decimals: $decimals, maxSupply: $maxSupply, owner: $owner)';
}


}

/// @nodoc
abstract mixin class $XelisAssetMetadataCopyWith<$Res>  {
  factory $XelisAssetMetadataCopyWith(XelisAssetMetadata value, $Res Function(XelisAssetMetadata) _then) = _$XelisAssetMetadataCopyWithImpl;
@useResult
$Res call({
 String name, String ticker, int decimals, XelisMaxSupplyMode maxSupply, XelisAssetOwner owner
});


$XelisMaxSupplyModeCopyWith<$Res> get maxSupply;$XelisAssetOwnerCopyWith<$Res> get owner;

}
/// @nodoc
class _$XelisAssetMetadataCopyWithImpl<$Res>
    implements $XelisAssetMetadataCopyWith<$Res> {
  _$XelisAssetMetadataCopyWithImpl(this._self, this._then);

  final XelisAssetMetadata _self;
  final $Res Function(XelisAssetMetadata) _then;

/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? ticker = null,Object? decimals = null,Object? maxSupply = null,Object? owner = null,}) {
  return _then(XelisAssetMetadata(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,decimals: null == decimals ? _self.decimals : decimals // ignore: cast_nullable_to_non_nullable
as int,maxSupply: null == maxSupply ? _self.maxSupply : maxSupply // ignore: cast_nullable_to_non_nullable
as XelisMaxSupplyMode,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as XelisAssetOwner,
  ));
}
/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XelisMaxSupplyModeCopyWith<$Res> get maxSupply {
  
  return $XelisMaxSupplyModeCopyWith<$Res>(_self.maxSupply, (value) {
    return _then(_self.copyWith(maxSupply: value));
  });
}/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XelisAssetOwnerCopyWith<$Res> get owner {
  
  return $XelisAssetOwnerCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [XelisAssetMetadata].
extension XelisAssetMetadataPatterns on XelisAssetMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XelisAssetMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XelisAssetMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XelisAssetMetadata value)  $default,){
final _that = this;
switch (_that) {
case _XelisAssetMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XelisAssetMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _XelisAssetMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String ticker,  int decimals,  XelisMaxSupplyMode maxSupply,  XelisAssetOwner owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XelisAssetMetadata() when $default != null:
return $default(_that.name,_that.ticker,_that.decimals,_that.maxSupply,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String ticker,  int decimals,  XelisMaxSupplyMode maxSupply,  XelisAssetOwner owner)  $default,) {final _that = this;
switch (_that) {
case _XelisAssetMetadata():
return $default(_that.name,_that.ticker,_that.decimals,_that.maxSupply,_that.owner);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String ticker,  int decimals,  XelisMaxSupplyMode maxSupply,  XelisAssetOwner owner)?  $default,) {final _that = this;
switch (_that) {
case _XelisAssetMetadata() when $default != null:
return $default(_that.name,_that.ticker,_that.decimals,_that.maxSupply,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _XelisAssetMetadata implements XelisAssetMetadata {
  const _XelisAssetMetadata({required this.name, required this.ticker, required this.decimals, required this.maxSupply, required this.owner});
  

@override final  String name;
@override final  String ticker;
@override final  int decimals;
@override final  XelisMaxSupplyMode maxSupply;
@override final  XelisAssetOwner owner;

/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XelisAssetMetadataCopyWith<_XelisAssetMetadata> get copyWith => __$XelisAssetMetadataCopyWithImpl<_XelisAssetMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XelisAssetMetadata&&(identical(other.name, name) || other.name == name)&&(identical(other.ticker, ticker) || other.ticker == ticker)&&(identical(other.decimals, decimals) || other.decimals == decimals)&&(identical(other.maxSupply, maxSupply) || other.maxSupply == maxSupply)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,name,ticker,decimals,maxSupply,owner);

@override
String toString() {
  return 'XelisAssetMetadata(name: $name, ticker: $ticker, decimals: $decimals, maxSupply: $maxSupply, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$XelisAssetMetadataCopyWith<$Res> implements $XelisAssetMetadataCopyWith<$Res> {
  factory _$XelisAssetMetadataCopyWith(_XelisAssetMetadata value, $Res Function(_XelisAssetMetadata) _then) = __$XelisAssetMetadataCopyWithImpl;
@override @useResult
$Res call({
 String name, String ticker, int decimals, XelisMaxSupplyMode maxSupply, XelisAssetOwner owner
});


@override $XelisMaxSupplyModeCopyWith<$Res> get maxSupply;@override $XelisAssetOwnerCopyWith<$Res> get owner;

}
/// @nodoc
class __$XelisAssetMetadataCopyWithImpl<$Res>
    implements _$XelisAssetMetadataCopyWith<$Res> {
  __$XelisAssetMetadataCopyWithImpl(this._self, this._then);

  final _XelisAssetMetadata _self;
  final $Res Function(_XelisAssetMetadata) _then;

/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? ticker = null,Object? decimals = null,Object? maxSupply = null,Object? owner = null,}) {
  return _then(_XelisAssetMetadata(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ticker: null == ticker ? _self.ticker : ticker // ignore: cast_nullable_to_non_nullable
as String,decimals: null == decimals ? _self.decimals : decimals // ignore: cast_nullable_to_non_nullable
as int,maxSupply: null == maxSupply ? _self.maxSupply : maxSupply // ignore: cast_nullable_to_non_nullable
as XelisMaxSupplyMode,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as XelisAssetOwner,
  ));
}

/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XelisMaxSupplyModeCopyWith<$Res> get maxSupply {
  
  return $XelisMaxSupplyModeCopyWith<$Res>(_self.maxSupply, (value) {
    return _then(_self.copyWith(maxSupply: value));
  });
}/// Create a copy of XelisAssetMetadata
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XelisAssetOwnerCopyWith<$Res> get owner {
  
  return $XelisAssetOwnerCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$XelisAssetOwner {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisAssetOwner);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'XelisAssetOwner()';
}


}

/// @nodoc
class $XelisAssetOwnerCopyWith<$Res>  {
$XelisAssetOwnerCopyWith(XelisAssetOwner _, $Res Function(XelisAssetOwner) __);
}


/// Adds pattern-matching-related methods to [XelisAssetOwner].
extension XelisAssetOwnerPatterns on XelisAssetOwner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( XelisAssetOwner_None value)?  none,TResult Function( XelisAssetOwner_Creator value)?  creator,TResult Function( XelisAssetOwner_Owner value)?  owner,required TResult orElse(),}){
final _that = this;
switch (_that) {
case XelisAssetOwner_None() when none != null:
return none(_that);case XelisAssetOwner_Creator() when creator != null:
return creator(_that);case XelisAssetOwner_Owner() when owner != null:
return owner(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( XelisAssetOwner_None value)  none,required TResult Function( XelisAssetOwner_Creator value)  creator,required TResult Function( XelisAssetOwner_Owner value)  owner,}){
final _that = this;
switch (_that) {
case XelisAssetOwner_None():
return none(_that);case XelisAssetOwner_Creator():
return creator(_that);case XelisAssetOwner_Owner():
return owner(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( XelisAssetOwner_None value)?  none,TResult? Function( XelisAssetOwner_Creator value)?  creator,TResult? Function( XelisAssetOwner_Owner value)?  owner,}){
final _that = this;
switch (_that) {
case XelisAssetOwner_None() when none != null:
return none(_that);case XelisAssetOwner_Creator() when creator != null:
return creator(_that);case XelisAssetOwner_Owner() when owner != null:
return owner(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( String contract,  BigInt id)?  creator,TResult Function( String origin,  BigInt originId,  String owner)?  owner,required TResult orElse(),}) {final _that = this;
switch (_that) {
case XelisAssetOwner_None() when none != null:
return none();case XelisAssetOwner_Creator() when creator != null:
return creator(_that.contract,_that.id);case XelisAssetOwner_Owner() when owner != null:
return owner(_that.origin,_that.originId,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( String contract,  BigInt id)  creator,required TResult Function( String origin,  BigInt originId,  String owner)  owner,}) {final _that = this;
switch (_that) {
case XelisAssetOwner_None():
return none();case XelisAssetOwner_Creator():
return creator(_that.contract,_that.id);case XelisAssetOwner_Owner():
return owner(_that.origin,_that.originId,_that.owner);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( String contract,  BigInt id)?  creator,TResult? Function( String origin,  BigInt originId,  String owner)?  owner,}) {final _that = this;
switch (_that) {
case XelisAssetOwner_None() when none != null:
return none();case XelisAssetOwner_Creator() when creator != null:
return creator(_that.contract,_that.id);case XelisAssetOwner_Owner() when owner != null:
return owner(_that.origin,_that.originId,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class XelisAssetOwner_None extends XelisAssetOwner {
  const XelisAssetOwner_None(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisAssetOwner_None);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'XelisAssetOwner.none()';
}


}




/// @nodoc


class XelisAssetOwner_Creator extends XelisAssetOwner {
  const XelisAssetOwner_Creator({required this.contract, required this.id}): super._();
  

 final  String contract;
 final  BigInt id;

/// Create a copy of XelisAssetOwner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XelisAssetOwner_CreatorCopyWith<XelisAssetOwner_Creator> get copyWith => _$XelisAssetOwner_CreatorCopyWithImpl<XelisAssetOwner_Creator>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisAssetOwner_Creator&&(identical(other.contract, contract) || other.contract == contract)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,contract,id);

@override
String toString() {
  return 'XelisAssetOwner.creator(contract: $contract, id: $id)';
}


}

/// @nodoc
abstract mixin class $XelisAssetOwner_CreatorCopyWith<$Res> implements $XelisAssetOwnerCopyWith<$Res> {
  factory $XelisAssetOwner_CreatorCopyWith(XelisAssetOwner_Creator value, $Res Function(XelisAssetOwner_Creator) _then) = _$XelisAssetOwner_CreatorCopyWithImpl;
@useResult
$Res call({
 String contract, BigInt id
});




}
/// @nodoc
class _$XelisAssetOwner_CreatorCopyWithImpl<$Res>
    implements $XelisAssetOwner_CreatorCopyWith<$Res> {
  _$XelisAssetOwner_CreatorCopyWithImpl(this._self, this._then);

  final XelisAssetOwner_Creator _self;
  final $Res Function(XelisAssetOwner_Creator) _then;

/// Create a copy of XelisAssetOwner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? contract = null,Object? id = null,}) {
  return _then(XelisAssetOwner_Creator(
contract: null == contract ? _self.contract : contract // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class XelisAssetOwner_Owner extends XelisAssetOwner {
  const XelisAssetOwner_Owner({required this.origin, required this.originId, required this.owner}): super._();
  

 final  String origin;
 final  BigInt originId;
 final  String owner;

/// Create a copy of XelisAssetOwner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XelisAssetOwner_OwnerCopyWith<XelisAssetOwner_Owner> get copyWith => _$XelisAssetOwner_OwnerCopyWithImpl<XelisAssetOwner_Owner>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisAssetOwner_Owner&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.originId, originId) || other.originId == originId)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode => Object.hash(runtimeType,origin,originId,owner);

@override
String toString() {
  return 'XelisAssetOwner.owner(origin: $origin, originId: $originId, owner: $owner)';
}


}

/// @nodoc
abstract mixin class $XelisAssetOwner_OwnerCopyWith<$Res> implements $XelisAssetOwnerCopyWith<$Res> {
  factory $XelisAssetOwner_OwnerCopyWith(XelisAssetOwner_Owner value, $Res Function(XelisAssetOwner_Owner) _then) = _$XelisAssetOwner_OwnerCopyWithImpl;
@useResult
$Res call({
 String origin, BigInt originId, String owner
});




}
/// @nodoc
class _$XelisAssetOwner_OwnerCopyWithImpl<$Res>
    implements $XelisAssetOwner_OwnerCopyWith<$Res> {
  _$XelisAssetOwner_OwnerCopyWithImpl(this._self, this._then);

  final XelisAssetOwner_Owner _self;
  final $Res Function(XelisAssetOwner_Owner) _then;

/// Create a copy of XelisAssetOwner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? origin = null,Object? originId = null,Object? owner = null,}) {
  return _then(XelisAssetOwner_Owner(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,originId: null == originId ? _self.originId : originId // ignore: cast_nullable_to_non_nullable
as BigInt,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$XelisMaxSupplyMode {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisMaxSupplyMode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'XelisMaxSupplyMode()';
}


}

/// @nodoc
class $XelisMaxSupplyModeCopyWith<$Res>  {
$XelisMaxSupplyModeCopyWith(XelisMaxSupplyMode _, $Res Function(XelisMaxSupplyMode) __);
}


/// Adds pattern-matching-related methods to [XelisMaxSupplyMode].
extension XelisMaxSupplyModePatterns on XelisMaxSupplyMode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( XelisMaxSupplyMode_None value)?  none,TResult Function( XelisMaxSupplyMode_Fixed value)?  fixed,TResult Function( XelisMaxSupplyMode_Mintable value)?  mintable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case XelisMaxSupplyMode_None() when none != null:
return none(_that);case XelisMaxSupplyMode_Fixed() when fixed != null:
return fixed(_that);case XelisMaxSupplyMode_Mintable() when mintable != null:
return mintable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( XelisMaxSupplyMode_None value)  none,required TResult Function( XelisMaxSupplyMode_Fixed value)  fixed,required TResult Function( XelisMaxSupplyMode_Mintable value)  mintable,}){
final _that = this;
switch (_that) {
case XelisMaxSupplyMode_None():
return none(_that);case XelisMaxSupplyMode_Fixed():
return fixed(_that);case XelisMaxSupplyMode_Mintable():
return mintable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( XelisMaxSupplyMode_None value)?  none,TResult? Function( XelisMaxSupplyMode_Fixed value)?  fixed,TResult? Function( XelisMaxSupplyMode_Mintable value)?  mintable,}){
final _that = this;
switch (_that) {
case XelisMaxSupplyMode_None() when none != null:
return none(_that);case XelisMaxSupplyMode_Fixed() when fixed != null:
return fixed(_that);case XelisMaxSupplyMode_Mintable() when mintable != null:
return mintable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( BigInt field0)?  fixed,TResult Function( BigInt field0)?  mintable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case XelisMaxSupplyMode_None() when none != null:
return none();case XelisMaxSupplyMode_Fixed() when fixed != null:
return fixed(_that.field0);case XelisMaxSupplyMode_Mintable() when mintable != null:
return mintable(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( BigInt field0)  fixed,required TResult Function( BigInt field0)  mintable,}) {final _that = this;
switch (_that) {
case XelisMaxSupplyMode_None():
return none();case XelisMaxSupplyMode_Fixed():
return fixed(_that.field0);case XelisMaxSupplyMode_Mintable():
return mintable(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( BigInt field0)?  fixed,TResult? Function( BigInt field0)?  mintable,}) {final _that = this;
switch (_that) {
case XelisMaxSupplyMode_None() when none != null:
return none();case XelisMaxSupplyMode_Fixed() when fixed != null:
return fixed(_that.field0);case XelisMaxSupplyMode_Mintable() when mintable != null:
return mintable(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class XelisMaxSupplyMode_None extends XelisMaxSupplyMode {
  const XelisMaxSupplyMode_None(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisMaxSupplyMode_None);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'XelisMaxSupplyMode.none()';
}


}




/// @nodoc


class XelisMaxSupplyMode_Fixed extends XelisMaxSupplyMode {
  const XelisMaxSupplyMode_Fixed(this.field0): super._();
  

 final  BigInt field0;

/// Create a copy of XelisMaxSupplyMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XelisMaxSupplyMode_FixedCopyWith<XelisMaxSupplyMode_Fixed> get copyWith => _$XelisMaxSupplyMode_FixedCopyWithImpl<XelisMaxSupplyMode_Fixed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisMaxSupplyMode_Fixed&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'XelisMaxSupplyMode.fixed(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $XelisMaxSupplyMode_FixedCopyWith<$Res> implements $XelisMaxSupplyModeCopyWith<$Res> {
  factory $XelisMaxSupplyMode_FixedCopyWith(XelisMaxSupplyMode_Fixed value, $Res Function(XelisMaxSupplyMode_Fixed) _then) = _$XelisMaxSupplyMode_FixedCopyWithImpl;
@useResult
$Res call({
 BigInt field0
});




}
/// @nodoc
class _$XelisMaxSupplyMode_FixedCopyWithImpl<$Res>
    implements $XelisMaxSupplyMode_FixedCopyWith<$Res> {
  _$XelisMaxSupplyMode_FixedCopyWithImpl(this._self, this._then);

  final XelisMaxSupplyMode_Fixed _self;
  final $Res Function(XelisMaxSupplyMode_Fixed) _then;

/// Create a copy of XelisMaxSupplyMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(XelisMaxSupplyMode_Fixed(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class XelisMaxSupplyMode_Mintable extends XelisMaxSupplyMode {
  const XelisMaxSupplyMode_Mintable(this.field0): super._();
  

 final  BigInt field0;

/// Create a copy of XelisMaxSupplyMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XelisMaxSupplyMode_MintableCopyWith<XelisMaxSupplyMode_Mintable> get copyWith => _$XelisMaxSupplyMode_MintableCopyWithImpl<XelisMaxSupplyMode_Mintable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XelisMaxSupplyMode_Mintable&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'XelisMaxSupplyMode.mintable(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $XelisMaxSupplyMode_MintableCopyWith<$Res> implements $XelisMaxSupplyModeCopyWith<$Res> {
  factory $XelisMaxSupplyMode_MintableCopyWith(XelisMaxSupplyMode_Mintable value, $Res Function(XelisMaxSupplyMode_Mintable) _then) = _$XelisMaxSupplyMode_MintableCopyWithImpl;
@useResult
$Res call({
 BigInt field0
});




}
/// @nodoc
class _$XelisMaxSupplyMode_MintableCopyWithImpl<$Res>
    implements $XelisMaxSupplyMode_MintableCopyWith<$Res> {
  _$XelisMaxSupplyMode_MintableCopyWithImpl(this._self, this._then);

  final XelisMaxSupplyMode_Mintable _self;
  final $Res Function(XelisMaxSupplyMode_Mintable) _then;

/// Create a copy of XelisMaxSupplyMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(XelisMaxSupplyMode_Mintable(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

// dart format on
