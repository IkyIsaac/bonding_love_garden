// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wristband_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WristbandSummary {

 String get id; String get wristbandNumber; String get qrCodeValue; String get liveStatus; DateTime get expiresAt; DateTime? get lastScannedAt; String get beneficiaryName; bool get isAccountOwner;
/// Create a copy of WristbandSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WristbandSummaryCopyWith<WristbandSummary> get copyWith => _$WristbandSummaryCopyWithImpl<WristbandSummary>(this as WristbandSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WristbandSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.wristbandNumber, wristbandNumber) || other.wristbandNumber == wristbandNumber)&&(identical(other.qrCodeValue, qrCodeValue) || other.qrCodeValue == qrCodeValue)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastScannedAt, lastScannedAt) || other.lastScannedAt == lastScannedAt)&&(identical(other.beneficiaryName, beneficiaryName) || other.beneficiaryName == beneficiaryName)&&(identical(other.isAccountOwner, isAccountOwner) || other.isAccountOwner == isAccountOwner));
}


@override
int get hashCode => Object.hash(runtimeType,id,wristbandNumber,qrCodeValue,liveStatus,expiresAt,lastScannedAt,beneficiaryName,isAccountOwner);

@override
String toString() {
  return 'WristbandSummary(id: $id, wristbandNumber: $wristbandNumber, qrCodeValue: $qrCodeValue, liveStatus: $liveStatus, expiresAt: $expiresAt, lastScannedAt: $lastScannedAt, beneficiaryName: $beneficiaryName, isAccountOwner: $isAccountOwner)';
}


}

/// @nodoc
abstract mixin class $WristbandSummaryCopyWith<$Res>  {
  factory $WristbandSummaryCopyWith(WristbandSummary value, $Res Function(WristbandSummary) _then) = _$WristbandSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String wristbandNumber, String qrCodeValue, String liveStatus, DateTime expiresAt, DateTime? lastScannedAt, String beneficiaryName, bool isAccountOwner
});




}
/// @nodoc
class _$WristbandSummaryCopyWithImpl<$Res>
    implements $WristbandSummaryCopyWith<$Res> {
  _$WristbandSummaryCopyWithImpl(this._self, this._then);

  final WristbandSummary _self;
  final $Res Function(WristbandSummary) _then;

/// Create a copy of WristbandSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? wristbandNumber = null,Object? qrCodeValue = null,Object? liveStatus = null,Object? expiresAt = null,Object? lastScannedAt = freezed,Object? beneficiaryName = null,Object? isAccountOwner = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,wristbandNumber: null == wristbandNumber ? _self.wristbandNumber : wristbandNumber // ignore: cast_nullable_to_non_nullable
as String,qrCodeValue: null == qrCodeValue ? _self.qrCodeValue : qrCodeValue // ignore: cast_nullable_to_non_nullable
as String,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastScannedAt: freezed == lastScannedAt ? _self.lastScannedAt : lastScannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,beneficiaryName: null == beneficiaryName ? _self.beneficiaryName : beneficiaryName // ignore: cast_nullable_to_non_nullable
as String,isAccountOwner: null == isAccountOwner ? _self.isAccountOwner : isAccountOwner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WristbandSummary].
extension WristbandSummaryPatterns on WristbandSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WristbandSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WristbandSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WristbandSummary value)  $default,){
final _that = this;
switch (_that) {
case _WristbandSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WristbandSummary value)?  $default,){
final _that = this;
switch (_that) {
case _WristbandSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String wristbandNumber,  String qrCodeValue,  String liveStatus,  DateTime expiresAt,  DateTime? lastScannedAt,  String beneficiaryName,  bool isAccountOwner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WristbandSummary() when $default != null:
return $default(_that.id,_that.wristbandNumber,_that.qrCodeValue,_that.liveStatus,_that.expiresAt,_that.lastScannedAt,_that.beneficiaryName,_that.isAccountOwner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String wristbandNumber,  String qrCodeValue,  String liveStatus,  DateTime expiresAt,  DateTime? lastScannedAt,  String beneficiaryName,  bool isAccountOwner)  $default,) {final _that = this;
switch (_that) {
case _WristbandSummary():
return $default(_that.id,_that.wristbandNumber,_that.qrCodeValue,_that.liveStatus,_that.expiresAt,_that.lastScannedAt,_that.beneficiaryName,_that.isAccountOwner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String wristbandNumber,  String qrCodeValue,  String liveStatus,  DateTime expiresAt,  DateTime? lastScannedAt,  String beneficiaryName,  bool isAccountOwner)?  $default,) {final _that = this;
switch (_that) {
case _WristbandSummary() when $default != null:
return $default(_that.id,_that.wristbandNumber,_that.qrCodeValue,_that.liveStatus,_that.expiresAt,_that.lastScannedAt,_that.beneficiaryName,_that.isAccountOwner);case _:
  return null;

}
}

}

/// @nodoc


class _WristbandSummary implements WristbandSummary {
  const _WristbandSummary({required this.id, required this.wristbandNumber, required this.qrCodeValue, required this.liveStatus, required this.expiresAt, this.lastScannedAt, required this.beneficiaryName, required this.isAccountOwner});
  

@override final  String id;
@override final  String wristbandNumber;
@override final  String qrCodeValue;
@override final  String liveStatus;
@override final  DateTime expiresAt;
@override final  DateTime? lastScannedAt;
@override final  String beneficiaryName;
@override final  bool isAccountOwner;

/// Create a copy of WristbandSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WristbandSummaryCopyWith<_WristbandSummary> get copyWith => __$WristbandSummaryCopyWithImpl<_WristbandSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WristbandSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.wristbandNumber, wristbandNumber) || other.wristbandNumber == wristbandNumber)&&(identical(other.qrCodeValue, qrCodeValue) || other.qrCodeValue == qrCodeValue)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastScannedAt, lastScannedAt) || other.lastScannedAt == lastScannedAt)&&(identical(other.beneficiaryName, beneficiaryName) || other.beneficiaryName == beneficiaryName)&&(identical(other.isAccountOwner, isAccountOwner) || other.isAccountOwner == isAccountOwner));
}


@override
int get hashCode => Object.hash(runtimeType,id,wristbandNumber,qrCodeValue,liveStatus,expiresAt,lastScannedAt,beneficiaryName,isAccountOwner);

@override
String toString() {
  return 'WristbandSummary(id: $id, wristbandNumber: $wristbandNumber, qrCodeValue: $qrCodeValue, liveStatus: $liveStatus, expiresAt: $expiresAt, lastScannedAt: $lastScannedAt, beneficiaryName: $beneficiaryName, isAccountOwner: $isAccountOwner)';
}


}

