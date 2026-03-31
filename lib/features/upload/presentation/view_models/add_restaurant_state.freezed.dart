// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_restaurant_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddRestaurantState {

 bool get isSubmitting;
/// Create a copy of AddRestaurantState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddRestaurantStateCopyWith<AddRestaurantState> get copyWith => _$AddRestaurantStateCopyWithImpl<AddRestaurantState>(this as AddRestaurantState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddRestaurantState&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting);

@override
String toString() {
  return 'AddRestaurantState(isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $AddRestaurantStateCopyWith<$Res>  {
  factory $AddRestaurantStateCopyWith(AddRestaurantState value, $Res Function(AddRestaurantState) _then) = _$AddRestaurantStateCopyWithImpl;
@useResult
$Res call({
 bool isSubmitting
});




}
/// @nodoc
class _$AddRestaurantStateCopyWithImpl<$Res>
    implements $AddRestaurantStateCopyWith<$Res> {
  _$AddRestaurantStateCopyWithImpl(this._self, this._then);

  final AddRestaurantState _self;
  final $Res Function(AddRestaurantState) _then;

/// Create a copy of AddRestaurantState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSubmitting = null,}) {
  return _then(_self.copyWith(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AddRestaurantState].
extension AddRestaurantStatePatterns on AddRestaurantState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddRestaurantState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddRestaurantState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddRestaurantState value)  $default,){
final _that = this;
switch (_that) {
case _AddRestaurantState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddRestaurantState value)?  $default,){
final _that = this;
switch (_that) {
case _AddRestaurantState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSubmitting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddRestaurantState() when $default != null:
return $default(_that.isSubmitting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSubmitting)  $default,) {final _that = this;
switch (_that) {
case _AddRestaurantState():
return $default(_that.isSubmitting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSubmitting)?  $default,) {final _that = this;
switch (_that) {
case _AddRestaurantState() when $default != null:
return $default(_that.isSubmitting);case _:
  return null;

}
}

}

/// @nodoc


class _AddRestaurantState implements AddRestaurantState {
  const _AddRestaurantState({this.isSubmitting = false});
  

@override@JsonKey() final  bool isSubmitting;

/// Create a copy of AddRestaurantState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddRestaurantStateCopyWith<_AddRestaurantState> get copyWith => __$AddRestaurantStateCopyWithImpl<_AddRestaurantState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddRestaurantState&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting);

@override
String toString() {
  return 'AddRestaurantState(isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class _$AddRestaurantStateCopyWith<$Res> implements $AddRestaurantStateCopyWith<$Res> {
  factory _$AddRestaurantStateCopyWith(_AddRestaurantState value, $Res Function(_AddRestaurantState) _then) = __$AddRestaurantStateCopyWithImpl;
@override @useResult
$Res call({
 bool isSubmitting
});




}
/// @nodoc
class __$AddRestaurantStateCopyWithImpl<$Res>
    implements _$AddRestaurantStateCopyWith<$Res> {
  __$AddRestaurantStateCopyWithImpl(this._self, this._then);

  final _AddRestaurantState _self;
  final $Res Function(_AddRestaurantState) _then;

/// Create a copy of AddRestaurantState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSubmitting = null,}) {
  return _then(_AddRestaurantState(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
