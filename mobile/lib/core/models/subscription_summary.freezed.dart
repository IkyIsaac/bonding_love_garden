// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubscriptionSummary {

 String get id; String get accessPlanId; String get planName; String get status; DateTime get startsAt; DateTime get endsAt; int? get visitsRemaining;
/// Create a copy of SubscriptionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionSummaryCopyWith<SubscriptionSummary> get copyWith => _$SubscriptionSummaryCopyWithImpl<SubscriptionSummary>(this as SubscriptionSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.accessPlanId, accessPlanId) || other.accessPlanId == accessPlanId)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.status, status) || other.status == status)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.visitsRemaining, visitsRemaining) || other.visitsRemaining == visitsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,id,accessPlanId,planName,status,startsAt,endsAt,visitsRemaining);

@override
String toString() {
  return 'SubscriptionSummary(id: $id, accessPlanId: $accessPlanId, planName: $planName, status: $status, startsAt: $startsAt, endsAt: $endsAt, visitsRemaining: $visitsRemaining)';
}


}

/// @nodoc
abstract mixin class $SubscriptionSummaryCopyWith<$Res>  {
  factory $SubscriptionSummaryCopyWith(SubscriptionSummary value, $Res Function(SubscriptionSummary) _then) = _$SubscriptionSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String accessPlanId, String planName, String status, DateTime startsAt, DateTime endsAt, int? visitsRemaining
});




}
/// @nodoc
class _$SubscriptionSummaryCopyWithImpl<$Res>
    implements $SubscriptionSummaryCopyWith<$Res> {
  _$SubscriptionSummaryCopyWithImpl(this._self, this._then);

  final SubscriptionSummary _self;
  final $Res Function(SubscriptionSummary) _then;

/// Create a copy of SubscriptionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accessPlanId = null,Object? planName = null,Object? status = null,Object? startsAt = null,Object? endsAt = null,Object? visitsRemaining = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accessPlanId: null == accessPlanId ? _self.accessPlanId : accessPlanId // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,visitsRemaining: freezed == visitsRemaining ? _self.visitsRemaining : visitsRemaining // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionSummary].
extension SubscriptionSummaryPatterns on SubscriptionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionSummary value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accessPlanId,  String planName,  String status,  DateTime startsAt,  DateTime endsAt,  int? visitsRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionSummary() when $default != null:
return $default(_that.id,_that.accessPlanId,_that.planName,_that.status,_that.startsAt,_that.endsAt,_that.visitsRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accessPlanId,  String planName,  String status,  DateTime startsAt,  DateTime endsAt,  int? visitsRemaining)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionSummary():
return $default(_that.id,_that.accessPlanId,_that.planName,_that.status,_that.startsAt,_that.endsAt,_that.visitsRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accessPlanId,  String planName,  String status,  DateTime startsAt,  DateTime endsAt,  int? visitsRemaining)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionSummary() when $default != null:
return $default(_that.id,_that.accessPlanId,_that.planName,_that.status,_that.startsAt,_that.endsAt,_that.visitsRemaining);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionSummary implements SubscriptionSummary {
  const _SubscriptionSummary({required this.id, required this.accessPlanId, required this.planName, required this.status, required this.startsAt, required this.endsAt, this.visitsRemaining});
  

@override final  String id;
@override final  String accessPlanId;
@override final  String planName;
@override final  String status;
@override final  DateTime startsAt;
@override final  DateTime endsAt;
@override final  int? visitsRemaining;

/// Create a copy of SubscriptionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionSummaryCopyWith<_SubscriptionSummary> get copyWith => __$SubscriptionSummaryCopyWithImpl<_SubscriptionSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.accessPlanId, accessPlanId) || other.accessPlanId == accessPlanId)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.status, status) || other.status == status)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.visitsRemaining, visitsRemaining) || other.visitsRemaining == visitsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,id,accessPlanId,planName,status,startsAt,endsAt,visitsRemaining);

@override
String toString() {
  return 'SubscriptionSummary(id: $id, accessPlanId: $accessPlanId, planName: $planName, status: $status, startsAt: $startsAt, endsAt: $endsAt, visitsRemaining: $visitsRemaining)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionSummaryCopyWith<$Res> implements $SubscriptionSummaryCopyWith<$Res> {
  factory _$SubscriptionSummaryCopyWith(_SubscriptionSummary value, $Res Function(_SubscriptionSummary) _then) = __$SubscriptionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String accessPlanId, String planName, String status, DateTime startsAt, DateTime endsAt, int? visitsRemaining
});




}
/// @nodoc
class __$SubscriptionSummaryCopyWithImpl<$Res>
    implements _$SubscriptionSummaryCopyWith<$Res> {
  __$SubscriptionSummaryCopyWithImpl(this._self, this._then);

  final _SubscriptionSummary _self;
  final $Res Function(_SubscriptionSummary) _then;

/// Create a copy of SubscriptionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accessPlanId = null,Object? planName = null,Object? status = null,Object? startsAt = null,Object? endsAt = null,Object? visitsRemaining = freezed,}) {
  return _then(_SubscriptionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accessPlanId: null == accessPlanId ? _self.accessPlanId : accessPlanId // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,visitsRemaining: freezed == visitsRemaining ? _self.visitsRemaining : visitsRemaining // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
