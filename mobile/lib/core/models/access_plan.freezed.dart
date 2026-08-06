// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'access_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccessPlan {

 String get id; String get name; AccessPlanType get planType; double get price; int get validityValue; String get validityUnit; int? get visitLimit; String? get description; int get includedItemCount;
/// Create a copy of AccessPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessPlanCopyWith<AccessPlan> get copyWith => _$AccessPlanCopyWithImpl<AccessPlan>(this as AccessPlan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.planType, planType) || other.planType == planType)&&(identical(other.price, price) || other.price == price)&&(identical(other.validityValue, validityValue) || other.validityValue == validityValue)&&(identical(other.validityUnit, validityUnit) || other.validityUnit == validityUnit)&&(identical(other.visitLimit, visitLimit) || other.visitLimit == visitLimit)&&(identical(other.description, description) || other.description == description)&&(identical(other.includedItemCount, includedItemCount) || other.includedItemCount == includedItemCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,planType,price,validityValue,validityUnit,visitLimit,description,includedItemCount);

@override
String toString() {
  return 'AccessPlan(id: $id, name: $name, planType: $planType, price: $price, validityValue: $validityValue, validityUnit: $validityUnit, visitLimit: $visitLimit, description: $description, includedItemCount: $includedItemCount)';
}


}

/// @nodoc
abstract mixin class $AccessPlanCopyWith<$Res>  {
  factory $AccessPlanCopyWith(AccessPlan value, $Res Function(AccessPlan) _then) = _$AccessPlanCopyWithImpl;
@useResult
$Res call({
 String id, String name, AccessPlanType planType, double price, int validityValue, String validityUnit, int? visitLimit, String? description, int includedItemCount
});




}
/// @nodoc
class _$AccessPlanCopyWithImpl<$Res>
    implements $AccessPlanCopyWith<$Res> {
  _$AccessPlanCopyWithImpl(this._self, this._then);

  final AccessPlan _self;
  final $Res Function(AccessPlan) _then;

/// Create a copy of AccessPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? planType = null,Object? price = null,Object? validityValue = null,Object? validityUnit = null,Object? visitLimit = freezed,Object? description = freezed,Object? includedItemCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,planType: null == planType ? _self.planType : planType // ignore: cast_nullable_to_non_nullable
as AccessPlanType,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,validityValue: null == validityValue ? _self.validityValue : validityValue // ignore: cast_nullable_to_non_nullable
as int,validityUnit: null == validityUnit ? _self.validityUnit : validityUnit // ignore: cast_nullable_to_non_nullable
as String,visitLimit: freezed == visitLimit ? _self.visitLimit : visitLimit // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,includedItemCount: null == includedItemCount ? _self.includedItemCount : includedItemCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AccessPlan].
extension AccessPlanPatterns on AccessPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessPlan value)  $default,){
final _that = this;
switch (_that) {
case _AccessPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessPlan value)?  $default,){
final _that = this;
switch (_that) {
case _AccessPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  AccessPlanType planType,  double price,  int validityValue,  String validityUnit,  int? visitLimit,  String? description,  int includedItemCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessPlan() when $default != null:
return $default(_that.id,_that.name,_that.planType,_that.price,_that.validityValue,_that.validityUnit,_that.visitLimit,_that.description,_that.includedItemCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  AccessPlanType planType,  double price,  int validityValue,  String validityUnit,  int? visitLimit,  String? description,  int includedItemCount)  $default,) {final _that = this;
switch (_that) {
case _AccessPlan():
return $default(_that.id,_that.name,_that.planType,_that.price,_that.validityValue,_that.validityUnit,_that.visitLimit,_that.description,_that.includedItemCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  AccessPlanType planType,  double price,  int validityValue,  String validityUnit,  int? visitLimit,  String? description,  int includedItemCount)?  $default,) {final _that = this;
switch (_that) {
case _AccessPlan() when $default != null:
return $default(_that.id,_that.name,_that.planType,_that.price,_that.validityValue,_that.validityUnit,_that.visitLimit,_that.description,_that.includedItemCount);case _:
  return null;

}
}

}

/// @nodoc


class _AccessPlan implements AccessPlan {
  const _AccessPlan({required this.id, required this.name, required this.planType, required this.price, required this.validityValue, required this.validityUnit, this.visitLimit, this.description, required this.includedItemCount});
  

@override final  String id;
@override final  String name;
@override final  AccessPlanType planType;
@override final  double price;
@override final  int validityValue;
@override final  String validityUnit;
@override final  int? visitLimit;
@override final  String? description;
@override final  int includedItemCount;

/// Create a copy of AccessPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessPlanCopyWith<_AccessPlan> get copyWith => __$AccessPlanCopyWithImpl<_AccessPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.planType, planType) || other.planType == planType)&&(identical(other.price, price) || other.price == price)&&(identical(other.validityValue, validityValue) || other.validityValue == validityValue)&&(identical(other.validityUnit, validityUnit) || other.validityUnit == validityUnit)&&(identical(other.visitLimit, visitLimit) || other.visitLimit == visitLimit)&&(identical(other.description, description) || other.description == description)&&(identical(other.includedItemCount, includedItemCount) || other.includedItemCount == includedItemCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,planType,price,validityValue,validityUnit,visitLimit,description,includedItemCount);

@override
String toString() {
  return 'AccessPlan(id: $id, name: $name, planType: $planType, price: $price, validityValue: $validityValue, validityUnit: $validityUnit, visitLimit: $visitLimit, description: $description, includedItemCount: $includedItemCount)';
}


}

/// @nodoc
abstract mixin class _$AccessPlanCopyWith<$Res> implements $AccessPlanCopyWith<$Res> {
  factory _$AccessPlanCopyWith(_AccessPlan value, $Res Function(_AccessPlan) _then) = __$AccessPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, AccessPlanType planType, double price, int validityValue, String validityUnit, int? visitLimit, String? description, int includedItemCount
});




}
/// @nodoc
class __$AccessPlanCopyWithImpl<$Res>
    implements _$AccessPlanCopyWith<$Res> {
  __$AccessPlanCopyWithImpl(this._self, this._then);

  final _AccessPlan _self;
  final $Res Function(_AccessPlan) _then;

/// Create a copy of AccessPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? planType = null,Object? price = null,Object? validityValue = null,Object? validityUnit = null,Object? visitLimit = freezed,Object? description = freezed,Object? includedItemCount = null,}) {
  return _then(_AccessPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,planType: null == planType ? _self.planType : planType // ignore: cast_nullable_to_non_nullable
as AccessPlanType,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,validityValue: null == validityValue ? _self.validityValue : validityValue // ignore: cast_nullable_to_non_nullable
as int,validityUnit: null == validityUnit ? _self.validityUnit : validityUnit // ignore: cast_nullable_to_non_nullable
as String,visitLimit: freezed == visitLimit ? _self.visitLimit : visitLimit // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,includedItemCount: null == includedItemCount ? _self.includedItemCount : includedItemCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
