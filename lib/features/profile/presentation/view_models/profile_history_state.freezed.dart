// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileHistoryState {

 bool get isLoading; bool get isLoadingMore; List<BrowseHistoryItemResponse> get items; bool get hasNext; int get currentPage; int get totalItems; Object? get error;
/// Create a copy of ProfileHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileHistoryStateCopyWith<ProfileHistoryState> get copyWith => _$ProfileHistoryStateCopyWithImpl<ProfileHistoryState>(this as ProfileHistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileHistoryState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,const DeepCollectionEquality().hash(items),hasNext,currentPage,totalItems,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProfileHistoryState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, items: $items, hasNext: $hasNext, currentPage: $currentPage, totalItems: $totalItems, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProfileHistoryStateCopyWith<$Res>  {
  factory $ProfileHistoryStateCopyWith(ProfileHistoryState value, $Res Function(ProfileHistoryState) _then) = _$ProfileHistoryStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isLoadingMore, List<BrowseHistoryItemResponse> items, bool hasNext, int currentPage, int totalItems, Object? error
});




}
/// @nodoc
class _$ProfileHistoryStateCopyWithImpl<$Res>
    implements $ProfileHistoryStateCopyWith<$Res> {
  _$ProfileHistoryStateCopyWithImpl(this._self, this._then);

  final ProfileHistoryState _self;
  final $Res Function(ProfileHistoryState) _then;

/// Create a copy of ProfileHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? items = null,Object? hasNext = null,Object? currentPage = null,Object? totalItems = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BrowseHistoryItemResponse>,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileHistoryState].
extension ProfileHistoryStatePatterns on ProfileHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  List<BrowseHistoryItemResponse> items,  bool hasNext,  int currentPage,  int totalItems,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileHistoryState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.items,_that.hasNext,_that.currentPage,_that.totalItems,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  List<BrowseHistoryItemResponse> items,  bool hasNext,  int currentPage,  int totalItems,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _ProfileHistoryState():
return $default(_that.isLoading,_that.isLoadingMore,_that.items,_that.hasNext,_that.currentPage,_that.totalItems,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isLoadingMore,  List<BrowseHistoryItemResponse> items,  bool hasNext,  int currentPage,  int totalItems,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _ProfileHistoryState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.items,_that.hasNext,_that.currentPage,_that.totalItems,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileHistoryState implements ProfileHistoryState {
  const _ProfileHistoryState({this.isLoading = false, this.isLoadingMore = false, final  List<BrowseHistoryItemResponse> items = const [], this.hasNext = false, this.currentPage = 0, this.totalItems = 0, this.error}): _items = items;
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
 final  List<BrowseHistoryItemResponse> _items;
@override@JsonKey() List<BrowseHistoryItemResponse> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool hasNext;
@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int totalItems;
@override final  Object? error;

/// Create a copy of ProfileHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileHistoryStateCopyWith<_ProfileHistoryState> get copyWith => __$ProfileHistoryStateCopyWithImpl<_ProfileHistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileHistoryState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,const DeepCollectionEquality().hash(_items),hasNext,currentPage,totalItems,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProfileHistoryState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, items: $items, hasNext: $hasNext, currentPage: $currentPage, totalItems: $totalItems, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProfileHistoryStateCopyWith<$Res> implements $ProfileHistoryStateCopyWith<$Res> {
  factory _$ProfileHistoryStateCopyWith(_ProfileHistoryState value, $Res Function(_ProfileHistoryState) _then) = __$ProfileHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isLoadingMore, List<BrowseHistoryItemResponse> items, bool hasNext, int currentPage, int totalItems, Object? error
});




}
/// @nodoc
class __$ProfileHistoryStateCopyWithImpl<$Res>
    implements _$ProfileHistoryStateCopyWith<$Res> {
  __$ProfileHistoryStateCopyWithImpl(this._self, this._then);

  final _ProfileHistoryState _self;
  final $Res Function(_ProfileHistoryState) _then;

/// Create a copy of ProfileHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? items = null,Object? hasNext = null,Object? currentPage = null,Object? totalItems = null,Object? error = freezed,}) {
  return _then(_ProfileHistoryState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BrowseHistoryItemResponse>,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
