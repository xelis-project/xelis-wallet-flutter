// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_event_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NativeWalletRuntimeEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeWalletRuntimeEvent()';
}


}

/// @nodoc
class $NativeWalletRuntimeEventCopyWith<$Res>  {
$NativeWalletRuntimeEventCopyWith(NativeWalletRuntimeEvent _, $Res Function(NativeWalletRuntimeEvent) __);
}


/// Adds pattern-matching-related methods to [NativeWalletRuntimeEvent].
extension NativeWalletRuntimeEventPatterns on NativeWalletRuntimeEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NativeWalletRuntimeEvent_Online value)?  online,TResult Function( NativeWalletRuntimeEvent_Offline value)?  offline,TResult Function( NativeWalletRuntimeEvent_SyncIssue value)?  syncIssue,TResult Function( NativeWalletRuntimeEvent_NewTopoHeight value)?  newTopoHeight,TResult Function( NativeWalletRuntimeEvent_Rescan value)?  rescan,TResult Function( NativeWalletRuntimeEvent_HistorySynced value)?  historySynced,TResult Function( NativeWalletRuntimeEvent_Degraded value)?  degraded,TResult Function( NativeWalletRuntimeEvent_Closed value)?  closed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NativeWalletRuntimeEvent_Online() when online != null:
return online(_that);case NativeWalletRuntimeEvent_Offline() when offline != null:
return offline(_that);case NativeWalletRuntimeEvent_SyncIssue() when syncIssue != null:
return syncIssue(_that);case NativeWalletRuntimeEvent_NewTopoHeight() when newTopoHeight != null:
return newTopoHeight(_that);case NativeWalletRuntimeEvent_Rescan() when rescan != null:
return rescan(_that);case NativeWalletRuntimeEvent_HistorySynced() when historySynced != null:
return historySynced(_that);case NativeWalletRuntimeEvent_Degraded() when degraded != null:
return degraded(_that);case NativeWalletRuntimeEvent_Closed() when closed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NativeWalletRuntimeEvent_Online value)  online,required TResult Function( NativeWalletRuntimeEvent_Offline value)  offline,required TResult Function( NativeWalletRuntimeEvent_SyncIssue value)  syncIssue,required TResult Function( NativeWalletRuntimeEvent_NewTopoHeight value)  newTopoHeight,required TResult Function( NativeWalletRuntimeEvent_Rescan value)  rescan,required TResult Function( NativeWalletRuntimeEvent_HistorySynced value)  historySynced,required TResult Function( NativeWalletRuntimeEvent_Degraded value)  degraded,required TResult Function( NativeWalletRuntimeEvent_Closed value)  closed,}){
final _that = this;
switch (_that) {
case NativeWalletRuntimeEvent_Online():
return online(_that);case NativeWalletRuntimeEvent_Offline():
return offline(_that);case NativeWalletRuntimeEvent_SyncIssue():
return syncIssue(_that);case NativeWalletRuntimeEvent_NewTopoHeight():
return newTopoHeight(_that);case NativeWalletRuntimeEvent_Rescan():
return rescan(_that);case NativeWalletRuntimeEvent_HistorySynced():
return historySynced(_that);case NativeWalletRuntimeEvent_Degraded():
return degraded(_that);case NativeWalletRuntimeEvent_Closed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NativeWalletRuntimeEvent_Online value)?  online,TResult? Function( NativeWalletRuntimeEvent_Offline value)?  offline,TResult? Function( NativeWalletRuntimeEvent_SyncIssue value)?  syncIssue,TResult? Function( NativeWalletRuntimeEvent_NewTopoHeight value)?  newTopoHeight,TResult? Function( NativeWalletRuntimeEvent_Rescan value)?  rescan,TResult? Function( NativeWalletRuntimeEvent_HistorySynced value)?  historySynced,TResult? Function( NativeWalletRuntimeEvent_Degraded value)?  degraded,TResult? Function( NativeWalletRuntimeEvent_Closed value)?  closed,}){
final _that = this;
switch (_that) {
case NativeWalletRuntimeEvent_Online() when online != null:
return online(_that);case NativeWalletRuntimeEvent_Offline() when offline != null:
return offline(_that);case NativeWalletRuntimeEvent_SyncIssue() when syncIssue != null:
return syncIssue(_that);case NativeWalletRuntimeEvent_NewTopoHeight() when newTopoHeight != null:
return newTopoHeight(_that);case NativeWalletRuntimeEvent_Rescan() when rescan != null:
return rescan(_that);case NativeWalletRuntimeEvent_HistorySynced() when historySynced != null:
return historySynced(_that);case NativeWalletRuntimeEvent_Degraded() when degraded != null:
return degraded(_that);case NativeWalletRuntimeEvent_Closed() when closed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  online,TResult Function()?  offline,TResult Function( NativeXelisError failure)?  syncIssue,TResult Function( BigInt topoheight)?  newTopoHeight,TResult Function( BigInt startTopoheight)?  rescan,TResult Function( BigInt topoheight)?  historySynced,TResult Function( BigInt skippedEvents,  NativeXelisError failure)?  degraded,TResult Function( NativeWalletRuntimeStreamCloseReason reason,  NativeXelisError failure)?  closed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NativeWalletRuntimeEvent_Online() when online != null:
return online();case NativeWalletRuntimeEvent_Offline() when offline != null:
return offline();case NativeWalletRuntimeEvent_SyncIssue() when syncIssue != null:
return syncIssue(_that.failure);case NativeWalletRuntimeEvent_NewTopoHeight() when newTopoHeight != null:
return newTopoHeight(_that.topoheight);case NativeWalletRuntimeEvent_Rescan() when rescan != null:
return rescan(_that.startTopoheight);case NativeWalletRuntimeEvent_HistorySynced() when historySynced != null:
return historySynced(_that.topoheight);case NativeWalletRuntimeEvent_Degraded() when degraded != null:
return degraded(_that.skippedEvents,_that.failure);case NativeWalletRuntimeEvent_Closed() when closed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  online,required TResult Function()  offline,required TResult Function( NativeXelisError failure)  syncIssue,required TResult Function( BigInt topoheight)  newTopoHeight,required TResult Function( BigInt startTopoheight)  rescan,required TResult Function( BigInt topoheight)  historySynced,required TResult Function( BigInt skippedEvents,  NativeXelisError failure)  degraded,required TResult Function( NativeWalletRuntimeStreamCloseReason reason,  NativeXelisError failure)  closed,}) {final _that = this;
switch (_that) {
case NativeWalletRuntimeEvent_Online():
return online();case NativeWalletRuntimeEvent_Offline():
return offline();case NativeWalletRuntimeEvent_SyncIssue():
return syncIssue(_that.failure);case NativeWalletRuntimeEvent_NewTopoHeight():
return newTopoHeight(_that.topoheight);case NativeWalletRuntimeEvent_Rescan():
return rescan(_that.startTopoheight);case NativeWalletRuntimeEvent_HistorySynced():
return historySynced(_that.topoheight);case NativeWalletRuntimeEvent_Degraded():
return degraded(_that.skippedEvents,_that.failure);case NativeWalletRuntimeEvent_Closed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  online,TResult? Function()?  offline,TResult? Function( NativeXelisError failure)?  syncIssue,TResult? Function( BigInt topoheight)?  newTopoHeight,TResult? Function( BigInt startTopoheight)?  rescan,TResult? Function( BigInt topoheight)?  historySynced,TResult? Function( BigInt skippedEvents,  NativeXelisError failure)?  degraded,TResult? Function( NativeWalletRuntimeStreamCloseReason reason,  NativeXelisError failure)?  closed,}) {final _that = this;
switch (_that) {
case NativeWalletRuntimeEvent_Online() when online != null:
return online();case NativeWalletRuntimeEvent_Offline() when offline != null:
return offline();case NativeWalletRuntimeEvent_SyncIssue() when syncIssue != null:
return syncIssue(_that.failure);case NativeWalletRuntimeEvent_NewTopoHeight() when newTopoHeight != null:
return newTopoHeight(_that.topoheight);case NativeWalletRuntimeEvent_Rescan() when rescan != null:
return rescan(_that.startTopoheight);case NativeWalletRuntimeEvent_HistorySynced() when historySynced != null:
return historySynced(_that.topoheight);case NativeWalletRuntimeEvent_Degraded() when degraded != null:
return degraded(_that.skippedEvents,_that.failure);case NativeWalletRuntimeEvent_Closed() when closed != null:
return closed(_that.reason,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class NativeWalletRuntimeEvent_Online extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_Online(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_Online);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeWalletRuntimeEvent.online()';
}


}




/// @nodoc


class NativeWalletRuntimeEvent_Offline extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_Offline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_Offline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NativeWalletRuntimeEvent.offline()';
}


}




