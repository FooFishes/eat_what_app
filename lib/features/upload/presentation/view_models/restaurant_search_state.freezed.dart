// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RestaurantSearchState {

 bool get isLoadingHint; bool get shouldShowIntroHint; bool get isSearching; String get keyword; List<Restaurant> get results; bool get hasSearched;
/// Create a copy of RestaurantSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantSearchStateCopyWith<RestaurantSearchState> get copyWith => _$RestaurantSearchStateCopyWithImpl<RestaurantSearchState>(this as RestaurantSearchState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RestaurantSearchState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantSearchState&&(identical(other.isLoadingHint, _this.isLoadingHint) || other.isLoadingHint == _this.isLoadingHint)&&(identical(other.shouldShowIntroHint, _this.shouldShowIntroHint) || other.shouldShowIntroHint == _this.shouldShowIntroHint)&&(identical(other.isSearching, _this.isSearching) || other.isSearching == _this.isSearching)&&(identical(other.keyword, _this.keyword) || other.keyword == _this.keyword)&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.hasSearched, _this.hasSearched) || other.hasSearched == _this.hasSearched));
}


@override
int get hashCode {
  final _this = this as RestaurantSearchState;
  return Object.hash(runtimeType,_this.isLoadingHint,_this.shouldShowIntroHint,_this.isSearching,_this.keyword,const DeepCollectionEquality().hash(_this.results),_this.hasSearched);
}

@override
String toString() {
  final _this = this as RestaurantSearchState;
  return 'RestaurantSearchState(isLoadingHint: ${_this.isLoadingHint}, shouldShowIntroHint: ${_this.shouldShowIntroHint}, isSearching: ${_this.isSearching}, keyword: ${_this.keyword}, results: ${_this.results}, hasSearched: ${_this.hasSearched})';
}


}

/// @nodoc
abstract mixin class $RestaurantSearchStateCopyWith<$Res>  {
  factory $RestaurantSearchStateCopyWith(RestaurantSearchState value, $Res Function(RestaurantSearchState) _then) = _$RestaurantSearchStateCopyWithImpl;
@useResult
$Res call({
 bool isLoadingHint, bool shouldShowIntroHint, bool isSearching, String keyword, List<Restaurant> results, bool hasSearched
});




}
/// @nodoc
class _$RestaurantSearchStateCopyWithImpl<$Res>
    implements $RestaurantSearchStateCopyWith<$Res> {
  _$RestaurantSearchStateCopyWithImpl(this._self, this._then);

  final RestaurantSearchState _self;
  final $Res Function(RestaurantSearchState) _then;

/// Create a copy of RestaurantSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoadingHint = null,Object? shouldShowIntroHint = null,Object? isSearching = null,Object? keyword = null,Object? results = null,Object? hasSearched = null,}) {
  return _then(RestaurantSearchState(
isLoadingHint: null == isLoadingHint ? _self.isLoadingHint : isLoadingHint // ignore: cast_nullable_to_non_nullable
as bool,shouldShowIntroHint: null == shouldShowIntroHint ? _self.shouldShowIntroHint : shouldShowIntroHint // ignore: cast_nullable_to_non_nullable
as bool,isSearching: null == isSearching ? _self.isSearching : isSearching // ignore: cast_nullable_to_non_nullable
as bool,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<Restaurant>,hasSearched: null == hasSearched ? _self.hasSearched : hasSearched // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantSearchState].
extension RestaurantSearchStatePatterns on RestaurantSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantSearchState value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoadingHint,  bool shouldShowIntroHint,  bool isSearching,  String keyword,  List<Restaurant> results,  bool hasSearched)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantSearchState() when $default != null:
return $default(_that.isLoadingHint,_that.shouldShowIntroHint,_that.isSearching,_that.keyword,_that.results,_that.hasSearched);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoadingHint,  bool shouldShowIntroHint,  bool isSearching,  String keyword,  List<Restaurant> results,  bool hasSearched)  $default,) {final _that = this;
switch (_that) {
case _RestaurantSearchState():
return $default(_that.isLoadingHint,_that.shouldShowIntroHint,_that.isSearching,_that.keyword,_that.results,_that.hasSearched);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoadingHint,  bool shouldShowIntroHint,  bool isSearching,  String keyword,  List<Restaurant> results,  bool hasSearched)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantSearchState() when $default != null:
return $default(_that.isLoadingHint,_that.shouldShowIntroHint,_that.isSearching,_that.keyword,_that.results,_that.hasSearched);case _:
  return null;

}
}

}

