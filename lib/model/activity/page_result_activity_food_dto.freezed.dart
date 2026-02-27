// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_result_activity_food_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PageResultActivityFoodDto {

 int get currentPage; List<ActivityFoodDto> get items; int get totalPages; int get totalItems; bool get hasNext;
/// Create a copy of PageResultActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageResultActivityFoodDtoCopyWith<PageResultActivityFoodDto> get copyWith => _$PageResultActivityFoodDtoCopyWithImpl<PageResultActivityFoodDto>(this as PageResultActivityFoodDto, _$identity);

  /// Serializes this PageResultActivityFoodDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageResultActivityFoodDto&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentPage,const DeepCollectionEquality().hash(items),totalPages,totalItems,hasNext);

@override
String toString() {
  return 'PageResultActivityFoodDto(currentPage: $currentPage, items: $items, totalPages: $totalPages, totalItems: $totalItems, hasNext: $hasNext)';
}


}

/// @nodoc
abstract mixin class $PageResultActivityFoodDtoCopyWith<$Res>  {
  factory $PageResultActivityFoodDtoCopyWith(PageResultActivityFoodDto value, $Res Function(PageResultActivityFoodDto) _then) = _$PageResultActivityFoodDtoCopyWithImpl;
@useResult
$Res call({
 int currentPage, List<ActivityFoodDto> items, int totalPages, int totalItems, bool hasNext
});




}
/// @nodoc
class _$PageResultActivityFoodDtoCopyWithImpl<$Res>
    implements $PageResultActivityFoodDtoCopyWith<$Res> {
  _$PageResultActivityFoodDtoCopyWithImpl(this._self, this._then);

  final PageResultActivityFoodDto _self;
  final $Res Function(PageResultActivityFoodDto) _then;

/// Create a copy of PageResultActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPage = null,Object? items = null,Object? totalPages = null,Object? totalItems = null,Object? hasNext = null,}) {
  return _then(_self.copyWith(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ActivityFoodDto>,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PageResultActivityFoodDto].
extension PageResultActivityFoodDtoPatterns on PageResultActivityFoodDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageResultActivityFoodDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageResultActivityFoodDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageResultActivityFoodDto value)  $default,){
final _that = this;
switch (_that) {
case _PageResultActivityFoodDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageResultActivityFoodDto value)?  $default,){
final _that = this;
switch (_that) {
case _PageResultActivityFoodDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentPage,  List<ActivityFoodDto> items,  int totalPages,  int totalItems,  bool hasNext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageResultActivityFoodDto() when $default != null:
return $default(_that.currentPage,_that.items,_that.totalPages,_that.totalItems,_that.hasNext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentPage,  List<ActivityFoodDto> items,  int totalPages,  int totalItems,  bool hasNext)  $default,) {final _that = this;
switch (_that) {
case _PageResultActivityFoodDto():
return $default(_that.currentPage,_that.items,_that.totalPages,_that.totalItems,_that.hasNext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentPage,  List<ActivityFoodDto> items,  int totalPages,  int totalItems,  bool hasNext)?  $default,) {final _that = this;
switch (_that) {
case _PageResultActivityFoodDto() when $default != null:
return $default(_that.currentPage,_that.items,_that.totalPages,_that.totalItems,_that.hasNext);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageResultActivityFoodDto implements PageResultActivityFoodDto {
  const _PageResultActivityFoodDto({required this.currentPage, required final  List<ActivityFoodDto> items, required this.totalPages, required this.totalItems, required this.hasNext}): _items = items;
  factory _PageResultActivityFoodDto.fromJson(Map<String, dynamic> json) => _$PageResultActivityFoodDtoFromJson(json);

@override final  int currentPage;
 final  List<ActivityFoodDto> _items;
@override List<ActivityFoodDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int totalPages;
@override final  int totalItems;
@override final  bool hasNext;

/// Create a copy of PageResultActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageResultActivityFoodDtoCopyWith<_PageResultActivityFoodDto> get copyWith => __$PageResultActivityFoodDtoCopyWithImpl<_PageResultActivityFoodDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageResultActivityFoodDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageResultActivityFoodDto&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentPage,const DeepCollectionEquality().hash(_items),totalPages,totalItems,hasNext);

@override
String toString() {
  return 'PageResultActivityFoodDto(currentPage: $currentPage, items: $items, totalPages: $totalPages, totalItems: $totalItems, hasNext: $hasNext)';
}


}

/// @nodoc
abstract mixin class _$PageResultActivityFoodDtoCopyWith<$Res> implements $PageResultActivityFoodDtoCopyWith<$Res> {
  factory _$PageResultActivityFoodDtoCopyWith(_PageResultActivityFoodDto value, $Res Function(_PageResultActivityFoodDto) _then) = __$PageResultActivityFoodDtoCopyWithImpl;
@override @useResult
$Res call({
 int currentPage, List<ActivityFoodDto> items, int totalPages, int totalItems, bool hasNext
});




}
/// @nodoc
class __$PageResultActivityFoodDtoCopyWithImpl<$Res>
    implements _$PageResultActivityFoodDtoCopyWith<$Res> {
  __$PageResultActivityFoodDtoCopyWithImpl(this._self, this._then);

  final _PageResultActivityFoodDto _self;
  final $Res Function(_PageResultActivityFoodDto) _then;

/// Create a copy of PageResultActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPage = null,Object? items = null,Object? totalPages = null,Object? totalItems = null,Object? hasNext = null,}) {
  return _then(_PageResultActivityFoodDto(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ActivityFoodDto>,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