/// @nodoc


class NativeWalletRuntimeEvent_SyncIssue extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_SyncIssue({required this.failure}): super._();
  

 final  NativeXelisError failure;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletRuntimeEvent_SyncIssueCopyWith<NativeWalletRuntimeEvent_SyncIssue> get copyWith => _$NativeWalletRuntimeEvent_SyncIssueCopyWithImpl<NativeWalletRuntimeEvent_SyncIssue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_SyncIssue&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NativeWalletRuntimeEvent.syncIssue(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativeWalletRuntimeEvent_SyncIssueCopyWith<$Res> implements $NativeWalletRuntimeEventCopyWith<$Res> {
  factory $NativeWalletRuntimeEvent_SyncIssueCopyWith(NativeWalletRuntimeEvent_SyncIssue value, $Res Function(NativeWalletRuntimeEvent_SyncIssue) _then) = _$NativeWalletRuntimeEvent_SyncIssueCopyWithImpl;
@useResult
$Res call({
 NativeXelisError failure
});




}
/// @nodoc
class _$NativeWalletRuntimeEvent_SyncIssueCopyWithImpl<$Res>
    implements $NativeWalletRuntimeEvent_SyncIssueCopyWith<$Res> {
  _$NativeWalletRuntimeEvent_SyncIssueCopyWithImpl(this._self, this._then);

  final NativeWalletRuntimeEvent_SyncIssue _self;
  final $Res Function(NativeWalletRuntimeEvent_SyncIssue) _then;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NativeWalletRuntimeEvent_SyncIssue(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc


class NativeWalletRuntimeEvent_NewTopoHeight extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_NewTopoHeight({required this.topoheight}): super._();
  

 final  BigInt topoheight;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletRuntimeEvent_NewTopoHeightCopyWith<NativeWalletRuntimeEvent_NewTopoHeight> get copyWith => _$NativeWalletRuntimeEvent_NewTopoHeightCopyWithImpl<NativeWalletRuntimeEvent_NewTopoHeight>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_NewTopoHeight&&(identical(other.topoheight, topoheight) || other.topoheight == topoheight));
}


@override
int get hashCode => Object.hash(runtimeType,topoheight);

@override
String toString() {
  return 'NativeWalletRuntimeEvent.newTopoHeight(topoheight: $topoheight)';
}


}