/// @nodoc


class _RestaurantSearchState implements RestaurantSearchState {
  const _RestaurantSearchState({this.isLoadingHint = false, this.shouldShowIntroHint = false, this.isSearching = false, this.keyword = '',  List<Restaurant> results = const [], this.hasSearched = false}): _results = results;
  

@override@JsonKey() final  bool isLoadingHint;
@override@JsonKey() final  bool shouldShowIntroHint;
@override@JsonKey() final  bool isSearching;
@override@JsonKey() final  String keyword;
 final  List<Restaurant> _results;
@override@JsonKey() List<Restaurant> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  bool hasSearched;

/// Create a copy of RestaurantSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantSearchStateCopyWith<_RestaurantSearchState> get copyWith => __$RestaurantSearchStateCopyWithImpl<_RestaurantSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantSearchState&&(identical(other.isLoadingHint, isLoadingHint) || other.isLoadingHint == isLoadingHint)&&(identical(other.shouldShowIntroHint, shouldShowIntroHint) || other.shouldShowIntroHint == shouldShowIntroHint)&&(identical(other.isSearching, isSearching) || other.isSearching == isSearching)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.hasSearched, hasSearched) || other.hasSearched == hasSearched));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isLoadingHint,shouldShowIntroHint,isSearching,keyword,const DeepCollectionEquality().hash(_results),hasSearched);
}

@override
String toString() {
    return 'RestaurantSearchState(isLoadingHint: $isLoadingHint, shouldShowIntroHint: $shouldShowIntroHint, isSearching: $isSearching, keyword: $keyword, results: $results, hasSearched: $hasSearched)';
}


}

/// @nodoc
abstract mixin class _$RestaurantSearchStateCopyWith<$Res> implements $RestaurantSearchStateCopyWith<$Res> {
  factory _$RestaurantSearchStateCopyWith(_RestaurantSearchState value, $Res Function(_RestaurantSearchState) _then) = __$RestaurantSearchStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoadingHint, bool shouldShowIntroHint, bool isSearching, String keyword, List<Restaurant> results, bool hasSearched
});




}
/// @nodoc
class __$RestaurantSearchStateCopyWithImpl<$Res>
    implements _$RestaurantSearchStateCopyWith<$Res> {
  __$RestaurantSearchStateCopyWithImpl(this._self, this._then);

  final _RestaurantSearchState _self;
  final $Res Function(_RestaurantSearchState) _then;

/// Create a copy of RestaurantSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoadingHint = null,Object? shouldShowIntroHint = null,Object? isSearching = null,Object? keyword = null,Object? results = null,Object? hasSearched = null,}) {
  return _then(_RestaurantSearchState(
isLoadingHint: null == isLoadingHint ? _self.isLoadingHint : isLoadingHint // ignore: cast_nullable_to_non_nullable
as bool,shouldShowIntroHint: null == shouldShowIntroHint ? _self.shouldShowIntroHint : shouldShowIntroHint // ignore: cast_nullable_to_non_nullable
as bool,isSearching: null == isSearching ? _self.isSearching : isSearching // ignore: cast_nullable_to_non_nullable
as bool,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<Restaurant>,hasSearched: null == hasSearched ? _self.hasSearched : hasSearched // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
