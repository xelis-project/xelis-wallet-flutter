// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_book_v2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NativeAddressBookEntry {

 String get id; String get displayName; String? get destinationLabel; String? get note; NativeSavedDestination get destination;
/// Create a copy of NativeAddressBookEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeAddressBookEntryCopyWith<NativeAddressBookEntry> get copyWith => _$NativeAddressBookEntryCopyWithImpl<NativeAddressBookEntry>(this as NativeAddressBookEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeAddressBookEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.destinationLabel, destinationLabel) || other.destinationLabel == destinationLabel)&&(identical(other.note, note) || other.note == note)&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,destinationLabel,note,destination);

@override
String toString() {
  return 'NativeAddressBookEntry(id: $id, displayName: $displayName, destinationLabel: $destinationLabel, note: $note, destination: $destination)';
}


}

/// @nodoc
abstract mixin class $NativeAddressBookEntryCopyWith<$Res>  {
  factory $NativeAddressBookEntryCopyWith(NativeAddressBookEntry value, $Res Function(NativeAddressBookEntry) _then) = _$NativeAddressBookEntryCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? destinationLabel, String? note, NativeSavedDestination destination
});


$NativeSavedDestinationCopyWith<$Res> get destination;

}
/// @nodoc
class _$NativeAddressBookEntryCopyWithImpl<$Res>
    implements $NativeAddressBookEntryCopyWith<$Res> {
  _$NativeAddressBookEntryCopyWithImpl(this._self, this._then);

  final NativeAddressBookEntry _self;
  final $Res Function(NativeAddressBookEntry) _then;

/// Create a copy of NativeAddressBookEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? destinationLabel = freezed,Object? note = freezed,Object? destination = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,destinationLabel: freezed == destinationLabel ? _self.destinationLabel : destinationLabel // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as NativeSavedDestination,
  ));
}
/// Create a copy of NativeAddressBookEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeSavedDestinationCopyWith<$Res> get destination {
  
  return $NativeSavedDestinationCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeAddressBookEntry].
extension NativeAddressBookEntryPatterns on NativeAddressBookEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeAddressBookEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeAddressBookEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeAddressBookEntry value)  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeAddressBookEntry value)?  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? destinationLabel,  String? note,  NativeSavedDestination destination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeAddressBookEntry() when $default != null:
return $default(_that.id,_that.displayName,_that.destinationLabel,_that.note,_that.destination);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? destinationLabel,  String? note,  NativeSavedDestination destination)  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookEntry():
return $default(_that.id,_that.displayName,_that.destinationLabel,_that.note,_that.destination);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? destinationLabel,  String? note,  NativeSavedDestination destination)?  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookEntry() when $default != null:
return $default(_that.id,_that.displayName,_that.destinationLabel,_that.note,_that.destination);case _:
  return null;

}
}

}

/// @nodoc


class _NativeAddressBookEntry implements NativeAddressBookEntry {
  const _NativeAddressBookEntry({required this.id, required this.displayName, this.destinationLabel, this.note, required this.destination});
  

@override final  String id;
@override final  String displayName;
@override final  String? destinationLabel;
@override final  String? note;
@override final  NativeSavedDestination destination;

/// Create a copy of NativeAddressBookEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeAddressBookEntryCopyWith<_NativeAddressBookEntry> get copyWith => __$NativeAddressBookEntryCopyWithImpl<_NativeAddressBookEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeAddressBookEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.destinationLabel, destinationLabel) || other.destinationLabel == destinationLabel)&&(identical(other.note, note) || other.note == note)&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,destinationLabel,note,destination);

@override
String toString() {
  return 'NativeAddressBookEntry(id: $id, displayName: $displayName, destinationLabel: $destinationLabel, note: $note, destination: $destination)';
}


}