/// @nodoc
abstract mixin class $NativeWalletRuntimeEvent_NewTopoHeightCopyWith<$Res> implements $NativeWalletRuntimeEventCopyWith<$Res> {
  factory $NativeWalletRuntimeEvent_NewTopoHeightCopyWith(NativeWalletRuntimeEvent_NewTopoHeight value, $Res Function(NativeWalletRuntimeEvent_NewTopoHeight) _then) = _$NativeWalletRuntimeEvent_NewTopoHeightCopyWithImpl;
@useResult
$Res call({
 BigInt topoheight
});




}
/// @nodoc
class _$NativeWalletRuntimeEvent_NewTopoHeightCopyWithImpl<$Res>
    implements $NativeWalletRuntimeEvent_NewTopoHeightCopyWith<$Res> {
  _$NativeWalletRuntimeEvent_NewTopoHeightCopyWithImpl(this._self, this._then);

  final NativeWalletRuntimeEvent_NewTopoHeight _self;
  final $Res Function(NativeWalletRuntimeEvent_NewTopoHeight) _then;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? topoheight = null,}) {
  return _then(NativeWalletRuntimeEvent_NewTopoHeight(
topoheight: null == topoheight ? _self.topoheight : topoheight // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletRuntimeEvent_Rescan extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_Rescan({required this.startTopoheight}): super._();
  

 final  BigInt startTopoheight;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletRuntimeEvent_RescanCopyWith<NativeWalletRuntimeEvent_Rescan> get copyWith => _$NativeWalletRuntimeEvent_RescanCopyWithImpl<NativeWalletRuntimeEvent_Rescan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_Rescan&&(identical(other.startTopoheight, startTopoheight) || other.startTopoheight == startTopoheight));
}


@override
int get hashCode => Object.hash(runtimeType,startTopoheight);

@override
String toString() {
  return 'NativeWalletRuntimeEvent.rescan(startTopoheight: $startTopoheight)';
}


}

