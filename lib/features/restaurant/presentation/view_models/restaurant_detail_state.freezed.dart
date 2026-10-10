// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RestaurantDetailState {

 Restaurant? get restaurant; List<FoodVO> get foods; bool get isLoading; bool get isLoadingMore; bool get hasNext; int get currentPage; Object? get error;
/// Create a copy of RestaurantDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantDetailStateCopyWith<RestaurantDetailState> get copyWith => _$RestaurantDetailStateCopyWithImpl<RestaurantDetailState>(this as RestaurantDetailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RestaurantDetailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantDetailState&&(identical(other.restaurant, _this.restaurant) || other.restaurant == _this.restaurant)&&const DeepCollectionEquality().equals(other.foods, _this.foods)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&(identical(other.hasNext, _this.hasNext) || other.hasNext == _this.hasNext)&&(identical(other.currentPage, _this.currentPage) || other.currentPage == _this.currentPage)&&const DeepCollectionEquality().equals(other.error, _this.error));
}


@override
int get hashCode {
  final _this = this as RestaurantDetailState;
  return Object.hash(runtimeType,_this.restaurant,const DeepCollectionEquality().hash(_this.foods),_this.isLoading,_this.isLoadingMore,_this.hasNext,_this.currentPage,const DeepCollectionEquality().hash(_this.error));
}

@override
String toString() {
  final _this = this as RestaurantDetailState;
  return 'RestaurantDetailState(restaurant: ${_this.restaurant}, foods: ${_this.foods}, isLoading: ${_this.isLoading}, isLoadingMore: ${_this.isLoadingMore}, hasNext: ${_this.hasNext}, currentPage: ${_this.currentPage}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $RestaurantDetailStateCopyWith<$Res>  {
  factory $RestaurantDetailStateCopyWith(RestaurantDetailState value, $Res Function(RestaurantDetailState) _then) = _$RestaurantDetailStateCopyWithImpl;
@useResult
$Res call({
 Restaurant? restaurant, List<FoodVO> foods, bool isLoading, bool isLoadingMore, bool hasNext, int currentPage, Object? error
});




}
/// @nodoc
class _$RestaurantDetailStateCopyWithImpl<$Res>
    implements $RestaurantDetailStateCopyWith<$Res> {
  _$RestaurantDetailStateCopyWithImpl(this._self, this._then);

  final RestaurantDetailState _self;
  final $Res Function(RestaurantDetailState) _then;

/// Create a copy of RestaurantDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restaurant = freezed,Object? foods = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasNext = null,Object? currentPage = null,Object? error = freezed,}) {
  return _then(RestaurantDetailState(
restaurant: freezed == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as Restaurant?,foods: null == foods ? _self.foods : foods // ignore: cast_nullable_to_non_nullable
as List<FoodVO>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantDetailState].
extension RestaurantDetailStatePatterns on RestaurantDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantDetailState value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Restaurant? restaurant,  List<FoodVO> foods,  bool isLoading,  bool isLoadingMore,  bool hasNext,  int currentPage,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantDetailState() when $default != null:
return $default(_that.restaurant,_that.foods,_that.isLoading,_that.isLoadingMore,_that.hasNext,_that.currentPage,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Restaurant? restaurant,  List<FoodVO> foods,  bool isLoading,  bool isLoadingMore,  bool hasNext,  int currentPage,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _RestaurantDetailState():
return $default(_that.restaurant,_that.foods,_that.isLoading,_that.isLoadingMore,_that.hasNext,_that.currentPage,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Restaurant? restaurant,  List<FoodVO> foods,  bool isLoading,  bool isLoadingMore,  bool hasNext,  int currentPage,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantDetailState() when $default != null:
return $default(_that.restaurant,_that.foods,_that.isLoading,_that.isLoadingMore,_that.hasNext,_that.currentPage,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _RestaurantDetailState implements RestaurantDetailState {
  const _RestaurantDetailState({this.restaurant,  List<FoodVO> foods = const [], this.isLoading = true, this.isLoadingMore = false, this.hasNext = false, this.currentPage = 1, this.error}): _foods = foods;
  

@override final  Restaurant? restaurant;
 final  List<FoodVO> _foods;
@override@JsonKey() List<FoodVO> get foods {
  if (_foods is EqualUnmodifiableListView) return _foods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foods);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool hasNext;
@override@JsonKey() final  int currentPage;
@override final  Object? error;

/// Create a copy of RestaurantDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantDetailStateCopyWith<_RestaurantDetailState> get copyWith => __$RestaurantDetailStateCopyWithImpl<_RestaurantDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantDetailState&&(identical(other.restaurant, restaurant) || other.restaurant == restaurant)&&const DeepCollectionEquality().equals(other.foods, _foods)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,restaurant,const DeepCollectionEquality().hash(_foods),isLoading,isLoadingMore,hasNext,currentPage,const DeepCollectionEquality().hash(error));
}

@override
String toString() {
    return 'RestaurantDetailState(restaurant: $restaurant, foods: $foods, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasNext: $hasNext, currentPage: $currentPage, error: $error)';
}


}

/// @nodoc
abstract mixin class _$RestaurantDetailStateCopyWith<$Res> implements $RestaurantDetailStateCopyWith<$Res> {
  factory _$RestaurantDetailStateCopyWith(_RestaurantDetailState value, $Res Function(_RestaurantDetailState) _then) = __$RestaurantDetailStateCopyWithImpl;
@override @useResult
$Res call({
 Restaurant? restaurant, List<FoodVO> foods, bool isLoading, bool isLoadingMore, bool hasNext, int currentPage, Object? error
});




}
/// @nodoc
class __$RestaurantDetailStateCopyWithImpl<$Res>
    implements _$RestaurantDetailStateCopyWith<$Res> {
  __$RestaurantDetailStateCopyWithImpl(this._self, this._then);

  final _RestaurantDetailState _self;
  final $Res Function(_RestaurantDetailState) _then;

/// Create a copy of RestaurantDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restaurant = freezed,Object? foods = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasNext = null,Object? currentPage = null,Object? error = freezed,}) {
  return _then(_RestaurantDetailState(
restaurant: freezed == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as Restaurant?,foods: null == foods ? _self._foods : foods // ignore: cast_nullable_to_non_nullable
as List<FoodVO>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