/// @nodoc
abstract mixin class _$NativeAddressBookEntryCopyWith<$Res> implements $NativeAddressBookEntryCopyWith<$Res> {
  factory _$NativeAddressBookEntryCopyWith(_NativeAddressBookEntry value, $Res Function(_NativeAddressBookEntry) _then) = __$NativeAddressBookEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? destinationLabel, String? note, NativeSavedDestination destination
});


@override $NativeSavedDestinationCopyWith<$Res> get destination;

}
/// @nodoc
class __$NativeAddressBookEntryCopyWithImpl<$Res>
    implements _$NativeAddressBookEntryCopyWith<$Res> {
  __$NativeAddressBookEntryCopyWithImpl(this._self, this._then);

  final _NativeAddressBookEntry _self;
  final $Res Function(_NativeAddressBookEntry) _then;

/// Create a copy of NativeAddressBookEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? destinationLabel = freezed,Object? note = freezed,Object? destination = null,}) {
  return _then(_NativeAddressBookEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,destinationLabel: freezed == destinationLabel ? _self.destinationLabel : destinationLabel // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as NativeSavedDestination,
  ));
}

/// Create a copy of NativeAddressBookEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeSavedDestinationCopyWith<$Res> get destination {
  
  return $NativeSavedDestinationCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}

/// @nodoc
mixin _$NativeAddressBookMatch {

 NativeAddressBookMatchKind get kind; List<NativeAddressBookEntry> get entries;
/// Create a copy of NativeAddressBookMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeAddressBookMatchCopyWith<NativeAddressBookMatch> get copyWith => _$NativeAddressBookMatchCopyWithImpl<NativeAddressBookMatch>(this as NativeAddressBookMatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeAddressBookMatch&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.entries, entries));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'NativeAddressBookMatch(kind: $kind, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $NativeAddressBookMatchCopyWith<$Res>  {
  factory $NativeAddressBookMatchCopyWith(NativeAddressBookMatch value, $Res Function(NativeAddressBookMatch) _then) = _$NativeAddressBookMatchCopyWithImpl;
@useResult
$Res call({
 NativeAddressBookMatchKind kind, List<NativeAddressBookEntry> entries
});




}
/// @nodoc
class _$NativeAddressBookMatchCopyWithImpl<$Res>
    implements $NativeAddressBookMatchCopyWith<$Res> {
  _$NativeAddressBookMatchCopyWithImpl(this._self, this._then);

  final NativeAddressBookMatch _self;
  final $Res Function(NativeAddressBookMatch) _then;

/// Create a copy of NativeAddressBookMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? entries = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NativeAddressBookMatchKind,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<NativeAddressBookEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeAddressBookMatch].
extension NativeAddressBookMatchPatterns on NativeAddressBookMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeAddressBookMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeAddressBookMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeAddressBookMatch value)  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeAddressBookMatch value)?  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NativeAddressBookMatchKind kind,  List<NativeAddressBookEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeAddressBookMatch() when $default != null:
return $default(_that.kind,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NativeAddressBookMatchKind kind,  List<NativeAddressBookEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookMatch():
return $default(_that.kind,_that.entries);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NativeAddressBookMatchKind kind,  List<NativeAddressBookEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookMatch() when $default != null:
return $default(_that.kind,_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class _NativeAddressBookMatch implements NativeAddressBookMatch {
  const _NativeAddressBookMatch({required this.kind, required final  List<NativeAddressBookEntry> entries}): _entries = entries;
  

@override final  NativeAddressBookMatchKind kind;
 final  List<NativeAddressBookEntry> _entries;
@override List<NativeAddressBookEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of NativeAddressBookMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeAddressBookMatchCopyWith<_NativeAddressBookMatch> get copyWith => __$NativeAddressBookMatchCopyWithImpl<_NativeAddressBookMatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeAddressBookMatch&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._entries, _entries));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'NativeAddressBookMatch(kind: $kind, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$NativeAddressBookMatchCopyWith<$Res> implements $NativeAddressBookMatchCopyWith<$Res> {
  factory _$NativeAddressBookMatchCopyWith(_NativeAddressBookMatch value, $Res Function(_NativeAddressBookMatch) _then) = __$NativeAddressBookMatchCopyWithImpl;
@override @useResult
$Res call({
 NativeAddressBookMatchKind kind, List<NativeAddressBookEntry> entries
});




}
/// @nodoc
class __$NativeAddressBookMatchCopyWithImpl<$Res>
    implements _$NativeAddressBookMatchCopyWith<$Res> {
  __$NativeAddressBookMatchCopyWithImpl(this._self, this._then);

  final _NativeAddressBookMatch _self;
  final $Res Function(_NativeAddressBookMatch) _then;

/// Create a copy of NativeAddressBookMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? entries = null,}) {
  return _then(_NativeAddressBookMatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NativeAddressBookMatchKind,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<NativeAddressBookEntry>,
  ));
}


}

