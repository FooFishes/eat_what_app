// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_tag_library_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileTagLibraryState {

 bool get isLoading; List<FoodTagSummaryVO> get systemTags; List<FoodTagSummaryVO> get customTags; Object? get error;
/// Create a copy of ProfileTagLibraryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileTagLibraryStateCopyWith<ProfileTagLibraryState> get copyWith => _$ProfileTagLibraryStateCopyWithImpl<ProfileTagLibraryState>(this as ProfileTagLibraryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProfileTagLibraryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileTagLibraryState&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&const DeepCollectionEquality().equals(other.systemTags, _this.systemTags)&&const DeepCollectionEquality().equals(other.customTags, _this.customTags)&&const DeepCollectionEquality().equals(other.error, _this.error));
}


@override
int get hashCode {
  final _this = this as ProfileTagLibraryState;
  return Object.hash(runtimeType,_this.isLoading,const DeepCollectionEquality().hash(_this.systemTags),const DeepCollectionEquality().hash(_this.customTags),const DeepCollectionEquality().hash(_this.error));
}

@override
String toString() {
  final _this = this as ProfileTagLibraryState;
  return 'ProfileTagLibraryState(isLoading: ${_this.isLoading}, systemTags: ${_this.systemTags}, customTags: ${_this.customTags}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $ProfileTagLibraryStateCopyWith<$Res>  {
  factory $ProfileTagLibraryStateCopyWith(ProfileTagLibraryState value, $Res Function(ProfileTagLibraryState) _then) = _$ProfileTagLibraryStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<FoodTagSummaryVO> systemTags, List<FoodTagSummaryVO> customTags, Object? error
});




}
/// @nodoc
class _$ProfileTagLibraryStateCopyWithImpl<$Res>
    implements $ProfileTagLibraryStateCopyWith<$Res> {
  _$ProfileTagLibraryStateCopyWithImpl(this._self, this._then);

  final ProfileTagLibraryState _self;
  final $Res Function(ProfileTagLibraryState) _then;

/// Create a copy of ProfileTagLibraryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? systemTags = null,Object? customTags = null,Object? error = freezed,}) {
  return _then(ProfileTagLibraryState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,systemTags: null == systemTags ? _self.systemTags : systemTags // ignore: cast_nullable_to_non_nullable
as List<FoodTagSummaryVO>,customTags: null == customTags ? _self.customTags : customTags // ignore: cast_nullable_to_non_nullable
as List<FoodTagSummaryVO>,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileTagLibraryState].
extension ProfileTagLibraryStatePatterns on ProfileTagLibraryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileTagLibraryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileTagLibraryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileTagLibraryState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileTagLibraryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileTagLibraryState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileTagLibraryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<FoodTagSummaryVO> systemTags,  List<FoodTagSummaryVO> customTags,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileTagLibraryState() when $default != null:
return $default(_that.isLoading,_that.systemTags,_that.customTags,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<FoodTagSummaryVO> systemTags,  List<FoodTagSummaryVO> customTags,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _ProfileTagLibraryState():
return $default(_that.isLoading,_that.systemTags,_that.customTags,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<FoodTagSummaryVO> systemTags,  List<FoodTagSummaryVO> customTags,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _ProfileTagLibraryState() when $default != null:
return $default(_that.isLoading,_that.systemTags,_that.customTags,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileTagLibraryState implements ProfileTagLibraryState {
  const _ProfileTagLibraryState({this.isLoading = true,  List<FoodTagSummaryVO> systemTags = const [],  List<FoodTagSummaryVO> customTags = const [], this.error}): _systemTags = systemTags,_customTags = customTags;
  

@override@JsonKey() final  bool isLoading;
 final  List<FoodTagSummaryVO> _systemTags;
@override@JsonKey() List<FoodTagSummaryVO> get systemTags {
  if (_systemTags is EqualUnmodifiableListView) return _systemTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_systemTags);
}

 final  List<FoodTagSummaryVO> _customTags;
@override@JsonKey() List<FoodTagSummaryVO> get customTags {
  if (_customTags is EqualUnmodifiableListView) return _customTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customTags);
}

@override final  Object? error;

/// Create a copy of ProfileTagLibraryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileTagLibraryStateCopyWith<_ProfileTagLibraryState> get copyWith => __$ProfileTagLibraryStateCopyWithImpl<_ProfileTagLibraryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileTagLibraryState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.systemTags, _systemTags)&&const DeepCollectionEquality().equals(other.customTags, _customTags)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_systemTags),const DeepCollectionEquality().hash(_customTags),const DeepCollectionEquality().hash(error));
}

@override
String toString() {
    return 'ProfileTagLibraryState(isLoading: $isLoading, systemTags: $systemTags, customTags: $customTags, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProfileTagLibraryStateCopyWith<$Res> implements $ProfileTagLibraryStateCopyWith<$Res> {
  factory _$ProfileTagLibraryStateCopyWith(_ProfileTagLibraryState value, $Res Function(_ProfileTagLibraryState) _then) = __$ProfileTagLibraryStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<FoodTagSummaryVO> systemTags, List<FoodTagSummaryVO> customTags, Object? error
});




}
/// @nodoc
class __$ProfileTagLibraryStateCopyWithImpl<$Res>
    implements _$ProfileTagLibraryStateCopyWith<$Res> {
  __$ProfileTagLibraryStateCopyWithImpl(this._self, this._then);

  final _ProfileTagLibraryState _self;
  final $Res Function(_ProfileTagLibraryState) _then;

/// Create a copy of ProfileTagLibraryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? systemTags = null,Object? customTags = null,Object? error = freezed,}) {
  return _then(_ProfileTagLibraryState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,systemTags: null == systemTags ? _self._systemTags : systemTags // ignore: cast_nullable_to_non_nullable
as List<FoodTagSummaryVO>,customTags: null == customTags ? _self._customTags : customTags // ignore: cast_nullable_to_non_nullable
as List<FoodTagSummaryVO>,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