/// @nodoc
abstract mixin class _$WristbandSummaryCopyWith<$Res> implements $WristbandSummaryCopyWith<$Res> {
  factory _$WristbandSummaryCopyWith(_WristbandSummary value, $Res Function(_WristbandSummary) _then) = __$WristbandSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String wristbandNumber, String qrCodeValue, String liveStatus, DateTime expiresAt, DateTime? lastScannedAt, String beneficiaryName, bool isAccountOwner
});




}
/// @nodoc
class __$WristbandSummaryCopyWithImpl<$Res>
    implements _$WristbandSummaryCopyWith<$Res> {
  __$WristbandSummaryCopyWithImpl(this._self, this._then);

  final _WristbandSummary _self;
  final $Res Function(_WristbandSummary) _then;

/// Create a copy of WristbandSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? wristbandNumber = null,Object? qrCodeValue = null,Object? liveStatus = null,Object? expiresAt = null,Object? lastScannedAt = freezed,Object? beneficiaryName = null,Object? isAccountOwner = null,}) {
  return _then(_WristbandSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,wristbandNumber: null == wristbandNumber ? _self.wristbandNumber : wristbandNumber // ignore: cast_nullable_to_non_nullable
as String,qrCodeValue: null == qrCodeValue ? _self.qrCodeValue : qrCodeValue // ignore: cast_nullable_to_non_nullable
as String,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastScannedAt: freezed == lastScannedAt ? _self.lastScannedAt : lastScannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,beneficiaryName: null == beneficiaryName ? _self.beneficiaryName : beneficiaryName // ignore: cast_nullable_to_non_nullable
as String,isAccountOwner: null == isAccountOwner ? _self.isAccountOwner : isAccountOwner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