/// @nodoc
mixin _$NativeAddressBookMigrationResult {

 int get migratedEntries; bool get alreadyComplete;
/// Create a copy of NativeAddressBookMigrationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeAddressBookMigrationResultCopyWith<NativeAddressBookMigrationResult> get copyWith => _$NativeAddressBookMigrationResultCopyWithImpl<NativeAddressBookMigrationResult>(this as NativeAddressBookMigrationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeAddressBookMigrationResult&&(identical(other.migratedEntries, migratedEntries) || other.migratedEntries == migratedEntries)&&(identical(other.alreadyComplete, alreadyComplete) || other.alreadyComplete == alreadyComplete));
}


@override
int get hashCode => Object.hash(runtimeType,migratedEntries,alreadyComplete);

@override
String toString() {
  return 'NativeAddressBookMigrationResult(migratedEntries: $migratedEntries, alreadyComplete: $alreadyComplete)';
}


}

/// @nodoc
abstract mixin class $NativeAddressBookMigrationResultCopyWith<$Res>  {
  factory $NativeAddressBookMigrationResultCopyWith(NativeAddressBookMigrationResult value, $Res Function(NativeAddressBookMigrationResult) _then) = _$NativeAddressBookMigrationResultCopyWithImpl;
@useResult
$Res call({
 int migratedEntries, bool alreadyComplete
});




}
/// @nodoc
class _$NativeAddressBookMigrationResultCopyWithImpl<$Res>
    implements $NativeAddressBookMigrationResultCopyWith<$Res> {
  _$NativeAddressBookMigrationResultCopyWithImpl(this._self, this._then);

  final NativeAddressBookMigrationResult _self;
  final $Res Function(NativeAddressBookMigrationResult) _then;

/// Create a copy of NativeAddressBookMigrationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? migratedEntries = null,Object? alreadyComplete = null,}) {
  return _then(_self.copyWith(
migratedEntries: null == migratedEntries ? _self.migratedEntries : migratedEntries // ignore: cast_nullable_to_non_nullable
as int,alreadyComplete: null == alreadyComplete ? _self.alreadyComplete : alreadyComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeAddressBookMigrationResult].
extension NativeAddressBookMigrationResultPatterns on NativeAddressBookMigrationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeAddressBookMigrationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeAddressBookMigrationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeAddressBookMigrationResult value)  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookMigrationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeAddressBookMigrationResult value)?  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookMigrationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int migratedEntries,  bool alreadyComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeAddressBookMigrationResult() when $default != null:
return $default(_that.migratedEntries,_that.alreadyComplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int migratedEntries,  bool alreadyComplete)  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookMigrationResult():
return $default(_that.migratedEntries,_that.alreadyComplete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int migratedEntries,  bool alreadyComplete)?  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookMigrationResult() when $default != null:
return $default(_that.migratedEntries,_that.alreadyComplete);case _:
  return null;

}
}

}

/// @nodoc


