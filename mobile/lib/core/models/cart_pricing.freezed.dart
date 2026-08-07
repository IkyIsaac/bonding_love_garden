// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_pricing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CartPricing {

 double get subtotal; double get discountTotal; double get entryFeeTotal; double get totalAmount;
/// Create a copy of CartPricing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartPricingCopyWith<CartPricing> get copyWith => _$CartPricingCopyWithImpl<CartPricing>(this as CartPricing, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartPricing&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountTotal, discountTotal) || other.discountTotal == discountTotal)&&(identical(other.entryFeeTotal, entryFeeTotal) || other.entryFeeTotal == entryFeeTotal)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}


@override
int get hashCode => Object.hash(runtimeType,subtotal,discountTotal,entryFeeTotal,totalAmount);

@override
String toString() {
  return 'CartPricing(subtotal: $subtotal, discountTotal: $discountTotal, entryFeeTotal: $entryFeeTotal, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $CartPricingCopyWith<$Res>  {
  factory $CartPricingCopyWith(CartPricing value, $Res Function(CartPricing) _then) = _$CartPricingCopyWithImpl;
@useResult
$Res call({
 double subtotal, double discountTotal, double entryFeeTotal, double totalAmount
});




}
/// @nodoc
class _$CartPricingCopyWithImpl<$Res>
    implements $CartPricingCopyWith<$Res> {
  _$CartPricingCopyWithImpl(this._self, this._then);

  final CartPricing _self;
  final $Res Function(CartPricing) _then;

/// Create a copy of CartPricing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotal = null,Object? discountTotal = null,Object? entryFeeTotal = null,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,discountTotal: null == discountTotal ? _self.discountTotal : discountTotal // ignore: cast_nullable_to_non_nullable
as double,entryFeeTotal: null == entryFeeTotal ? _self.entryFeeTotal : entryFeeTotal // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CartPricing].
extension CartPricingPatterns on CartPricing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartPricing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartPricing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartPricing value)  $default,){
final _that = this;
switch (_that) {
case _CartPricing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartPricing value)?  $default,){
final _that = this;
switch (_that) {
case _CartPricing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double subtotal,  double discountTotal,  double entryFeeTotal,  double totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartPricing() when $default != null:
return $default(_that.subtotal,_that.discountTotal,_that.entryFeeTotal,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double subtotal,  double discountTotal,  double entryFeeTotal,  double totalAmount)  $default,) {final _that = this;
switch (_that) {
case _CartPricing():
return $default(_that.subtotal,_that.discountTotal,_that.entryFeeTotal,_that.totalAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double subtotal,  double discountTotal,  double entryFeeTotal,  double totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _CartPricing() when $default != null:
return $default(_that.subtotal,_that.discountTotal,_that.entryFeeTotal,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc


class _CartPricing implements CartPricing {
  const _CartPricing({required this.subtotal, required this.discountTotal, required this.entryFeeTotal, required this.totalAmount});
  

@override final  double subtotal;
@override final  double discountTotal;
@override final  double entryFeeTotal;
@override final  double totalAmount;

/// Create a copy of CartPricing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartPricingCopyWith<_CartPricing> get copyWith => __$CartPricingCopyWithImpl<_CartPricing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartPricing&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountTotal, discountTotal) || other.discountTotal == discountTotal)&&(identical(other.entryFeeTotal, entryFeeTotal) || other.entryFeeTotal == entryFeeTotal)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}


@override
int get hashCode => Object.hash(runtimeType,subtotal,discountTotal,entryFeeTotal,totalAmount);

@override
String toString() {
  return 'CartPricing(subtotal: $subtotal, discountTotal: $discountTotal, entryFeeTotal: $entryFeeTotal, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$CartPricingCopyWith<$Res> implements $CartPricingCopyWith<$Res> {
  factory _$CartPricingCopyWith(_CartPricing value, $Res Function(_CartPricing) _then) = __$CartPricingCopyWithImpl;
@override @useResult
$Res call({
 double subtotal, double discountTotal, double entryFeeTotal, double totalAmount
});




}
/// @nodoc
class __$CartPricingCopyWithImpl<$Res>
    implements _$CartPricingCopyWith<$Res> {
  __$CartPricingCopyWithImpl(this._self, this._then);

  final _CartPricing _self;
  final $Res Function(_CartPricing) _then;

/// Create a copy of CartPricing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotal = null,Object? discountTotal = null,Object? entryFeeTotal = null,Object? totalAmount = null,}) {
  return _then(_CartPricing(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,discountTotal: null == discountTotal ? _self.discountTotal : discountTotal // ignore: cast_nullable_to_non_nullable
as double,entryFeeTotal: null == entryFeeTotal ? _self.entryFeeTotal : entryFeeTotal // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
