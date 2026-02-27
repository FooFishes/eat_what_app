// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_food_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityFoodDto {

 int get id; int get accountId; String get foodName; String get description; int get provinceId; int get cityId; List<String> get pictureUrl; int get likesCount; bool get isLiked; int get createdAt; int get updatedAt; String get uploaderName;
/// Create a copy of ActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityFoodDtoCopyWith<ActivityFoodDto> get copyWith => _$ActivityFoodDtoCopyWithImpl<ActivityFoodDto>(this as ActivityFoodDto, _$identity);

  /// Serializes this ActivityFoodDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityFoodDto&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.description, description) || other.description == description)&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other.pictureUrl, pictureUrl)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.uploaderName, uploaderName) || other.uploaderName == uploaderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountId,foodName,description,provinceId,cityId,const DeepCollectionEquality().hash(pictureUrl),likesCount,isLiked,createdAt,updatedAt,uploaderName);

@override
String toString() {
  return 'ActivityFoodDto(id: $id, accountId: $accountId, foodName: $foodName, description: $description, provinceId: $provinceId, cityId: $cityId, pictureUrl: $pictureUrl, likesCount: $likesCount, isLiked: $isLiked, createdAt: $createdAt, updatedAt: $updatedAt, uploaderName: $uploaderName)';
}


}

/// @nodoc
abstract mixin class $ActivityFoodDtoCopyWith<$Res>  {
  factory $ActivityFoodDtoCopyWith(ActivityFoodDto value, $Res Function(ActivityFoodDto) _then) = _$ActivityFoodDtoCopyWithImpl;
@useResult
$Res call({
 int id, int accountId, String foodName, String description, int provinceId, int cityId, List<String> pictureUrl, int likesCount, bool isLiked, int createdAt, int updatedAt, String uploaderName
});




}
/// @nodoc
class _$ActivityFoodDtoCopyWithImpl<$Res>
    implements $ActivityFoodDtoCopyWith<$Res> {
  _$ActivityFoodDtoCopyWithImpl(this._self, this._then);

  final ActivityFoodDto _self;
  final $Res Function(ActivityFoodDto) _then;

/// Create a copy of ActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? foodName = null,Object? description = null,Object? provinceId = null,Object? cityId = null,Object? pictureUrl = null,Object? likesCount = null,Object? isLiked = null,Object? createdAt = null,Object? updatedAt = null,Object? uploaderName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,foodName: null == foodName ? _self.foodName : foodName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,provinceId: null == provinceId ? _self.provinceId : provinceId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,pictureUrl: null == pictureUrl ? _self.pictureUrl : pictureUrl // ignore: cast_nullable_to_non_nullable
as List<String>,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,uploaderName: null == uploaderName ? _self.uploaderName : uploaderName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityFoodDto].
extension ActivityFoodDtoPatterns on ActivityFoodDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityFoodDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityFoodDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityFoodDto value)  $default,){
final _that = this;
switch (_that) {
case _ActivityFoodDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityFoodDto value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityFoodDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int accountId,  String foodName,  String description,  int provinceId,  int cityId,  List<String> pictureUrl,  int likesCount,  bool isLiked,  int createdAt,  int updatedAt,  String uploaderName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityFoodDto() when $default != null:
return $default(_that.id,_that.accountId,_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl,_that.likesCount,_that.isLiked,_that.createdAt,_that.updatedAt,_that.uploaderName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int accountId,  String foodName,  String description,  int provinceId,  int cityId,  List<String> pictureUrl,  int likesCount,  bool isLiked,  int createdAt,  int updatedAt,  String uploaderName)  $default,) {final _that = this;
switch (_that) {
case _ActivityFoodDto():
return $default(_that.id,_that.accountId,_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl,_that.likesCount,_that.isLiked,_that.createdAt,_that.updatedAt,_that.uploaderName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int accountId,  String foodName,  String description,  int provinceId,  int cityId,  List<String> pictureUrl,  int likesCount,  bool isLiked,  int createdAt,  int updatedAt,  String uploaderName)?  $default,) {final _that = this;
switch (_that) {
case _ActivityFoodDto() when $default != null:
return $default(_that.id,_that.accountId,_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl,_that.likesCount,_that.isLiked,_that.createdAt,_that.updatedAt,_that.uploaderName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityFoodDto implements ActivityFoodDto {
  const _ActivityFoodDto({required this.id, required this.accountId, required this.foodName, required this.description, required this.provinceId, required this.cityId, required final  List<String> pictureUrl, required this.likesCount, required this.isLiked, required this.createdAt, required this.updatedAt, required this.uploaderName}): _pictureUrl = pictureUrl;
  factory _ActivityFoodDto.fromJson(Map<String, dynamic> json) => _$ActivityFoodDtoFromJson(json);

@override final  int id;
@override final  int accountId;
@override final  String foodName;
@override final  String description;
@override final  int provinceId;
@override final  int cityId;
 final  List<String> _pictureUrl;
@override List<String> get pictureUrl {
  if (_pictureUrl is EqualUnmodifiableListView) return _pictureUrl;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pictureUrl);
}

@override final  int likesCount;
@override final  bool isLiked;
@override final  int createdAt;
@override final  int updatedAt;
@override final  String uploaderName;

/// Create a copy of ActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityFoodDtoCopyWith<_ActivityFoodDto> get copyWith => __$ActivityFoodDtoCopyWithImpl<_ActivityFoodDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityFoodDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityFoodDto&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.description, description) || other.description == description)&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other._pictureUrl, _pictureUrl)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.uploaderName, uploaderName) || other.uploaderName == uploaderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountId,foodName,description,provinceId,cityId,const DeepCollectionEquality().hash(_pictureUrl),likesCount,isLiked,createdAt,updatedAt,uploaderName);

@override
String toString() {
  return 'ActivityFoodDto(id: $id, accountId: $accountId, foodName: $foodName, description: $description, provinceId: $provinceId, cityId: $cityId, pictureUrl: $pictureUrl, likesCount: $likesCount, isLiked: $isLiked, createdAt: $createdAt, updatedAt: $updatedAt, uploaderName: $uploaderName)';
}


}

/// @nodoc
abstract mixin class _$ActivityFoodDtoCopyWith<$Res> implements $ActivityFoodDtoCopyWith<$Res> {
  factory _$ActivityFoodDtoCopyWith(_ActivityFoodDto value, $Res Function(_ActivityFoodDto) _then) = __$ActivityFoodDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, int accountId, String foodName, String description, int provinceId, int cityId, List<String> pictureUrl, int likesCount, bool isLiked, int createdAt, int updatedAt, String uploaderName
});




}
/// @nodoc
class __$ActivityFoodDtoCopyWithImpl<$Res>
    implements _$ActivityFoodDtoCopyWith<$Res> {
  __$ActivityFoodDtoCopyWithImpl(this._self, this._then);

  final _ActivityFoodDto _self;
  final $Res Function(_ActivityFoodDto) _then;

/// Create a copy of ActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? foodName = null,Object? description = null,Object? provinceId = null,Object? cityId = null,Object? pictureUrl = null,Object? likesCount = null,Object? isLiked = null,Object? createdAt = null,Object? updatedAt = null,Object? uploaderName = null,}) {
  return _then(_ActivityFoodDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,foodName: null == foodName ? _self.foodName : foodName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,provinceId: null == provinceId ? _self.provinceId : provinceId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,pictureUrl: null == pictureUrl ? _self._pictureUrl : pictureUrl // ignore: cast_nullable_to_non_nullable
as List<String>,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,uploaderName: null == uploaderName ? _self.uploaderName : uploaderName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
