// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_event_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NativeWalletBusinessEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeWalletBusinessEvent()';
}


}

/// @nodoc
class $NativeWalletBusinessEventCopyWith<$Res>  {
$NativeWalletBusinessEventCopyWith(NativeWalletBusinessEvent _, $Res Function(NativeWalletBusinessEvent) __);
}


/// Adds pattern-matching-related methods to [NativeWalletBusinessEvent].
extension NativeWalletBusinessEventPatterns on NativeWalletBusinessEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativeWalletBusinessEvent_NewTransaction value)?  newTransaction,TResult Function( NativeWalletBusinessEvent_NewPendingTransaction value)?  newPendingTransaction,TResult Function( NativeWalletBusinessEvent_BalanceChanged value)?  balanceChanged,TResult Function( NativeWalletBusinessEvent_NewAsset value)?  newAsset,TResult Function( NativeWalletBusinessEvent_AssetTracked value)?  assetTracked,TResult Function( NativeWalletBusinessEvent_AssetUntracked value)?  assetUntracked,TResult Function( NativeWalletBusinessEvent_Degraded value)?  degraded,TResult Function( NativeWalletBusinessEvent_Closed value)?  closed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativeWalletBusinessEvent_NewTransaction() when newTransaction != null:
return newTransaction(_that);case NativeWalletBusinessEvent_NewPendingTransaction() when newPendingTransaction != null:
return newPendingTransaction(_that);case NativeWalletBusinessEvent_BalanceChanged() when balanceChanged != null:
return balanceChanged(_that);case NativeWalletBusinessEvent_NewAsset() when newAsset != null:
return newAsset(_that);case NativeWalletBusinessEvent_AssetTracked() when assetTracked != null:
return assetTracked(_that);case NativeWalletBusinessEvent_AssetUntracked() when assetUntracked != null:
return assetUntracked(_that);case NativeWalletBusinessEvent_Degraded() when degraded != null:
return degraded(_that);case NativeWalletBusinessEvent_Closed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativeWalletBusinessEvent_NewTransaction value)  newTransaction,required TResult Function( NativeWalletBusinessEvent_NewPendingTransaction value)  newPendingTransaction,required TResult Function( NativeWalletBusinessEvent_BalanceChanged value)  balanceChanged,required TResult Function( NativeWalletBusinessEvent_NewAsset value)  newAsset,required TResult Function( NativeWalletBusinessEvent_AssetTracked value)  assetTracked,required TResult Function( NativeWalletBusinessEvent_AssetUntracked value)  assetUntracked,required TResult Function( NativeWalletBusinessEvent_Degraded value)  degraded,required TResult Function( NativeWalletBusinessEvent_Closed value)  closed,}){
final _that = this;
switch (_that) {
case NativeWalletBusinessEvent_NewTransaction():
return newTransaction(_that);case NativeWalletBusinessEvent_NewPendingTransaction():
return newPendingTransaction(_that);case NativeWalletBusinessEvent_BalanceChanged():
return balanceChanged(_that);case NativeWalletBusinessEvent_NewAsset():
return newAsset(_that);case NativeWalletBusinessEvent_AssetTracked():
return assetTracked(_that);case NativeWalletBusinessEvent_AssetUntracked():
return assetUntracked(_that);case NativeWalletBusinessEvent_Degraded():
return degraded(_that);case NativeWalletBusinessEvent_Closed():
return closed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativeWalletBusinessEvent_NewTransaction value)?  newTransaction,TResult? Function( NativeWalletBusinessEvent_NewPendingTransaction value)?  newPendingTransaction,TResult? Function( NativeWalletBusinessEvent_BalanceChanged value)?  balanceChanged,TResult? Function( NativeWalletBusinessEvent_NewAsset value)?  newAsset,TResult? Function( NativeWalletBusinessEvent_AssetTracked value)?  assetTracked,TResult? Function( NativeWalletBusinessEvent_AssetUntracked value)?  assetUntracked,TResult? Function( NativeWalletBusinessEvent_Degraded value)?  degraded,TResult? Function( NativeWalletBusinessEvent_Closed value)?  closed,}){
final _that = this;
switch (_that) {
case NativeWalletBusinessEvent_NewTransaction() when newTransaction != null:
return newTransaction(_that);case NativeWalletBusinessEvent_NewPendingTransaction() when newPendingTransaction != null:
return newPendingTransaction(_that);case NativeWalletBusinessEvent_BalanceChanged() when balanceChanged != null:
return balanceChanged(_that);case NativeWalletBusinessEvent_NewAsset() when newAsset != null:
return newAsset(_that);case NativeWalletBusinessEvent_AssetTracked() when assetTracked != null:
return assetTracked(_that);case NativeWalletBusinessEvent_AssetUntracked() when assetUntracked != null:
return assetUntracked(_that);case NativeWalletBusinessEvent_Degraded() when degraded != null:
return degraded(_that);case NativeWalletBusinessEvent_Closed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( NativeWalletTransactionEntry transaction)?  newTransaction,TResult Function( NativeWalletPendingTransaction transaction)?  newPendingTransaction,TResult Function( String asset,  BigInt balance)?  balanceChanged,TResult Function( NativeWalletAsset asset)?  newAsset,TResult Function( String asset)?  assetTracked,TResult Function( String asset)?  assetUntracked,TResult Function( BigInt skippedEvents,  NativeXelisError failure)?  degraded,TResult Function( NativeWalletBusinessStreamCloseReason reason,  NativeXelisError failure)?  closed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativeWalletBusinessEvent_NewTransaction() when newTransaction != null:
return newTransaction(_that.transaction);case NativeWalletBusinessEvent_NewPendingTransaction() when newPendingTransaction != null:
return newPendingTransaction(_that.transaction);case NativeWalletBusinessEvent_BalanceChanged() when balanceChanged != null:
return balanceChanged(_that.asset,_that.balance);case NativeWalletBusinessEvent_NewAsset() when newAsset != null:
return newAsset(_that.asset);case NativeWalletBusinessEvent_AssetTracked() when assetTracked != null:
return assetTracked(_that.asset);case NativeWalletBusinessEvent_AssetUntracked() when assetUntracked != null:
return assetUntracked(_that.asset);case NativeWalletBusinessEvent_Degraded() when degraded != null:
return degraded(_that.skippedEvents,_that.failure);case NativeWalletBusinessEvent_Closed() when closed != null:
return closed(_that.reason,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( NativeWalletTransactionEntry transaction)  newTransaction,required TResult Function( NativeWalletPendingTransaction transaction)  newPendingTransaction,required TResult Function( String asset,  BigInt balance)  balanceChanged,required TResult Function( NativeWalletAsset asset)  newAsset,required TResult Function( String asset)  assetTracked,required TResult Function( String asset)  assetUntracked,required TResult Function( BigInt skippedEvents,  NativeXelisError failure)  degraded,required TResult Function( NativeWalletBusinessStreamCloseReason reason,  NativeXelisError failure)  closed,}) {final _that = this;
switch (_that) {
case NativeWalletBusinessEvent_NewTransaction():
return newTransaction(_that.transaction);case NativeWalletBusinessEvent_NewPendingTransaction():
return newPendingTransaction(_that.transaction);case NativeWalletBusinessEvent_BalanceChanged():
return balanceChanged(_that.asset,_that.balance);case NativeWalletBusinessEvent_NewAsset():
return newAsset(_that.asset);case NativeWalletBusinessEvent_AssetTracked():
return assetTracked(_that.asset);case NativeWalletBusinessEvent_AssetUntracked():
return assetUntracked(_that.asset);case NativeWalletBusinessEvent_Degraded():
return degraded(_that.skippedEvents,_that.failure);case NativeWalletBusinessEvent_Closed():
return closed(_that.reason,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( NativeWalletTransactionEntry transaction)?  newTransaction,TResult? Function( NativeWalletPendingTransaction transaction)?  newPendingTransaction,TResult? Function( String asset,  BigInt balance)?  balanceChanged,TResult? Function( NativeWalletAsset asset)?  newAsset,TResult? Function( String asset)?  assetTracked,TResult? Function( String asset)?  assetUntracked,TResult? Function( BigInt skippedEvents,  NativeXelisError failure)?  degraded,TResult? Function( NativeWalletBusinessStreamCloseReason reason,  NativeXelisError failure)?  closed,}) {final _that = this;
switch (_that) {
case NativeWalletBusinessEvent_NewTransaction() when newTransaction != null:
return newTransaction(_that.transaction);case NativeWalletBusinessEvent_NewPendingTransaction() when newPendingTransaction != null:
return newPendingTransaction(_that.transaction);case NativeWalletBusinessEvent_BalanceChanged() when balanceChanged != null:
return balanceChanged(_that.asset,_that.balance);case NativeWalletBusinessEvent_NewAsset() when newAsset != null:
return newAsset(_that.asset);case NativeWalletBusinessEvent_AssetTracked() when assetTracked != null:
return assetTracked(_that.asset);case NativeWalletBusinessEvent_AssetUntracked() when assetUntracked != null:
return assetUntracked(_that.asset);case NativeWalletBusinessEvent_Degraded() when degraded != null:
return degraded(_that.skippedEvents,_that.failure);case NativeWalletBusinessEvent_Closed() when closed != null:
return closed(_that.reason,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class NativeWalletBusinessEvent_NewTransaction extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_NewTransaction({required this.transaction}): super._();
  

 final  NativeWalletTransactionEntry transaction;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_NewTransactionCopyWith<NativeWalletBusinessEvent_NewTransaction> get copyWith => _$NativeWalletBusinessEvent_NewTransactionCopyWithImpl<NativeWalletBusinessEvent_NewTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_NewTransaction&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,transaction);

@override
String toString() {
  return 'NativeWalletBusinessEvent.newTransaction(transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_NewTransactionCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_NewTransactionCopyWith(NativeWalletBusinessEvent_NewTransaction value, $Res Function(NativeWalletBusinessEvent_NewTransaction) _then) = _$NativeWalletBusinessEvent_NewTransactionCopyWithImpl;
@useResult
$Res call({
 NativeWalletTransactionEntry transaction
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_NewTransactionCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_NewTransactionCopyWith<$Res> {
  _$NativeWalletBusinessEvent_NewTransactionCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_NewTransaction _self;
  final $Res Function(NativeWalletBusinessEvent_NewTransaction) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transaction = null,}) {
  return _then(NativeWalletBusinessEvent_NewTransaction(
transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativeWalletTransactionEntry,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_NewPendingTransaction extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_NewPendingTransaction({required this.transaction}): super._();
  

 final  NativeWalletPendingTransaction transaction;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_NewPendingTransactionCopyWith<NativeWalletBusinessEvent_NewPendingTransaction> get copyWith => _$NativeWalletBusinessEvent_NewPendingTransactionCopyWithImpl<NativeWalletBusinessEvent_NewPendingTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_NewPendingTransaction&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode => Object.hash(runtimeType,transaction);

@override
String toString() {
  return 'NativeWalletBusinessEvent.newPendingTransaction(transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_NewPendingTransactionCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_NewPendingTransactionCopyWith(NativeWalletBusinessEvent_NewPendingTransaction value, $Res Function(NativeWalletBusinessEvent_NewPendingTransaction) _then) = _$NativeWalletBusinessEvent_NewPendingTransactionCopyWithImpl;
@useResult
$Res call({
 NativeWalletPendingTransaction transaction
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_NewPendingTransactionCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_NewPendingTransactionCopyWith<$Res> {
  _$NativeWalletBusinessEvent_NewPendingTransactionCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_NewPendingTransaction _self;
  final $Res Function(NativeWalletBusinessEvent_NewPendingTransaction) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transaction = null,}) {
  return _then(NativeWalletBusinessEvent_NewPendingTransaction(
transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as NativeWalletPendingTransaction,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_BalanceChanged extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_BalanceChanged({required this.asset, required this.balance}): super._();
  

 final  String asset;
 final  BigInt balance;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_BalanceChangedCopyWith<NativeWalletBusinessEvent_BalanceChanged> get copyWith => _$NativeWalletBusinessEvent_BalanceChangedCopyWithImpl<NativeWalletBusinessEvent_BalanceChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_BalanceChanged&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,asset,balance);

@override
String toString() {
  return 'NativeWalletBusinessEvent.balanceChanged(asset: $asset, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_BalanceChangedCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_BalanceChangedCopyWith(NativeWalletBusinessEvent_BalanceChanged value, $Res Function(NativeWalletBusinessEvent_BalanceChanged) _then) = _$NativeWalletBusinessEvent_BalanceChangedCopyWithImpl;
@useResult
$Res call({
 String asset, BigInt balance
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_BalanceChangedCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_BalanceChangedCopyWith<$Res> {
  _$NativeWalletBusinessEvent_BalanceChangedCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_BalanceChanged _self;
  final $Res Function(NativeWalletBusinessEvent_BalanceChanged) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,Object? balance = null,}) {
  return _then(NativeWalletBusinessEvent_BalanceChanged(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_NewAsset extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_NewAsset({required this.asset}): super._();
  

 final  NativeWalletAsset asset;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_NewAssetCopyWith<NativeWalletBusinessEvent_NewAsset> get copyWith => _$NativeWalletBusinessEvent_NewAssetCopyWithImpl<NativeWalletBusinessEvent_NewAsset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_NewAsset&&(identical(other.asset, asset) || other.asset == asset));
}


@override
int get hashCode => Object.hash(runtimeType,asset);

@override
String toString() {
  return 'NativeWalletBusinessEvent.newAsset(asset: $asset)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_NewAssetCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_NewAssetCopyWith(NativeWalletBusinessEvent_NewAsset value, $Res Function(NativeWalletBusinessEvent_NewAsset) _then) = _$NativeWalletBusinessEvent_NewAssetCopyWithImpl;
@useResult
$Res call({
 NativeWalletAsset asset
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_NewAssetCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_NewAssetCopyWith<$Res> {
  _$NativeWalletBusinessEvent_NewAssetCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_NewAsset _self;
  final $Res Function(NativeWalletBusinessEvent_NewAsset) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,}) {
  return _then(NativeWalletBusinessEvent_NewAsset(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as NativeWalletAsset,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_AssetTracked extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_AssetTracked({required this.asset}): super._();
  

 final  String asset;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_AssetTrackedCopyWith<NativeWalletBusinessEvent_AssetTracked> get copyWith => _$NativeWalletBusinessEvent_AssetTrackedCopyWithImpl<NativeWalletBusinessEvent_AssetTracked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_AssetTracked&&(identical(other.asset, asset) || other.asset == asset));
}


@override
int get hashCode => Object.hash(runtimeType,asset);

@override
String toString() {
  return 'NativeWalletBusinessEvent.assetTracked(asset: $asset)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_AssetTrackedCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_AssetTrackedCopyWith(NativeWalletBusinessEvent_AssetTracked value, $Res Function(NativeWalletBusinessEvent_AssetTracked) _then) = _$NativeWalletBusinessEvent_AssetTrackedCopyWithImpl;
@useResult
$Res call({
 String asset
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_AssetTrackedCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_AssetTrackedCopyWith<$Res> {
  _$NativeWalletBusinessEvent_AssetTrackedCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_AssetTracked _self;
  final $Res Function(NativeWalletBusinessEvent_AssetTracked) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,}) {
  return _then(NativeWalletBusinessEvent_AssetTracked(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_AssetUntracked extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_AssetUntracked({required this.asset}): super._();
  

 final  String asset;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_AssetUntrackedCopyWith<NativeWalletBusinessEvent_AssetUntracked> get copyWith => _$NativeWalletBusinessEvent_AssetUntrackedCopyWithImpl<NativeWalletBusinessEvent_AssetUntracked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_AssetUntracked&&(identical(other.asset, asset) || other.asset == asset));
}


@override
int get hashCode => Object.hash(runtimeType,asset);

@override
String toString() {
  return 'NativeWalletBusinessEvent.assetUntracked(asset: $asset)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_AssetUntrackedCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_AssetUntrackedCopyWith(NativeWalletBusinessEvent_AssetUntracked value, $Res Function(NativeWalletBusinessEvent_AssetUntracked) _then) = _$NativeWalletBusinessEvent_AssetUntrackedCopyWithImpl;
@useResult
$Res call({
 String asset
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_AssetUntrackedCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_AssetUntrackedCopyWith<$Res> {
  _$NativeWalletBusinessEvent_AssetUntrackedCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_AssetUntracked _self;
  final $Res Function(NativeWalletBusinessEvent_AssetUntracked) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,}) {
  return _then(NativeWalletBusinessEvent_AssetUntracked(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_Degraded extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_Degraded({required this.skippedEvents, required this.failure}): super._();
  

 final  BigInt skippedEvents;
 final  NativeXelisError failure;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_DegradedCopyWith<NativeWalletBusinessEvent_Degraded> get copyWith => _$NativeWalletBusinessEvent_DegradedCopyWithImpl<NativeWalletBusinessEvent_Degraded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_Degraded&&(identical(other.skippedEvents, skippedEvents) || other.skippedEvents == skippedEvents)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,skippedEvents,failure);

@override
String toString() {
  return 'NativeWalletBusinessEvent.degraded(skippedEvents: $skippedEvents, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_DegradedCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_DegradedCopyWith(NativeWalletBusinessEvent_Degraded value, $Res Function(NativeWalletBusinessEvent_Degraded) _then) = _$NativeWalletBusinessEvent_DegradedCopyWithImpl;
@useResult
$Res call({
 BigInt skippedEvents, NativeXelisError failure
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_DegradedCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_DegradedCopyWith<$Res> {
  _$NativeWalletBusinessEvent_DegradedCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_Degraded _self;
  final $Res Function(NativeWalletBusinessEvent_Degraded) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? skippedEvents = null,Object? failure = null,}) {
  return _then(NativeWalletBusinessEvent_Degraded(
skippedEvents: null == skippedEvents ? _self.skippedEvents : skippedEvents // ignore: cast_nullable_to_non_nullable
as BigInt,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc


class NativeWalletBusinessEvent_Closed extends NativeWalletBusinessEvent {
  const NativeWalletBusinessEvent_Closed({required this.reason, required this.failure}): super._();
  

 final  NativeWalletBusinessStreamCloseReason reason;
 final  NativeXelisError failure;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletBusinessEvent_ClosedCopyWith<NativeWalletBusinessEvent_Closed> get copyWith => _$NativeWalletBusinessEvent_ClosedCopyWithImpl<NativeWalletBusinessEvent_Closed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletBusinessEvent_Closed&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,reason,failure);

@override
String toString() {
  return 'NativeWalletBusinessEvent.closed(reason: $reason, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativeWalletBusinessEvent_ClosedCopyWith<$Res> implements $NativeWalletBusinessEventCopyWith<$Res> {
  factory $NativeWalletBusinessEvent_ClosedCopyWith(NativeWalletBusinessEvent_Closed value, $Res Function(NativeWalletBusinessEvent_Closed) _then) = _$NativeWalletBusinessEvent_ClosedCopyWithImpl;
@useResult
$Res call({
 NativeWalletBusinessStreamCloseReason reason, NativeXelisError failure
});




}
/// @nodoc
class _$NativeWalletBusinessEvent_ClosedCopyWithImpl<$Res>
    implements $NativeWalletBusinessEvent_ClosedCopyWith<$Res> {
  _$NativeWalletBusinessEvent_ClosedCopyWithImpl(this._self, this._then);

  final NativeWalletBusinessEvent_Closed _self;
  final $Res Function(NativeWalletBusinessEvent_Closed) _then;

/// Create a copy of NativeWalletBusinessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? failure = null,}) {
  return _then(NativeWalletBusinessEvent_Closed(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as NativeWalletBusinessStreamCloseReason,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc
mixin _$NativeWalletTransactionEntryData {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeWalletTransactionEntryData()';
}


}

/// @nodoc
class $NativeWalletTransactionEntryDataCopyWith<$Res>  {
$NativeWalletTransactionEntryDataCopyWith(NativeWalletTransactionEntryData _, $Res Function(NativeWalletTransactionEntryData) __);
}


/// Adds pattern-matching-related methods to [NativeWalletTransactionEntryData].
extension NativeWalletTransactionEntryDataPatterns on NativeWalletTransactionEntryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativeWalletTransactionEntryData_Coinbase value)?  coinbase,TResult Function( NativeWalletTransactionEntryData_Burn value)?  burn,TResult Function( NativeWalletTransactionEntryData_Incoming value)?  incoming,TResult Function( NativeWalletTransactionEntryData_Outgoing value)?  outgoing,TResult Function( NativeWalletTransactionEntryData_Multisig value)?  multisig,TResult Function( NativeWalletTransactionEntryData_InvokeContract value)?  invokeContract,TResult Function( NativeWalletTransactionEntryData_DeployContract value)?  deployContract,TResult Function( NativeWalletTransactionEntryData_IncomingContract value)?  incomingContract,TResult Function( NativeWalletTransactionEntryData_OutgoingBlob value)?  outgoingBlob,TResult Function( NativeWalletTransactionEntryData_IncomingBlob value)?  incomingBlob,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativeWalletTransactionEntryData_Coinbase() when coinbase != null:
return coinbase(_that);case NativeWalletTransactionEntryData_Burn() when burn != null:
return burn(_that);case NativeWalletTransactionEntryData_Incoming() when incoming != null:
return incoming(_that);case NativeWalletTransactionEntryData_Outgoing() when outgoing != null:
return outgoing(_that);case NativeWalletTransactionEntryData_Multisig() when multisig != null:
return multisig(_that);case NativeWalletTransactionEntryData_InvokeContract() when invokeContract != null:
return invokeContract(_that);case NativeWalletTransactionEntryData_DeployContract() when deployContract != null:
return deployContract(_that);case NativeWalletTransactionEntryData_IncomingContract() when incomingContract != null:
return incomingContract(_that);case NativeWalletTransactionEntryData_OutgoingBlob() when outgoingBlob != null:
return outgoingBlob(_that);case NativeWalletTransactionEntryData_IncomingBlob() when incomingBlob != null:
return incomingBlob(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativeWalletTransactionEntryData_Coinbase value)  coinbase,required TResult Function( NativeWalletTransactionEntryData_Burn value)  burn,required TResult Function( NativeWalletTransactionEntryData_Incoming value)  incoming,required TResult Function( NativeWalletTransactionEntryData_Outgoing value)  outgoing,required TResult Function( NativeWalletTransactionEntryData_Multisig value)  multisig,required TResult Function( NativeWalletTransactionEntryData_InvokeContract value)  invokeContract,required TResult Function( NativeWalletTransactionEntryData_DeployContract value)  deployContract,required TResult Function( NativeWalletTransactionEntryData_IncomingContract value)  incomingContract,required TResult Function( NativeWalletTransactionEntryData_OutgoingBlob value)  outgoingBlob,required TResult Function( NativeWalletTransactionEntryData_IncomingBlob value)  incomingBlob,}){
final _that = this;
switch (_that) {
case NativeWalletTransactionEntryData_Coinbase():
return coinbase(_that);case NativeWalletTransactionEntryData_Burn():
return burn(_that);case NativeWalletTransactionEntryData_Incoming():
return incoming(_that);case NativeWalletTransactionEntryData_Outgoing():
return outgoing(_that);case NativeWalletTransactionEntryData_Multisig():
return multisig(_that);case NativeWalletTransactionEntryData_InvokeContract():
return invokeContract(_that);case NativeWalletTransactionEntryData_DeployContract():
return deployContract(_that);case NativeWalletTransactionEntryData_IncomingContract():
return incomingContract(_that);case NativeWalletTransactionEntryData_OutgoingBlob():
return outgoingBlob(_that);case NativeWalletTransactionEntryData_IncomingBlob():
return incomingBlob(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativeWalletTransactionEntryData_Coinbase value)?  coinbase,TResult? Function( NativeWalletTransactionEntryData_Burn value)?  burn,TResult? Function( NativeWalletTransactionEntryData_Incoming value)?  incoming,TResult? Function( NativeWalletTransactionEntryData_Outgoing value)?  outgoing,TResult? Function( NativeWalletTransactionEntryData_Multisig value)?  multisig,TResult? Function( NativeWalletTransactionEntryData_InvokeContract value)?  invokeContract,TResult? Function( NativeWalletTransactionEntryData_DeployContract value)?  deployContract,TResult? Function( NativeWalletTransactionEntryData_IncomingContract value)?  incomingContract,TResult? Function( NativeWalletTransactionEntryData_OutgoingBlob value)?  outgoingBlob,TResult? Function( NativeWalletTransactionEntryData_IncomingBlob value)?  incomingBlob,}){
final _that = this;
switch (_that) {
case NativeWalletTransactionEntryData_Coinbase() when coinbase != null:
return coinbase(_that);case NativeWalletTransactionEntryData_Burn() when burn != null:
return burn(_that);case NativeWalletTransactionEntryData_Incoming() when incoming != null:
return incoming(_that);case NativeWalletTransactionEntryData_Outgoing() when outgoing != null:
return outgoing(_that);case NativeWalletTransactionEntryData_Multisig() when multisig != null:
return multisig(_that);case NativeWalletTransactionEntryData_InvokeContract() when invokeContract != null:
return invokeContract(_that);case NativeWalletTransactionEntryData_DeployContract() when deployContract != null:
return deployContract(_that);case NativeWalletTransactionEntryData_IncomingContract() when incomingContract != null:
return incomingContract(_that);case NativeWalletTransactionEntryData_OutgoingBlob() when outgoingBlob != null:
return outgoingBlob(_that);case NativeWalletTransactionEntryData_IncomingBlob() when incomingBlob != null:
return incomingBlob(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BigInt reward)?  coinbase,TResult Function( String asset,  BigInt amount,  BigInt fee,  BigInt nonce)?  burn,TResult Function( String from,  List<NativeWalletTransferIn> transfers)?  incoming,TResult Function( List<NativeWalletTransferOut> transfers,  BigInt fee,  BigInt nonce)?  outgoing,TResult Function( List<String> participants,  int threshold,  BigInt fee,  BigInt nonce)?  multisig,TResult Function( String contract,  List<NativeWalletAssetAmount> deposits,  List<NativeWalletContractTransferGroup> received,  int chunkId,  BigInt fee,  BigInt maxGas,  BigInt nonce)?  invokeContract,TResult Function( BigInt fee,  BigInt nonce,  NativeWalletDeployInvoke? invoke)?  deployContract,TResult Function( List<NativeWalletContractTransferGroup> transfers)?  incomingContract,TResult Function( List<String> destinations,  BigInt fee,  BigInt nonce,  NativeWalletExtraData data)?  outgoingBlob,TResult Function( String from,  List<String> destinations,  NativeWalletExtraData data)?  incomingBlob,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativeWalletTransactionEntryData_Coinbase() when coinbase != null:
return coinbase(_that.reward);case NativeWalletTransactionEntryData_Burn() when burn != null:
return burn(_that.asset,_that.amount,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_Incoming() when incoming != null:
return incoming(_that.from,_that.transfers);case NativeWalletTransactionEntryData_Outgoing() when outgoing != null:
return outgoing(_that.transfers,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_Multisig() when multisig != null:
return multisig(_that.participants,_that.threshold,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_InvokeContract() when invokeContract != null:
return invokeContract(_that.contract,_that.deposits,_that.received,_that.chunkId,_that.fee,_that.maxGas,_that.nonce);case NativeWalletTransactionEntryData_DeployContract() when deployContract != null:
return deployContract(_that.fee,_that.nonce,_that.invoke);case NativeWalletTransactionEntryData_IncomingContract() when incomingContract != null:
return incomingContract(_that.transfers);case NativeWalletTransactionEntryData_OutgoingBlob() when outgoingBlob != null:
return outgoingBlob(_that.destinations,_that.fee,_that.nonce,_that.data);case NativeWalletTransactionEntryData_IncomingBlob() when incomingBlob != null:
return incomingBlob(_that.from,_that.destinations,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BigInt reward)  coinbase,required TResult Function( String asset,  BigInt amount,  BigInt fee,  BigInt nonce)  burn,required TResult Function( String from,  List<NativeWalletTransferIn> transfers)  incoming,required TResult Function( List<NativeWalletTransferOut> transfers,  BigInt fee,  BigInt nonce)  outgoing,required TResult Function( List<String> participants,  int threshold,  BigInt fee,  BigInt nonce)  multisig,required TResult Function( String contract,  List<NativeWalletAssetAmount> deposits,  List<NativeWalletContractTransferGroup> received,  int chunkId,  BigInt fee,  BigInt maxGas,  BigInt nonce)  invokeContract,required TResult Function( BigInt fee,  BigInt nonce,  NativeWalletDeployInvoke? invoke)  deployContract,required TResult Function( List<NativeWalletContractTransferGroup> transfers)  incomingContract,required TResult Function( List<String> destinations,  BigInt fee,  BigInt nonce,  NativeWalletExtraData data)  outgoingBlob,required TResult Function( String from,  List<String> destinations,  NativeWalletExtraData data)  incomingBlob,}) {final _that = this;
switch (_that) {
case NativeWalletTransactionEntryData_Coinbase():
return coinbase(_that.reward);case NativeWalletTransactionEntryData_Burn():
return burn(_that.asset,_that.amount,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_Incoming():
return incoming(_that.from,_that.transfers);case NativeWalletTransactionEntryData_Outgoing():
return outgoing(_that.transfers,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_Multisig():
return multisig(_that.participants,_that.threshold,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_InvokeContract():
return invokeContract(_that.contract,_that.deposits,_that.received,_that.chunkId,_that.fee,_that.maxGas,_that.nonce);case NativeWalletTransactionEntryData_DeployContract():
return deployContract(_that.fee,_that.nonce,_that.invoke);case NativeWalletTransactionEntryData_IncomingContract():
return incomingContract(_that.transfers);case NativeWalletTransactionEntryData_OutgoingBlob():
return outgoingBlob(_that.destinations,_that.fee,_that.nonce,_that.data);case NativeWalletTransactionEntryData_IncomingBlob():
return incomingBlob(_that.from,_that.destinations,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BigInt reward)?  coinbase,TResult? Function( String asset,  BigInt amount,  BigInt fee,  BigInt nonce)?  burn,TResult? Function( String from,  List<NativeWalletTransferIn> transfers)?  incoming,TResult? Function( List<NativeWalletTransferOut> transfers,  BigInt fee,  BigInt nonce)?  outgoing,TResult? Function( List<String> participants,  int threshold,  BigInt fee,  BigInt nonce)?  multisig,TResult? Function( String contract,  List<NativeWalletAssetAmount> deposits,  List<NativeWalletContractTransferGroup> received,  int chunkId,  BigInt fee,  BigInt maxGas,  BigInt nonce)?  invokeContract,TResult? Function( BigInt fee,  BigInt nonce,  NativeWalletDeployInvoke? invoke)?  deployContract,TResult? Function( List<NativeWalletContractTransferGroup> transfers)?  incomingContract,TResult? Function( List<String> destinations,  BigInt fee,  BigInt nonce,  NativeWalletExtraData data)?  outgoingBlob,TResult? Function( String from,  List<String> destinations,  NativeWalletExtraData data)?  incomingBlob,}) {final _that = this;
switch (_that) {
case NativeWalletTransactionEntryData_Coinbase() when coinbase != null:
return coinbase(_that.reward);case NativeWalletTransactionEntryData_Burn() when burn != null:
return burn(_that.asset,_that.amount,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_Incoming() when incoming != null:
return incoming(_that.from,_that.transfers);case NativeWalletTransactionEntryData_Outgoing() when outgoing != null:
return outgoing(_that.transfers,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_Multisig() when multisig != null:
return multisig(_that.participants,_that.threshold,_that.fee,_that.nonce);case NativeWalletTransactionEntryData_InvokeContract() when invokeContract != null:
return invokeContract(_that.contract,_that.deposits,_that.received,_that.chunkId,_that.fee,_that.maxGas,_that.nonce);case NativeWalletTransactionEntryData_DeployContract() when deployContract != null:
return deployContract(_that.fee,_that.nonce,_that.invoke);case NativeWalletTransactionEntryData_IncomingContract() when incomingContract != null:
return incomingContract(_that.transfers);case NativeWalletTransactionEntryData_OutgoingBlob() when outgoingBlob != null:
return outgoingBlob(_that.destinations,_that.fee,_that.nonce,_that.data);case NativeWalletTransactionEntryData_IncomingBlob() when incomingBlob != null:
return incomingBlob(_that.from,_that.destinations,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class NativeWalletTransactionEntryData_Coinbase extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_Coinbase({required this.reward}): super._();
  

 final  BigInt reward;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_CoinbaseCopyWith<NativeWalletTransactionEntryData_Coinbase> get copyWith => _$NativeWalletTransactionEntryData_CoinbaseCopyWithImpl<NativeWalletTransactionEntryData_Coinbase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_Coinbase&&(identical(other.reward, reward) || other.reward == reward));
}


@override
int get hashCode => Object.hash(runtimeType,reward);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.coinbase(reward: $reward)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_CoinbaseCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_CoinbaseCopyWith(NativeWalletTransactionEntryData_Coinbase value, $Res Function(NativeWalletTransactionEntryData_Coinbase) _then) = _$NativeWalletTransactionEntryData_CoinbaseCopyWithImpl;
@useResult
$Res call({
 BigInt reward
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_CoinbaseCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_CoinbaseCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_CoinbaseCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_Coinbase _self;
  final $Res Function(NativeWalletTransactionEntryData_Coinbase) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reward = null,}) {
  return _then(NativeWalletTransactionEntryData_Coinbase(
reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_Burn extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_Burn({required this.asset, required this.amount, required this.fee, required this.nonce}): super._();
  

 final  String asset;
 final  BigInt amount;
 final  BigInt fee;
 final  BigInt nonce;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_BurnCopyWith<NativeWalletTransactionEntryData_Burn> get copyWith => _$NativeWalletTransactionEntryData_BurnCopyWithImpl<NativeWalletTransactionEntryData_Burn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_Burn&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.nonce, nonce) || other.nonce == nonce));
}


@override
int get hashCode => Object.hash(runtimeType,asset,amount,fee,nonce);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.burn(asset: $asset, amount: $amount, fee: $fee, nonce: $nonce)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_BurnCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_BurnCopyWith(NativeWalletTransactionEntryData_Burn value, $Res Function(NativeWalletTransactionEntryData_Burn) _then) = _$NativeWalletTransactionEntryData_BurnCopyWithImpl;
@useResult
$Res call({
 String asset, BigInt amount, BigInt fee, BigInt nonce
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_BurnCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_BurnCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_BurnCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_Burn _self;
  final $Res Function(NativeWalletTransactionEntryData_Burn) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,Object? amount = null,Object? fee = null,Object? nonce = null,}) {
  return _then(NativeWalletTransactionEntryData_Burn(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_Incoming extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_Incoming({required this.from, required  List<NativeWalletTransferIn> transfers}): _transfers = transfers,super._();
  

 final  String from;
 final  List<NativeWalletTransferIn> _transfers;
 List<NativeWalletTransferIn> get transfers {
  if (_transfers is EqualUnmodifiableListView) return _transfers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transfers);
}


/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_IncomingCopyWith<NativeWalletTransactionEntryData_Incoming> get copyWith => _$NativeWalletTransactionEntryData_IncomingCopyWithImpl<NativeWalletTransactionEntryData_Incoming>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_Incoming&&(identical(other.from, from) || other.from == from)&&const DeepCollectionEquality().equals(other._transfers, _transfers));
}


@override
int get hashCode => Object.hash(runtimeType,from,const DeepCollectionEquality().hash(_transfers));

@override
String toString() {
  return 'NativeWalletTransactionEntryData.incoming(from: $from, transfers: $transfers)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_IncomingCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_IncomingCopyWith(NativeWalletTransactionEntryData_Incoming value, $Res Function(NativeWalletTransactionEntryData_Incoming) _then) = _$NativeWalletTransactionEntryData_IncomingCopyWithImpl;
@useResult
$Res call({
 String from, List<NativeWalletTransferIn> transfers
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_IncomingCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_IncomingCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_IncomingCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_Incoming _self;
  final $Res Function(NativeWalletTransactionEntryData_Incoming) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = null,Object? transfers = null,}) {
  return _then(NativeWalletTransactionEntryData_Incoming(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,transfers: null == transfers ? _self._transfers : transfers // ignore: cast_nullable_to_non_nullable
as List<NativeWalletTransferIn>,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_Outgoing extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_Outgoing({required  List<NativeWalletTransferOut> transfers, required this.fee, required this.nonce}): _transfers = transfers,super._();
  

 final  List<NativeWalletTransferOut> _transfers;
 List<NativeWalletTransferOut> get transfers {
  if (_transfers is EqualUnmodifiableListView) return _transfers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transfers);
}

 final  BigInt fee;
 final  BigInt nonce;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_OutgoingCopyWith<NativeWalletTransactionEntryData_Outgoing> get copyWith => _$NativeWalletTransactionEntryData_OutgoingCopyWithImpl<NativeWalletTransactionEntryData_Outgoing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_Outgoing&&const DeepCollectionEquality().equals(other._transfers, _transfers)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.nonce, nonce) || other.nonce == nonce));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transfers),fee,nonce);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.outgoing(transfers: $transfers, fee: $fee, nonce: $nonce)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_OutgoingCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_OutgoingCopyWith(NativeWalletTransactionEntryData_Outgoing value, $Res Function(NativeWalletTransactionEntryData_Outgoing) _then) = _$NativeWalletTransactionEntryData_OutgoingCopyWithImpl;
@useResult
$Res call({
 List<NativeWalletTransferOut> transfers, BigInt fee, BigInt nonce
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_OutgoingCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_OutgoingCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_OutgoingCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_Outgoing _self;
  final $Res Function(NativeWalletTransactionEntryData_Outgoing) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transfers = null,Object? fee = null,Object? nonce = null,}) {
  return _then(NativeWalletTransactionEntryData_Outgoing(
transfers: null == transfers ? _self._transfers : transfers // ignore: cast_nullable_to_non_nullable
as List<NativeWalletTransferOut>,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_Multisig extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_Multisig({required  List<String> participants, required this.threshold, required this.fee, required this.nonce}): _participants = participants,super._();
  

 final  List<String> _participants;
 List<String> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

 final  int threshold;
 final  BigInt fee;
 final  BigInt nonce;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_MultisigCopyWith<NativeWalletTransactionEntryData_Multisig> get copyWith => _$NativeWalletTransactionEntryData_MultisigCopyWithImpl<NativeWalletTransactionEntryData_Multisig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_Multisig&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.nonce, nonce) || other.nonce == nonce));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_participants),threshold,fee,nonce);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.multisig(participants: $participants, threshold: $threshold, fee: $fee, nonce: $nonce)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_MultisigCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_MultisigCopyWith(NativeWalletTransactionEntryData_Multisig value, $Res Function(NativeWalletTransactionEntryData_Multisig) _then) = _$NativeWalletTransactionEntryData_MultisigCopyWithImpl;
@useResult
$Res call({
 List<String> participants, int threshold, BigInt fee, BigInt nonce
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_MultisigCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_MultisigCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_MultisigCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_Multisig _self;
  final $Res Function(NativeWalletTransactionEntryData_Multisig) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? participants = null,Object? threshold = null,Object? fee = null,Object? nonce = null,}) {
  return _then(NativeWalletTransactionEntryData_Multisig(
participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_InvokeContract extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_InvokeContract({required this.contract, required  List<NativeWalletAssetAmount> deposits, required  List<NativeWalletContractTransferGroup> received, required this.chunkId, required this.fee, required this.maxGas, required this.nonce}): _deposits = deposits,_received = received,super._();
  

 final  String contract;
 final  List<NativeWalletAssetAmount> _deposits;
 List<NativeWalletAssetAmount> get deposits {
  if (_deposits is EqualUnmodifiableListView) return _deposits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deposits);
}

 final  List<NativeWalletContractTransferGroup> _received;
 List<NativeWalletContractTransferGroup> get received {
  if (_received is EqualUnmodifiableListView) return _received;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_received);
}

 final  int chunkId;
 final  BigInt fee;
 final  BigInt maxGas;
 final  BigInt nonce;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_InvokeContractCopyWith<NativeWalletTransactionEntryData_InvokeContract> get copyWith => _$NativeWalletTransactionEntryData_InvokeContractCopyWithImpl<NativeWalletTransactionEntryData_InvokeContract>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_InvokeContract&&(identical(other.contract, contract) || other.contract == contract)&&const DeepCollectionEquality().equals(other._deposits, _deposits)&&const DeepCollectionEquality().equals(other._received, _received)&&(identical(other.chunkId, chunkId) || other.chunkId == chunkId)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.maxGas, maxGas) || other.maxGas == maxGas)&&(identical(other.nonce, nonce) || other.nonce == nonce));
}


@override
int get hashCode => Object.hash(runtimeType,contract,const DeepCollectionEquality().hash(_deposits),const DeepCollectionEquality().hash(_received),chunkId,fee,maxGas,nonce);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.invokeContract(contract: $contract, deposits: $deposits, received: $received, chunkId: $chunkId, fee: $fee, maxGas: $maxGas, nonce: $nonce)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_InvokeContractCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_InvokeContractCopyWith(NativeWalletTransactionEntryData_InvokeContract value, $Res Function(NativeWalletTransactionEntryData_InvokeContract) _then) = _$NativeWalletTransactionEntryData_InvokeContractCopyWithImpl;
@useResult
$Res call({
 String contract, List<NativeWalletAssetAmount> deposits, List<NativeWalletContractTransferGroup> received, int chunkId, BigInt fee, BigInt maxGas, BigInt nonce
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_InvokeContractCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_InvokeContractCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_InvokeContractCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_InvokeContract _self;
  final $Res Function(NativeWalletTransactionEntryData_InvokeContract) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? contract = null,Object? deposits = null,Object? received = null,Object? chunkId = null,Object? fee = null,Object? maxGas = null,Object? nonce = null,}) {
  return _then(NativeWalletTransactionEntryData_InvokeContract(
contract: null == contract ? _self.contract : contract // ignore: cast_nullable_to_non_nullable
as String,deposits: null == deposits ? _self._deposits : deposits // ignore: cast_nullable_to_non_nullable
as List<NativeWalletAssetAmount>,received: null == received ? _self._received : received // ignore: cast_nullable_to_non_nullable
as List<NativeWalletContractTransferGroup>,chunkId: null == chunkId ? _self.chunkId : chunkId // ignore: cast_nullable_to_non_nullable
as int,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,maxGas: null == maxGas ? _self.maxGas : maxGas // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_DeployContract extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_DeployContract({required this.fee, required this.nonce, this.invoke}): super._();
  

 final  BigInt fee;
 final  BigInt nonce;
 final  NativeWalletDeployInvoke? invoke;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_DeployContractCopyWith<NativeWalletTransactionEntryData_DeployContract> get copyWith => _$NativeWalletTransactionEntryData_DeployContractCopyWithImpl<NativeWalletTransactionEntryData_DeployContract>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_DeployContract&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.nonce, nonce) || other.nonce == nonce)&&(identical(other.invoke, invoke) || other.invoke == invoke));
}


@override
int get hashCode => Object.hash(runtimeType,fee,nonce,invoke);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.deployContract(fee: $fee, nonce: $nonce, invoke: $invoke)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_DeployContractCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_DeployContractCopyWith(NativeWalletTransactionEntryData_DeployContract value, $Res Function(NativeWalletTransactionEntryData_DeployContract) _then) = _$NativeWalletTransactionEntryData_DeployContractCopyWithImpl;
@useResult
$Res call({
 BigInt fee, BigInt nonce, NativeWalletDeployInvoke? invoke
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_DeployContractCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_DeployContractCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_DeployContractCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_DeployContract _self;
  final $Res Function(NativeWalletTransactionEntryData_DeployContract) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fee = null,Object? nonce = null,Object? invoke = freezed,}) {
  return _then(NativeWalletTransactionEntryData_DeployContract(
fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,invoke: freezed == invoke ? _self.invoke : invoke // ignore: cast_nullable_to_non_nullable
as NativeWalletDeployInvoke?,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_IncomingContract extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_IncomingContract({required  List<NativeWalletContractTransferGroup> transfers}): _transfers = transfers,super._();
  

 final  List<NativeWalletContractTransferGroup> _transfers;
 List<NativeWalletContractTransferGroup> get transfers {
  if (_transfers is EqualUnmodifiableListView) return _transfers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transfers);
}


/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_IncomingContractCopyWith<NativeWalletTransactionEntryData_IncomingContract> get copyWith => _$NativeWalletTransactionEntryData_IncomingContractCopyWithImpl<NativeWalletTransactionEntryData_IncomingContract>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_IncomingContract&&const DeepCollectionEquality().equals(other._transfers, _transfers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transfers));

@override
String toString() {
  return 'NativeWalletTransactionEntryData.incomingContract(transfers: $transfers)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_IncomingContractCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_IncomingContractCopyWith(NativeWalletTransactionEntryData_IncomingContract value, $Res Function(NativeWalletTransactionEntryData_IncomingContract) _then) = _$NativeWalletTransactionEntryData_IncomingContractCopyWithImpl;
@useResult
$Res call({
 List<NativeWalletContractTransferGroup> transfers
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_IncomingContractCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_IncomingContractCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_IncomingContractCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_IncomingContract _self;
  final $Res Function(NativeWalletTransactionEntryData_IncomingContract) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transfers = null,}) {
  return _then(NativeWalletTransactionEntryData_IncomingContract(
transfers: null == transfers ? _self._transfers : transfers // ignore: cast_nullable_to_non_nullable
as List<NativeWalletContractTransferGroup>,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_OutgoingBlob extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_OutgoingBlob({required  List<String> destinations, required this.fee, required this.nonce, required this.data}): _destinations = destinations,super._();
  

 final  List<String> _destinations;
 List<String> get destinations {
  if (_destinations is EqualUnmodifiableListView) return _destinations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destinations);
}

 final  BigInt fee;
 final  BigInt nonce;
 final  NativeWalletExtraData data;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_OutgoingBlobCopyWith<NativeWalletTransactionEntryData_OutgoingBlob> get copyWith => _$NativeWalletTransactionEntryData_OutgoingBlobCopyWithImpl<NativeWalletTransactionEntryData_OutgoingBlob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_OutgoingBlob&&const DeepCollectionEquality().equals(other._destinations, _destinations)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.nonce, nonce) || other.nonce == nonce)&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_destinations),fee,nonce,data);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.outgoingBlob(destinations: $destinations, fee: $fee, nonce: $nonce, data: $data)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_OutgoingBlobCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_OutgoingBlobCopyWith(NativeWalletTransactionEntryData_OutgoingBlob value, $Res Function(NativeWalletTransactionEntryData_OutgoingBlob) _then) = _$NativeWalletTransactionEntryData_OutgoingBlobCopyWithImpl;
@useResult
$Res call({
 List<String> destinations, BigInt fee, BigInt nonce, NativeWalletExtraData data
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_OutgoingBlobCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_OutgoingBlobCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_OutgoingBlobCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_OutgoingBlob _self;
  final $Res Function(NativeWalletTransactionEntryData_OutgoingBlob) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? destinations = null,Object? fee = null,Object? nonce = null,Object? data = null,}) {
  return _then(NativeWalletTransactionEntryData_OutgoingBlob(
destinations: null == destinations ? _self._destinations : destinations // ignore: cast_nullable_to_non_nullable
as List<String>,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as BigInt,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as BigInt,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NativeWalletExtraData,
  ));
}


}

/// @nodoc


class NativeWalletTransactionEntryData_IncomingBlob extends NativeWalletTransactionEntryData {
  const NativeWalletTransactionEntryData_IncomingBlob({required this.from, required  List<String> destinations, required this.data}): _destinations = destinations,super._();
  

 final  String from;
 final  List<String> _destinations;
 List<String> get destinations {
  if (_destinations is EqualUnmodifiableListView) return _destinations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destinations);
}

 final  NativeWalletExtraData data;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletTransactionEntryData_IncomingBlobCopyWith<NativeWalletTransactionEntryData_IncomingBlob> get copyWith => _$NativeWalletTransactionEntryData_IncomingBlobCopyWithImpl<NativeWalletTransactionEntryData_IncomingBlob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletTransactionEntryData_IncomingBlob&&(identical(other.from, from) || other.from == from)&&const DeepCollectionEquality().equals(other._destinations, _destinations)&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,from,const DeepCollectionEquality().hash(_destinations),data);

@override
String toString() {
  return 'NativeWalletTransactionEntryData.incomingBlob(from: $from, destinations: $destinations, data: $data)';
}


}

/// @nodoc
abstract mixin class $NativeWalletTransactionEntryData_IncomingBlobCopyWith<$Res> implements $NativeWalletTransactionEntryDataCopyWith<$Res> {
  factory $NativeWalletTransactionEntryData_IncomingBlobCopyWith(NativeWalletTransactionEntryData_IncomingBlob value, $Res Function(NativeWalletTransactionEntryData_IncomingBlob) _then) = _$NativeWalletTransactionEntryData_IncomingBlobCopyWithImpl;
@useResult
$Res call({
 String from, List<String> destinations, NativeWalletExtraData data
});




}
/// @nodoc
class _$NativeWalletTransactionEntryData_IncomingBlobCopyWithImpl<$Res>
    implements $NativeWalletTransactionEntryData_IncomingBlobCopyWith<$Res> {
  _$NativeWalletTransactionEntryData_IncomingBlobCopyWithImpl(this._self, this._then);

  final NativeWalletTransactionEntryData_IncomingBlob _self;
  final $Res Function(NativeWalletTransactionEntryData_IncomingBlob) _then;

/// Create a copy of NativeWalletTransactionEntryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = null,Object? destinations = null,Object? data = null,}) {
  return _then(NativeWalletTransactionEntryData_IncomingBlob(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,destinations: null == destinations ? _self._destinations : destinations // ignore: cast_nullable_to_non_nullable
as List<String>,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NativeWalletExtraData,
  ));
}


}

// dart format on
