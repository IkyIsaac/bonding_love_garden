// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionSummary {

 String get id; String get wristbandId; String get beneficiaryName; String? get catalogItemName; DateTime get startedAt; DateTime get plannedEndAt; String get status; int get extendedMinutesTotal;
/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSummaryCopyWith<SessionSummary> get copyWith => _$SessionSummaryCopyWithImpl<SessionSummary>(this as SessionSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.wristbandId, wristbandId) || other.wristbandId == wristbandId)&&(identical(other.beneficiaryName, beneficiaryName) || other.beneficiaryName == beneficiaryName)&&(identical(other.catalogItemName, catalogItemName) || other.catalogItemName == catalogItemName)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.plannedEndAt, plannedEndAt) || other.plannedEndAt == plannedEndAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.extendedMinutesTotal, extendedMinutesTotal) || other.extendedMinutesTotal == extendedMinutesTotal));
}


@override
int get hashCode => Object.hash(runtimeType,id,wristbandId,beneficiaryName,catalogItemName,startedAt,plannedEndAt,status,extendedMinutesTotal);

@override
String toString() {
  return 'SessionSummary(id: $id, wristbandId: $wristbandId, beneficiaryName: $beneficiaryName, catalogItemName: $catalogItemName, startedAt: $startedAt, plannedEndAt: $plannedEndAt, status: $status, extendedMinutesTotal: $extendedMinutesTotal)';
}


}

/// @nodoc
abstract mixin class $SessionSummaryCopyWith<$Res>  {
  factory $SessionSummaryCopyWith(SessionSummary value, $Res Function(SessionSummary) _then) = _$SessionSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String wristbandId, String beneficiaryName, String? catalogItemName, DateTime startedAt, DateTime plannedEndAt, String status, int extendedMinutesTotal
});




}
/// @nodoc
class _$SessionSummaryCopyWithImpl<$Res>
    implements $SessionSummaryCopyWith<$Res> {
  _$SessionSummaryCopyWithImpl(this._self, this._then);

  final SessionSummary _self;
  final $Res Function(SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? wristbandId = null,Object? beneficiaryName = null,Object? catalogItemName = freezed,Object? startedAt = null,Object? plannedEndAt = null,Object? status = null,Object? extendedMinutesTotal = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,wristbandId: null == wristbandId ? _self.wristbandId : wristbandId // ignore: cast_nullable_to_non_nullable
as String,beneficiaryName: null == beneficiaryName ? _self.beneficiaryName : beneficiaryName // ignore: cast_nullable_to_non_nullable
as String,catalogItemName: freezed == catalogItemName ? _self.catalogItemName : catalogItemName // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,plannedEndAt: null == plannedEndAt ? _self.plannedEndAt : plannedEndAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,extendedMinutesTotal: null == extendedMinutesTotal ? _self.extendedMinutesTotal : extendedMinutesTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionSummary].
extension SessionSummaryPatterns on SessionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSummary value)  $default,){
final _that = this;
switch (_that) {
case _SessionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String wristbandId,  String beneficiaryName,  String? catalogItemName,  DateTime startedAt,  DateTime plannedEndAt,  String status,  int extendedMinutesTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.id,_that.wristbandId,_that.beneficiaryName,_that.catalogItemName,_that.startedAt,_that.plannedEndAt,_that.status,_that.extendedMinutesTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String wristbandId,  String beneficiaryName,  String? catalogItemName,  DateTime startedAt,  DateTime plannedEndAt,  String status,  int extendedMinutesTotal)  $default,) {final _that = this;
switch (_that) {
case _SessionSummary():
return $default(_that.id,_that.wristbandId,_that.beneficiaryName,_that.catalogItemName,_that.startedAt,_that.plannedEndAt,_that.status,_that.extendedMinutesTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String wristbandId,  String beneficiaryName,  String? catalogItemName,  DateTime startedAt,  DateTime plannedEndAt,  String status,  int extendedMinutesTotal)?  $default,) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.id,_that.wristbandId,_that.beneficiaryName,_that.catalogItemName,_that.startedAt,_that.plannedEndAt,_that.status,_that.extendedMinutesTotal);case _:
  return null;

}
}

}

/// @nodoc


class _SessionSummary implements SessionSummary {
  const _SessionSummary({required this.id, required this.wristbandId, required this.beneficiaryName, this.catalogItemName, required this.startedAt, required this.plannedEndAt, required this.status, required this.extendedMinutesTotal});
  

@override final  String id;
@override final  String wristbandId;
@override final  String beneficiaryName;
@override final  String? catalogItemName;
@override final  DateTime startedAt;
@override final  DateTime plannedEndAt;
@override final  String status;
@override final  int extendedMinutesTotal;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSummaryCopyWith<_SessionSummary> get copyWith => __$SessionSummaryCopyWithImpl<_SessionSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.wristbandId, wristbandId) || other.wristbandId == wristbandId)&&(identical(other.beneficiaryName, beneficiaryName) || other.beneficiaryName == beneficiaryName)&&(identical(other.catalogItemName, catalogItemName) || other.catalogItemName == catalogItemName)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.plannedEndAt, plannedEndAt) || other.plannedEndAt == plannedEndAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.extendedMinutesTotal, extendedMinutesTotal) || other.extendedMinutesTotal == extendedMinutesTotal));
}


@override
int get hashCode => Object.hash(runtimeType,id,wristbandId,beneficiaryName,catalogItemName,startedAt,plannedEndAt,status,extendedMinutesTotal);

@override
String toString() {
  return 'SessionSummary(id: $id, wristbandId: $wristbandId, beneficiaryName: $beneficiaryName, catalogItemName: $catalogItemName, startedAt: $startedAt, plannedEndAt: $plannedEndAt, status: $status, extendedMinutesTotal: $extendedMinutesTotal)';
}


}

/// @nodoc
abstract mixin class _$SessionSummaryCopyWith<$Res> implements $SessionSummaryCopyWith<$Res> {
  factory _$SessionSummaryCopyWith(_SessionSummary value, $Res Function(_SessionSummary) _then) = __$SessionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String wristbandId, String beneficiaryName, String? catalogItemName, DateTime startedAt, DateTime plannedEndAt, String status, int extendedMinutesTotal
});




}
/// @nodoc
class __$SessionSummaryCopyWithImpl<$Res>
    implements _$SessionSummaryCopyWith<$Res> {
  __$SessionSummaryCopyWithImpl(this._self, this._then);

  final _SessionSummary _self;
  final $Res Function(_SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? wristbandId = null,Object? beneficiaryName = null,Object? catalogItemName = freezed,Object? startedAt = null,Object? plannedEndAt = null,Object? status = null,Object? extendedMinutesTotal = null,}) {
  return _then(_SessionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,wristbandId: null == wristbandId ? _self.wristbandId : wristbandId // ignore: cast_nullable_to_non_nullable
as String,beneficiaryName: null == beneficiaryName ? _self.beneficiaryName : beneficiaryName // ignore: cast_nullable_to_non_nullable
as String,catalogItemName: freezed == catalogItemName ? _self.catalogItemName : catalogItemName // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,plannedEndAt: null == plannedEndAt ? _self.plannedEndAt : plannedEndAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,extendedMinutesTotal: null == extendedMinutesTotal ? _self.extendedMinutesTotal : extendedMinutesTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
