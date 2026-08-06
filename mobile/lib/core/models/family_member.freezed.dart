// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FamilyMember {

 String get id; String get fullName; FamilyMemberKind get kind; int? get age; String? get gender; String? get allergiesNotes; String? get generalNotes; bool get isPrimaryChild;
/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyMemberCopyWith<FamilyMember> get copyWith => _$FamilyMemberCopyWithImpl<FamilyMember>(this as FamilyMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyMember&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.age, age) || other.age == age)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.allergiesNotes, allergiesNotes) || other.allergiesNotes == allergiesNotes)&&(identical(other.generalNotes, generalNotes) || other.generalNotes == generalNotes)&&(identical(other.isPrimaryChild, isPrimaryChild) || other.isPrimaryChild == isPrimaryChild));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,kind,age,gender,allergiesNotes,generalNotes,isPrimaryChild);

@override
String toString() {
  return 'FamilyMember(id: $id, fullName: $fullName, kind: $kind, age: $age, gender: $gender, allergiesNotes: $allergiesNotes, generalNotes: $generalNotes, isPrimaryChild: $isPrimaryChild)';
}


}

/// @nodoc
abstract mixin class $FamilyMemberCopyWith<$Res>  {
  factory $FamilyMemberCopyWith(FamilyMember value, $Res Function(FamilyMember) _then) = _$FamilyMemberCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, FamilyMemberKind kind, int? age, String? gender, String? allergiesNotes, String? generalNotes, bool isPrimaryChild
});




}
/// @nodoc
class _$FamilyMemberCopyWithImpl<$Res>
    implements $FamilyMemberCopyWith<$Res> {
  _$FamilyMemberCopyWithImpl(this._self, this._then);

  final FamilyMember _self;
  final $Res Function(FamilyMember) _then;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? kind = null,Object? age = freezed,Object? gender = freezed,Object? allergiesNotes = freezed,Object? generalNotes = freezed,Object? isPrimaryChild = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FamilyMemberKind,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,allergiesNotes: freezed == allergiesNotes ? _self.allergiesNotes : allergiesNotes // ignore: cast_nullable_to_non_nullable
as String?,generalNotes: freezed == generalNotes ? _self.generalNotes : generalNotes // ignore: cast_nullable_to_non_nullable
as String?,isPrimaryChild: null == isPrimaryChild ? _self.isPrimaryChild : isPrimaryChild // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyMember].
extension FamilyMemberPatterns on FamilyMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyMember value)  $default,){
final _that = this;
switch (_that) {
case _FamilyMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyMember value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  FamilyMemberKind kind,  int? age,  String? gender,  String? allergiesNotes,  String? generalNotes,  bool isPrimaryChild)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
return $default(_that.id,_that.fullName,_that.kind,_that.age,_that.gender,_that.allergiesNotes,_that.generalNotes,_that.isPrimaryChild);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  FamilyMemberKind kind,  int? age,  String? gender,  String? allergiesNotes,  String? generalNotes,  bool isPrimaryChild)  $default,) {final _that = this;
switch (_that) {
case _FamilyMember():
return $default(_that.id,_that.fullName,_that.kind,_that.age,_that.gender,_that.allergiesNotes,_that.generalNotes,_that.isPrimaryChild);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  FamilyMemberKind kind,  int? age,  String? gender,  String? allergiesNotes,  String? generalNotes,  bool isPrimaryChild)?  $default,) {final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
return $default(_that.id,_that.fullName,_that.kind,_that.age,_that.gender,_that.allergiesNotes,_that.generalNotes,_that.isPrimaryChild);case _:
  return null;

}
}

}

/// @nodoc


class _FamilyMember implements FamilyMember {
  const _FamilyMember({required this.id, required this.fullName, required this.kind, this.age, this.gender, this.allergiesNotes, this.generalNotes, required this.isPrimaryChild});
  

@override final  String id;
@override final  String fullName;
@override final  FamilyMemberKind kind;
@override final  int? age;
@override final  String? gender;
@override final  String? allergiesNotes;
@override final  String? generalNotes;
@override final  bool isPrimaryChild;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyMemberCopyWith<_FamilyMember> get copyWith => __$FamilyMemberCopyWithImpl<_FamilyMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyMember&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.age, age) || other.age == age)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.allergiesNotes, allergiesNotes) || other.allergiesNotes == allergiesNotes)&&(identical(other.generalNotes, generalNotes) || other.generalNotes == generalNotes)&&(identical(other.isPrimaryChild, isPrimaryChild) || other.isPrimaryChild == isPrimaryChild));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,kind,age,gender,allergiesNotes,generalNotes,isPrimaryChild);

@override
String toString() {
  return 'FamilyMember(id: $id, fullName: $fullName, kind: $kind, age: $age, gender: $gender, allergiesNotes: $allergiesNotes, generalNotes: $generalNotes, isPrimaryChild: $isPrimaryChild)';
}


}

/// @nodoc
abstract mixin class _$FamilyMemberCopyWith<$Res> implements $FamilyMemberCopyWith<$Res> {
  factory _$FamilyMemberCopyWith(_FamilyMember value, $Res Function(_FamilyMember) _then) = __$FamilyMemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, FamilyMemberKind kind, int? age, String? gender, String? allergiesNotes, String? generalNotes, bool isPrimaryChild
});




}
/// @nodoc
class __$FamilyMemberCopyWithImpl<$Res>
    implements _$FamilyMemberCopyWith<$Res> {
  __$FamilyMemberCopyWithImpl(this._self, this._then);

  final _FamilyMember _self;
  final $Res Function(_FamilyMember) _then;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? kind = null,Object? age = freezed,Object? gender = freezed,Object? allergiesNotes = freezed,Object? generalNotes = freezed,Object? isPrimaryChild = null,}) {
  return _then(_FamilyMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FamilyMemberKind,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,allergiesNotes: freezed == allergiesNotes ? _self.allergiesNotes : allergiesNotes // ignore: cast_nullable_to_non_nullable
as String?,generalNotes: freezed == generalNotes ? _self.generalNotes : generalNotes // ignore: cast_nullable_to_non_nullable
as String?,isPrimaryChild: null == isPrimaryChild ? _self.isPrimaryChild : isPrimaryChild // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
