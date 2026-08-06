// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VenueSettings {

 String get parkName; String? get logoUrl;
/// Create a copy of VenueSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueSettingsCopyWith<VenueSettings> get copyWith => _$VenueSettingsCopyWithImpl<VenueSettings>(this as VenueSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueSettings&&(identical(other.parkName, parkName) || other.parkName == parkName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,parkName,logoUrl);

@override
String toString() {
  return 'VenueSettings(parkName: $parkName, logoUrl: $logoUrl)';
}


}

/// @nodoc
abstract mixin class $VenueSettingsCopyWith<$Res>  {
  factory $VenueSettingsCopyWith(VenueSettings value, $Res Function(VenueSettings) _then) = _$VenueSettingsCopyWithImpl;
@useResult
$Res call({
 String parkName, String? logoUrl
});




}
/// @nodoc
class _$VenueSettingsCopyWithImpl<$Res>
    implements $VenueSettingsCopyWith<$Res> {
  _$VenueSettingsCopyWithImpl(this._self, this._then);

  final VenueSettings _self;
  final $Res Function(VenueSettings) _then;

/// Create a copy of VenueSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? parkName = null,Object? logoUrl = freezed,}) {
  return _then(_self.copyWith(
parkName: null == parkName ? _self.parkName : parkName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueSettings].
extension VenueSettingsPatterns on VenueSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueSettings value)  $default,){
final _that = this;
switch (_that) {
case _VenueSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueSettings value)?  $default,){
final _that = this;
switch (_that) {
case _VenueSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String parkName,  String? logoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueSettings() when $default != null:
return $default(_that.parkName,_that.logoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String parkName,  String? logoUrl)  $default,) {final _that = this;
switch (_that) {
case _VenueSettings():
return $default(_that.parkName,_that.logoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String parkName,  String? logoUrl)?  $default,) {final _that = this;
switch (_that) {
case _VenueSettings() when $default != null:
return $default(_that.parkName,_that.logoUrl);case _:
  return null;

}
}

}

/// @nodoc


class _VenueSettings implements VenueSettings {
  const _VenueSettings({required this.parkName, this.logoUrl});
  

@override final  String parkName;
@override final  String? logoUrl;

/// Create a copy of VenueSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueSettingsCopyWith<_VenueSettings> get copyWith => __$VenueSettingsCopyWithImpl<_VenueSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueSettings&&(identical(other.parkName, parkName) || other.parkName == parkName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,parkName,logoUrl);

@override
String toString() {
  return 'VenueSettings(parkName: $parkName, logoUrl: $logoUrl)';
}


}

/// @nodoc
abstract mixin class _$VenueSettingsCopyWith<$Res> implements $VenueSettingsCopyWith<$Res> {
  factory _$VenueSettingsCopyWith(_VenueSettings value, $Res Function(_VenueSettings) _then) = __$VenueSettingsCopyWithImpl;
@override @useResult
$Res call({
 String parkName, String? logoUrl
});




}
/// @nodoc
class __$VenueSettingsCopyWithImpl<$Res>
    implements _$VenueSettingsCopyWith<$Res> {
  __$VenueSettingsCopyWithImpl(this._self, this._then);

  final _VenueSettings _self;
  final $Res Function(_VenueSettings) _then;

/// Create a copy of VenueSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? parkName = null,Object? logoUrl = freezed,}) {
  return _then(_VenueSettings(
parkName: null == parkName ? _self.parkName : parkName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
