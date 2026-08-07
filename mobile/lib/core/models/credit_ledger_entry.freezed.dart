// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_ledger_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreditLedgerEntry {

 String get id; CreditDirection get direction; int get amount; String? get reason; DateTime get createdAt;
/// Create a copy of CreditLedgerEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditLedgerEntryCopyWith<CreditLedgerEntry> get copyWith => _$CreditLedgerEntryCopyWithImpl<CreditLedgerEntry>(this as CreditLedgerEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditLedgerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,direction,amount,reason,createdAt);

@override
String toString() {
  return 'CreditLedgerEntry(id: $id, direction: $direction, amount: $amount, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CreditLedgerEntryCopyWith<$Res>  {
  factory $CreditLedgerEntryCopyWith(CreditLedgerEntry value, $Res Function(CreditLedgerEntry) _then) = _$CreditLedgerEntryCopyWithImpl;
@useResult
$Res call({
 String id, CreditDirection direction, int amount, String? reason, DateTime createdAt
});




}
/// @nodoc
class _$CreditLedgerEntryCopyWithImpl<$Res>
    implements $CreditLedgerEntryCopyWith<$Res> {
  _$CreditLedgerEntryCopyWithImpl(this._self, this._then);

  final CreditLedgerEntry _self;
  final $Res Function(CreditLedgerEntry) _then;

/// Create a copy of CreditLedgerEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? direction = null,Object? amount = null,Object? reason = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CreditDirection,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CreditLedgerEntry].
extension CreditLedgerEntryPatterns on CreditLedgerEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditLedgerEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditLedgerEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditLedgerEntry value)  $default,){
final _that = this;
switch (_that) {
case _CreditLedgerEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditLedgerEntry value)?  $default,){
final _that = this;
switch (_that) {
case _CreditLedgerEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CreditDirection direction,  int amount,  String? reason,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditLedgerEntry() when $default != null:
return $default(_that.id,_that.direction,_that.amount,_that.reason,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CreditDirection direction,  int amount,  String? reason,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CreditLedgerEntry():
return $default(_that.id,_that.direction,_that.amount,_that.reason,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CreditDirection direction,  int amount,  String? reason,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CreditLedgerEntry() when $default != null:
return $default(_that.id,_that.direction,_that.amount,_that.reason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _CreditLedgerEntry implements CreditLedgerEntry {
  const _CreditLedgerEntry({required this.id, required this.direction, required this.amount, this.reason, required this.createdAt});
  

@override final  String id;
@override final  CreditDirection direction;
@override final  int amount;
@override final  String? reason;
@override final  DateTime createdAt;

/// Create a copy of CreditLedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditLedgerEntryCopyWith<_CreditLedgerEntry> get copyWith => __$CreditLedgerEntryCopyWithImpl<_CreditLedgerEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditLedgerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,direction,amount,reason,createdAt);

@override
String toString() {
  return 'CreditLedgerEntry(id: $id, direction: $direction, amount: $amount, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CreditLedgerEntryCopyWith<$Res> implements $CreditLedgerEntryCopyWith<$Res> {
  factory _$CreditLedgerEntryCopyWith(_CreditLedgerEntry value, $Res Function(_CreditLedgerEntry) _then) = __$CreditLedgerEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, CreditDirection direction, int amount, String? reason, DateTime createdAt
});




}
/// @nodoc
class __$CreditLedgerEntryCopyWithImpl<$Res>
    implements _$CreditLedgerEntryCopyWith<$Res> {
  __$CreditLedgerEntryCopyWithImpl(this._self, this._then);

  final _CreditLedgerEntry _self;
  final $Res Function(_CreditLedgerEntry) _then;

/// Create a copy of CreditLedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? direction = null,Object? amount = null,Object? reason = freezed,Object? createdAt = null,}) {
  return _then(_CreditLedgerEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CreditDirection,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