/// @nodoc
abstract mixin class $NativeWalletRuntimeEvent_RescanCopyWith<$Res> implements $NativeWalletRuntimeEventCopyWith<$Res> {
  factory $NativeWalletRuntimeEvent_RescanCopyWith(NativeWalletRuntimeEvent_Rescan value, $Res Function(NativeWalletRuntimeEvent_Rescan) _then) = _$NativeWalletRuntimeEvent_RescanCopyWithImpl;
@useResult
$Res call({
 BigInt startTopoheight
});




}
/// @nodoc
class _$NativeWalletRuntimeEvent_RescanCopyWithImpl<$Res>
    implements $NativeWalletRuntimeEvent_RescanCopyWith<$Res> {
  _$NativeWalletRuntimeEvent_RescanCopyWithImpl(this._self, this._then);

  final NativeWalletRuntimeEvent_Rescan _self;
  final $Res Function(NativeWalletRuntimeEvent_Rescan) _then;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startTopoheight = null,}) {
  return _then(NativeWalletRuntimeEvent_Rescan(
startTopoheight: null == startTopoheight ? _self.startTopoheight : startTopoheight // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletRuntimeEvent_HistorySynced extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_HistorySynced({required this.topoheight}): super._();
  

 final  BigInt topoheight;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletRuntimeEvent_HistorySyncedCopyWith<NativeWalletRuntimeEvent_HistorySynced> get copyWith => _$NativeWalletRuntimeEvent_HistorySyncedCopyWithImpl<NativeWalletRuntimeEvent_HistorySynced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_HistorySynced&&(identical(other.topoheight, topoheight) || other.topoheight == topoheight));
}


@override
int get hashCode => Object.hash(runtimeType,topoheight);

@override
String toString() {
  return 'NativeWalletRuntimeEvent.historySynced(topoheight: $topoheight)';
}


}