class _NativeAddressBookMigrationResult implements NativeAddressBookMigrationResult {
  const _NativeAddressBookMigrationResult({required this.migratedEntries, required this.alreadyComplete});
  

@override final  int migratedEntries;
@override final  bool alreadyComplete;

/// Create a copy of NativeAddressBookMigrationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeAddressBookMigrationResultCopyWith<_NativeAddressBookMigrationResult> get copyWith => __$NativeAddressBookMigrationResultCopyWithImpl<_NativeAddressBookMigrationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeAddressBookMigrationResult&&(identical(other.migratedEntries, migratedEntries) || other.migratedEntries == migratedEntries)&&(identical(other.alreadyComplete, alreadyComplete) || other.alreadyComplete == alreadyComplete));
}


@override
int get hashCode => Object.hash(runtimeType,migratedEntries,alreadyComplete);

@override
String toString() {
  return 'NativeAddressBookMigrationResult(migratedEntries: $migratedEntries, alreadyComplete: $alreadyComplete)';
}


}

/// @nodoc
abstract mixin class _$NativeAddressBookMigrationResultCopyWith<$Res> implements $NativeAddressBookMigrationResultCopyWith<$Res> {
  factory _$NativeAddressBookMigrationResultCopyWith(_NativeAddressBookMigrationResult value, $Res Function(_NativeAddressBookMigrationResult) _then) = __$NativeAddressBookMigrationResultCopyWithImpl;
@override @useResult
$Res call({
 int migratedEntries, bool alreadyComplete
});




}
/// @nodoc
class __$NativeAddressBookMigrationResultCopyWithImpl<$Res>
    implements _$NativeAddressBookMigrationResultCopyWith<$Res> {
  __$NativeAddressBookMigrationResultCopyWithImpl(this._self, this._then);

  final _NativeAddressBookMigrationResult _self;
  final $Res Function(_NativeAddressBookMigrationResult) _then;

/// Create a copy of NativeAddressBookMigrationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? migratedEntries = null,Object? alreadyComplete = null,}) {
  return _then(_NativeAddressBookMigrationResult(
migratedEntries: null == migratedEntries ? _self.migratedEntries : migratedEntries // ignore: cast_nullable_to_non_nullable
as int,alreadyComplete: null == alreadyComplete ? _self.alreadyComplete : alreadyComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$NativeAddressBookPage {

 List<NativeAddressBookEntry> get entries; int get total; bool get hasMore;
/// Create a copy of NativeAddressBookPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeAddressBookPageCopyWith<NativeAddressBookPage> get copyWith => _$NativeAddressBookPageCopyWithImpl<NativeAddressBookPage>(this as NativeAddressBookPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeAddressBookPage&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries),total,hasMore);

@override
String toString() {
  return 'NativeAddressBookPage(entries: $entries, total: $total, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $NativeAddressBookPageCopyWith<$Res>  {
  factory $NativeAddressBookPageCopyWith(NativeAddressBookPage value, $Res Function(NativeAddressBookPage) _then) = _$NativeAddressBookPageCopyWithImpl;
@useResult
$Res call({
 List<NativeAddressBookEntry> entries, int total, bool hasMore
});




}
/// @nodoc
class _$NativeAddressBookPageCopyWithImpl<$Res>
    implements $NativeAddressBookPageCopyWith<$Res> {
  _$NativeAddressBookPageCopyWithImpl(this._self, this._then);

  final NativeAddressBookPage _self;
  final $Res Function(NativeAddressBookPage) _then;

/// Create a copy of NativeAddressBookPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? total = null,Object? hasMore = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<NativeAddressBookEntry>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeAddressBookPage].
extension NativeAddressBookPagePatterns on NativeAddressBookPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeAddressBookPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeAddressBookPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeAddressBookPage value)  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeAddressBookPage value)?  $default,){
final _that = this;
switch (_that) {
case _NativeAddressBookPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NativeAddressBookEntry> entries,  int total,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeAddressBookPage() when $default != null:
return $default(_that.entries,_that.total,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NativeAddressBookEntry> entries,  int total,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookPage():
return $default(_that.entries,_that.total,_that.hasMore);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NativeAddressBookEntry> entries,  int total,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _NativeAddressBookPage() when $default != null:
return $default(_that.entries,_that.total,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _NativeAddressBookPage implements NativeAddressBookPage {
  const _NativeAddressBookPage({required final  List<NativeAddressBookEntry> entries, required this.total, required this.hasMore}): _entries = entries;
  

 final  List<NativeAddressBookEntry> _entries;
@override List<NativeAddressBookEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

@override final  int total;
@override final  bool hasMore;

/// Create a copy of NativeAddressBookPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeAddressBookPageCopyWith<_NativeAddressBookPage> get copyWith => __$NativeAddressBookPageCopyWithImpl<_NativeAddressBookPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeAddressBookPage&&const DeepCollectionEquality().equals(other._entries, _entries)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),total,hasMore);

@override
String toString() {
  return 'NativeAddressBookPage(entries: $entries, total: $total, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$NativeAddressBookPageCopyWith<$Res> implements $NativeAddressBookPageCopyWith<$Res> {
  factory _$NativeAddressBookPageCopyWith(_NativeAddressBookPage value, $Res Function(_NativeAddressBookPage) _then) = __$NativeAddressBookPageCopyWithImpl;
@override @useResult
$Res call({
 List<NativeAddressBookEntry> entries, int total, bool hasMore
});




}
/// @nodoc
class __$NativeAddressBookPageCopyWithImpl<$Res>
    implements _$NativeAddressBookPageCopyWith<$Res> {
  __$NativeAddressBookPageCopyWithImpl(this._self, this._then);

  final _NativeAddressBookPage _self;
  final $Res Function(_NativeAddressBookPage) _then;

/// Create a copy of NativeAddressBookPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? total = null,Object? hasMore = null,}) {
  return _then(_NativeAddressBookPage(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<NativeAddressBookEntry>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$NativeSavedDestination {

 String get address; String get baseAddress; NativeSavedDestinationKind get kind; NativeIntegratedDataKind? get integratedDataKind;
/// Create a copy of NativeSavedDestination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeSavedDestinationCopyWith<NativeSavedDestination> get copyWith => _$NativeSavedDestinationCopyWithImpl<NativeSavedDestination>(this as NativeSavedDestination, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeSavedDestination&&(identical(other.address, address) || other.address == address)&&(identical(other.baseAddress, baseAddress) || other.baseAddress == baseAddress)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.integratedDataKind, integratedDataKind) || other.integratedDataKind == integratedDataKind));
}


@override
int get hashCode => Object.hash(runtimeType,address,baseAddress,kind,integratedDataKind);

@override
String toString() {
  return 'NativeSavedDestination(address: $address, baseAddress: $baseAddress, kind: $kind, integratedDataKind: $integratedDataKind)';
}


}

/// @nodoc
abstract mixin class $NativeSavedDestinationCopyWith<$Res>  {
  factory $NativeSavedDestinationCopyWith(NativeSavedDestination value, $Res Function(NativeSavedDestination) _then) = _$NativeSavedDestinationCopyWithImpl;
@useResult
$Res call({
 String address, String baseAddress, NativeSavedDestinationKind kind, NativeIntegratedDataKind? integratedDataKind
});




}
/// @nodoc
class _$NativeSavedDestinationCopyWithImpl<$Res>
    implements $NativeSavedDestinationCopyWith<$Res> {
  _$NativeSavedDestinationCopyWithImpl(this._self, this._then);

  final NativeSavedDestination _self;
  final $Res Function(NativeSavedDestination) _then;

/// Create a copy of NativeSavedDestination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? address = null,Object? baseAddress = null,Object? kind = null,Object? integratedDataKind = freezed,}) {
  return _then(_self.copyWith(
address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,baseAddress: null == baseAddress ? _self.baseAddress : baseAddress // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NativeSavedDestinationKind,integratedDataKind: freezed == integratedDataKind ? _self.integratedDataKind : integratedDataKind // ignore: cast_nullable_to_non_nullable
as NativeIntegratedDataKind?,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeSavedDestination].
extension NativeSavedDestinationPatterns on NativeSavedDestination {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeSavedDestination value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeSavedDestination() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeSavedDestination value)  $default,){
final _that = this;
switch (_that) {
case _NativeSavedDestination():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeSavedDestination value)?  $default,){
final _that = this;
switch (_that) {
case _NativeSavedDestination() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String address,  String baseAddress,  NativeSavedDestinationKind kind,  NativeIntegratedDataKind? integratedDataKind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeSavedDestination() when $default != null:
return $default(_that.address,_that.baseAddress,_that.kind,_that.integratedDataKind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String address,  String baseAddress,  NativeSavedDestinationKind kind,  NativeIntegratedDataKind? integratedDataKind)  $default,) {final _that = this;
switch (_that) {
case _NativeSavedDestination():
return $default(_that.address,_that.baseAddress,_that.kind,_that.integratedDataKind);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String address,  String baseAddress,  NativeSavedDestinationKind kind,  NativeIntegratedDataKind? integratedDataKind)?  $default,) {final _that = this;
switch (_that) {
case _NativeSavedDestination() when $default != null:
return $default(_that.address,_that.baseAddress,_that.kind,_that.integratedDataKind);case _:
  return null;

}
}

}

/// @nodoc


class _NativeSavedDestination implements NativeSavedDestination {
  const _NativeSavedDestination({required this.address, required this.baseAddress, required this.kind, this.integratedDataKind});
  

@override final  String address;
@override final  String baseAddress;
@override final  NativeSavedDestinationKind kind;
@override final  NativeIntegratedDataKind? integratedDataKind;

/// Create a copy of NativeSavedDestination
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeSavedDestinationCopyWith<_NativeSavedDestination> get copyWith => __$NativeSavedDestinationCopyWithImpl<_NativeSavedDestination>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeSavedDestination&&(identical(other.address, address) || other.address == address)&&(identical(other.baseAddress, baseAddress) || other.baseAddress == baseAddress)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.integratedDataKind, integratedDataKind) || other.integratedDataKind == integratedDataKind));
}


@override
int get hashCode => Object.hash(runtimeType,address,baseAddress,kind,integratedDataKind);

@override
String toString() {
  return 'NativeSavedDestination(address: $address, baseAddress: $baseAddress, kind: $kind, integratedDataKind: $integratedDataKind)';
}


}

/// @nodoc
abstract mixin class _$NativeSavedDestinationCopyWith<$Res> implements $NativeSavedDestinationCopyWith<$Res> {
  factory _$NativeSavedDestinationCopyWith(_NativeSavedDestination value, $Res Function(_NativeSavedDestination) _then) = __$NativeSavedDestinationCopyWithImpl;
@override @useResult
$Res call({
 String address, String baseAddress, NativeSavedDestinationKind kind, NativeIntegratedDataKind? integratedDataKind
});




}
/// @nodoc
class __$NativeSavedDestinationCopyWithImpl<$Res>
    implements _$NativeSavedDestinationCopyWith<$Res> {
  __$NativeSavedDestinationCopyWithImpl(this._self, this._then);

  final _NativeSavedDestination _self;
  final $Res Function(_NativeSavedDestination) _then;

/// Create a copy of NativeSavedDestination
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? address = null,Object? baseAddress = null,Object? kind = null,Object? integratedDataKind = freezed,}) {
  return _then(_NativeSavedDestination(
address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,baseAddress: null == baseAddress ? _self.baseAddress : baseAddress // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NativeSavedDestinationKind,integratedDataKind: freezed == integratedDataKind ? _self.integratedDataKind : integratedDataKind // ignore: cast_nullable_to_non_nullable
as NativeIntegratedDataKind?,
  ));
}


}

// dart format on
