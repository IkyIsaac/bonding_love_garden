// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'package_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PackageOffer {

 String get id; String get name; String? get description; double get price; DateTime? get availabilityStart; DateTime? get availabilityEnd;
/// Create a copy of PackageOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackageOfferCopyWith<PackageOffer> get copyWith => _$PackageOfferCopyWithImpl<PackageOffer>(this as PackageOffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackageOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.availabilityStart, availabilityStart) || other.availabilityStart == availabilityStart)&&(identical(other.availabilityEnd, availabilityEnd) || other.availabilityEnd == availabilityEnd));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,price,availabilityStart,availabilityEnd);

@override
String toString() {
  return 'PackageOffer(id: $id, name: $name, description: $description, price: $price, availabilityStart: $availabilityStart, availabilityEnd: $availabilityEnd)';
}


}

/// @nodoc
abstract mixin class $PackageOfferCopyWith<$Res>  {
  factory $PackageOfferCopyWith(PackageOffer value, $Res Function(PackageOffer) _then) = _$PackageOfferCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, double price, DateTime? availabilityStart, DateTime? availabilityEnd
});




}
/// @nodoc
class _$PackageOfferCopyWithImpl<$Res>
    implements $PackageOfferCopyWith<$Res> {
  _$PackageOfferCopyWithImpl(this._self, this._then);

  final PackageOffer _self;
  final $Res Function(PackageOffer) _then;

/// Create a copy of PackageOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? price = null,Object? availabilityStart = freezed,Object? availabilityEnd = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,availabilityStart: freezed == availabilityStart ? _self.availabilityStart : availabilityStart // ignore: cast_nullable_to_non_nullable
as DateTime?,availabilityEnd: freezed == availabilityEnd ? _self.availabilityEnd : availabilityEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PackageOffer].
extension PackageOfferPatterns on PackageOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackageOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackageOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackageOffer value)  $default,){
final _that = this;
switch (_that) {
case _PackageOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackageOffer value)?  $default,){
final _that = this;
switch (_that) {
case _PackageOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  double price,  DateTime? availabilityStart,  DateTime? availabilityEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackageOffer() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.price,_that.availabilityStart,_that.availabilityEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  double price,  DateTime? availabilityStart,  DateTime? availabilityEnd)  $default,) {final _that = this;
switch (_that) {
case _PackageOffer():
return $default(_that.id,_that.name,_that.description,_that.price,_that.availabilityStart,_that.availabilityEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  double price,  DateTime? availabilityStart,  DateTime? availabilityEnd)?  $default,) {final _that = this;
switch (_that) {
case _PackageOffer() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.price,_that.availabilityStart,_that.availabilityEnd);case _:
  return null;

}
}

}

/// @nodoc


class _PackageOffer implements PackageOffer {
  const _PackageOffer({required this.id, required this.name, this.description, required this.price, this.availabilityStart, this.availabilityEnd});
  

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  double price;
@override final  DateTime? availabilityStart;
@override final  DateTime? availabilityEnd;

/// Create a copy of PackageOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackageOfferCopyWith<_PackageOffer> get copyWith => __$PackageOfferCopyWithImpl<_PackageOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackageOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.availabilityStart, availabilityStart) || other.availabilityStart == availabilityStart)&&(identical(other.availabilityEnd, availabilityEnd) || other.availabilityEnd == availabilityEnd));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,price,availabilityStart,availabilityEnd);

@override
String toString() {
  return 'PackageOffer(id: $id, name: $name, description: $description, price: $price, availabilityStart: $availabilityStart, availabilityEnd: $availabilityEnd)';
}


}

/// @nodoc
abstract mixin class _$PackageOfferCopyWith<$Res> implements $PackageOfferCopyWith<$Res> {
  factory _$PackageOfferCopyWith(_PackageOffer value, $Res Function(_PackageOffer) _then) = __$PackageOfferCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, double price, DateTime? availabilityStart, DateTime? availabilityEnd
});




}
/// @nodoc
class __$PackageOfferCopyWithImpl<$Res>
    implements _$PackageOfferCopyWith<$Res> {
  __$PackageOfferCopyWithImpl(this._self, this._then);

  final _PackageOffer _self;
  final $Res Function(_PackageOffer) _then;

/// Create a copy of PackageOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? price = null,Object? availabilityStart = freezed,Object? availabilityEnd = freezed,}) {
  return _then(_PackageOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,availabilityStart: freezed == availabilityStart ? _self.availabilityStart : availabilityStart // ignore: cast_nullable_to_non_nullable
as DateTime?,availabilityEnd: freezed == availabilityEnd ? _self.availabilityEnd : availabilityEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