/// @nodoc
abstract mixin class $NativeWalletRuntimeEvent_HistorySyncedCopyWith<$Res> implements $NativeWalletRuntimeEventCopyWith<$Res> {
  factory $NativeWalletRuntimeEvent_HistorySyncedCopyWith(NativeWalletRuntimeEvent_HistorySynced value, $Res Function(NativeWalletRuntimeEvent_HistorySynced) _then) = _$NativeWalletRuntimeEvent_HistorySyncedCopyWithImpl;
@useResult
$Res call({
 BigInt topoheight
});




}
/// @nodoc
class _$NativeWalletRuntimeEvent_HistorySyncedCopyWithImpl<$Res>
    implements $NativeWalletRuntimeEvent_HistorySyncedCopyWith<$Res> {
  _$NativeWalletRuntimeEvent_HistorySyncedCopyWithImpl(this._self, this._then);

  final NativeWalletRuntimeEvent_HistorySynced _self;
  final $Res Function(NativeWalletRuntimeEvent_HistorySynced) _then;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? topoheight = null,}) {
  return _then(NativeWalletRuntimeEvent_HistorySynced(
topoheight: null == topoheight ? _self.topoheight : topoheight // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class NativeWalletRuntimeEvent_Degraded extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_Degraded({required this.skippedEvents, required this.failure}): super._();
  

 final  BigInt skippedEvents;
 final  NativeXelisError failure;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletRuntimeEvent_DegradedCopyWith<NativeWalletRuntimeEvent_Degraded> get copyWith => _$NativeWalletRuntimeEvent_DegradedCopyWithImpl<NativeWalletRuntimeEvent_Degraded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_Degraded&&(identical(other.skippedEvents, skippedEvents) || other.skippedEvents == skippedEvents)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,skippedEvents,failure);

@override
String toString() {
  return 'NativeWalletRuntimeEvent.degraded(skippedEvents: $skippedEvents, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativeWalletRuntimeEvent_DegradedCopyWith<$Res> implements $NativeWalletRuntimeEventCopyWith<$Res> {
  factory $NativeWalletRuntimeEvent_DegradedCopyWith(NativeWalletRuntimeEvent_Degraded value, $Res Function(NativeWalletRuntimeEvent_Degraded) _then) = _$NativeWalletRuntimeEvent_DegradedCopyWithImpl;
@useResult
$Res call({
 BigInt skippedEvents, NativeXelisError failure
});




}
/// @nodoc
class _$NativeWalletRuntimeEvent_DegradedCopyWithImpl<$Res>
    implements $NativeWalletRuntimeEvent_DegradedCopyWith<$Res> {
  _$NativeWalletRuntimeEvent_DegradedCopyWithImpl(this._self, this._then);

  final NativeWalletRuntimeEvent_Degraded _self;
  final $Res Function(NativeWalletRuntimeEvent_Degraded) _then;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? skippedEvents = null,Object? failure = null,}) {
  return _then(NativeWalletRuntimeEvent_Degraded(
skippedEvents: null == skippedEvents ? _self.skippedEvents : skippedEvents // ignore: cast_nullable_to_non_nullable
as BigInt,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

/// @nodoc


class NativeWalletRuntimeEvent_Closed extends NativeWalletRuntimeEvent {
  const NativeWalletRuntimeEvent_Closed({required this.reason, required this.failure}): super._();
  

 final  NativeWalletRuntimeStreamCloseReason reason;
 final  NativeXelisError failure;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeWalletRuntimeEvent_ClosedCopyWith<NativeWalletRuntimeEvent_Closed> get copyWith => _$NativeWalletRuntimeEvent_ClosedCopyWithImpl<NativeWalletRuntimeEvent_Closed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeWalletRuntimeEvent_Closed&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,reason,failure);

@override
String toString() {
  return 'NativeWalletRuntimeEvent.closed(reason: $reason, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NativeWalletRuntimeEvent_ClosedCopyWith<$Res> implements $NativeWalletRuntimeEventCopyWith<$Res> {
  factory $NativeWalletRuntimeEvent_ClosedCopyWith(NativeWalletRuntimeEvent_Closed value, $Res Function(NativeWalletRuntimeEvent_Closed) _then) = _$NativeWalletRuntimeEvent_ClosedCopyWithImpl;
@useResult
$Res call({
 NativeWalletRuntimeStreamCloseReason reason, NativeXelisError failure
});




}
/// @nodoc
class _$NativeWalletRuntimeEvent_ClosedCopyWithImpl<$Res>
    implements $NativeWalletRuntimeEvent_ClosedCopyWith<$Res> {
  _$NativeWalletRuntimeEvent_ClosedCopyWithImpl(this._self, this._then);

  final NativeWalletRuntimeEvent_Closed _self;
  final $Res Function(NativeWalletRuntimeEvent_Closed) _then;

/// Create a copy of NativeWalletRuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? failure = null,}) {
  return _then(NativeWalletRuntimeEvent_Closed(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as NativeWalletRuntimeStreamCloseReason,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NativeXelisError,
  ));
}


}

// dart format on
