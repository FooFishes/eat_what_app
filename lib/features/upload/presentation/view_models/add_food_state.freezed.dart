// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_food_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddFoodState {

 bool get isLoadingTags; bool get isSubmitting; List<FoodTagSummaryVO> get systemTags;
/// Create a copy of AddFoodState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddFoodStateCopyWith<AddFoodState> get copyWith => _$AddFoodStateCopyWithImpl<AddFoodState>(this as AddFoodState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AddFoodState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddFoodState&&(identical(other.isLoadingTags, _this.isLoadingTags) || other.isLoadingTags == _this.isLoadingTags)&&(identical(other.isSubmitting, _this.isSubmitting) || other.isSubmitting == _this.isSubmitting)&&const DeepCollectionEquality().equals(other.systemTags, _this.systemTags));
}


@override
int get hashCode {
  final _this = this as AddFoodState;
  return Object.hash(runtimeType,_this.isLoadingTags,_this.isSubmitting,const DeepCollectionEquality().hash(_this.systemTags));
}

@override
String toString() {
  final _this = this as AddFoodState;
  return 'AddFoodState(isLoadingTags: ${_this.isLoadingTags}, isSubmitting: ${_this.isSubmitting}, systemTags: ${_this.systemTags})';
}


}

/// @nodoc
abstract mixin class $AddFoodStateCopyWith<$Res>  {
  factory $AddFoodStateCopyWith(AddFoodState value, $Res Function(AddFoodState) _then) = _$AddFoodStateCopyWithImpl;
@useResult
$Res call({
 bool isLoadingTags, bool isSubmitting, List<FoodTagSummaryVO> systemTags
});




}
/// @nodoc
class _$AddFoodStateCopyWithImpl<$Res>
    implements $AddFoodStateCopyWith<$Res> {
  _$AddFoodStateCopyWithImpl(this._self, this._then);

  final AddFoodState _self;
  final $Res Function(AddFoodState) _then;

/// Create a copy of AddFoodState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoadingTags = null,Object? isSubmitting = null,Object? systemTags = null,}) {
  return _then(AddFoodState(
isLoadingTags: null == isLoadingTags ? _self.isLoadingTags : isLoadingTags // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,systemTags: null == systemTags ? _self.systemTags : systemTags // ignore: cast_nullable_to_non_nullable
as List<FoodTagSummaryVO>,
  ));
}

}


/// Adds pattern-matching-related methods to [AddFoodState].
extension AddFoodStatePatterns on AddFoodState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddFoodState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddFoodState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddFoodState value)  $default,){
final _that = this;
switch (_that) {
case _AddFoodState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddFoodState value)?  $default,){
final _that = this;
switch (_that) {
case _AddFoodState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoadingTags,  bool isSubmitting,  List<FoodTagSummaryVO> systemTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddFoodState() when $default != null:
return $default(_that.isLoadingTags,_that.isSubmitting,_that.systemTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoadingTags,  bool isSubmitting,  List<FoodTagSummaryVO> systemTags)  $default,) {final _that = this;
switch (_that) {
case _AddFoodState():
return $default(_that.isLoadingTags,_that.isSubmitting,_that.systemTags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoadingTags,  bool isSubmitting,  List<FoodTagSummaryVO> systemTags)?  $default,) {final _that = this;
switch (_that) {
case _AddFoodState() when $default != null:
return $default(_that.isLoadingTags,_that.isSubmitting,_that.systemTags);case _:
  return null;

}
}

}

/// @nodoc


class _AddFoodState implements AddFoodState {
  const _AddFoodState({this.isLoadingTags = true, this.isSubmitting = false,  List<FoodTagSummaryVO> systemTags = const []}): _systemTags = systemTags;
  

@override@JsonKey() final  bool isLoadingTags;
@override@JsonKey() final  bool isSubmitting;
 final  List<FoodTagSummaryVO> _systemTags;
@override@JsonKey() List<FoodTagSummaryVO> get systemTags {
  if (_systemTags is EqualUnmodifiableListView) return _systemTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_systemTags);
}


/// Create a copy of AddFoodState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddFoodStateCopyWith<_AddFoodState> get copyWith => __$AddFoodStateCopyWithImpl<_AddFoodState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddFoodState&&(identical(other.isLoadingTags, isLoadingTags) || other.isLoadingTags == isLoadingTags)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&const DeepCollectionEquality().equals(other.systemTags, _systemTags));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isLoadingTags,isSubmitting,const DeepCollectionEquality().hash(_systemTags));
}

@override
String toString() {
    return 'AddFoodState(isLoadingTags: $isLoadingTags, isSubmitting: $isSubmitting, systemTags: $systemTags)';
}


}

/// @nodoc
abstract mixin class _$AddFoodStateCopyWith<$Res> implements $AddFoodStateCopyWith<$Res> {
  factory _$AddFoodStateCopyWith(_AddFoodState value, $Res Function(_AddFoodState) _then) = __$AddFoodStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoadingTags, bool isSubmitting, List<FoodTagSummaryVO> systemTags
});




}
/// @nodoc
class __$AddFoodStateCopyWithImpl<$Res>
    implements _$AddFoodStateCopyWith<$Res> {
  __$AddFoodStateCopyWithImpl(this._self, this._then);

  final _AddFoodState _self;
  final $Res Function(_AddFoodState) _then;

/// Create a copy of AddFoodState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoadingTags = null,Object? isSubmitting = null,Object? systemTags = null,}) {
  return _then(_AddFoodState(
isLoadingTags: null == isLoadingTags ? _self.isLoadingTags : isLoadingTags // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,systemTags: null == systemTags ? _self._systemTags : systemTags // ignore: cast_nullable_to_non_nullable
as List<FoodTagSummaryVO>,
  ));
}


}

// dart format on
