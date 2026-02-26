// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_activity_food_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateActivityFoodDto {

 String get foodName; String? get description; int get provinceId; int get cityId; List<String> get pictureUrl;
/// Create a copy of CreateActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateActivityFoodDtoCopyWith<CreateActivityFoodDto> get copyWith => _$CreateActivityFoodDtoCopyWithImpl<CreateActivityFoodDto>(this as CreateActivityFoodDto, _$identity);

  /// Serializes this CreateActivityFoodDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateActivityFoodDto&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.description, description) || other.description == description)&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other.pictureUrl, pictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,foodName,description,provinceId,cityId,const DeepCollectionEquality().hash(pictureUrl));

@override
String toString() {
  return 'CreateActivityFoodDto(foodName: $foodName, description: $description, provinceId: $provinceId, cityId: $cityId, pictureUrl: $pictureUrl)';
}


}

/// @nodoc
abstract mixin class $CreateActivityFoodDtoCopyWith<$Res>  {
  factory $CreateActivityFoodDtoCopyWith(CreateActivityFoodDto value, $Res Function(CreateActivityFoodDto) _then) = _$CreateActivityFoodDtoCopyWithImpl;
@useResult
$Res call({
 String foodName, String? description, int provinceId, int cityId, List<String> pictureUrl
});




}
/// @nodoc
class _$CreateActivityFoodDtoCopyWithImpl<$Res>
    implements $CreateActivityFoodDtoCopyWith<$Res> {
  _$CreateActivityFoodDtoCopyWithImpl(this._self, this._then);

  final CreateActivityFoodDto _self;
  final $Res Function(CreateActivityFoodDto) _then;

/// Create a copy of CreateActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? foodName = null,Object? description = freezed,Object? provinceId = null,Object? cityId = null,Object? pictureUrl = null,}) {
  return _then(_self.copyWith(
foodName: null == foodName ? _self.foodName : foodName // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,provinceId: null == provinceId ? _self.provinceId : provinceId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,pictureUrl: null == pictureUrl ? _self.pictureUrl : pictureUrl // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateActivityFoodDto].
extension CreateActivityFoodDtoPatterns on CreateActivityFoodDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateActivityFoodDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateActivityFoodDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateActivityFoodDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateActivityFoodDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateActivityFoodDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateActivityFoodDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String foodName,  String? description,  int provinceId,  int cityId,  List<String> pictureUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateActivityFoodDto() when $default != null:
return $default(_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String foodName,  String? description,  int provinceId,  int cityId,  List<String> pictureUrl)  $default,) {final _that = this;
switch (_that) {
case _CreateActivityFoodDto():
return $default(_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String foodName,  String? description,  int provinceId,  int cityId,  List<String> pictureUrl)?  $default,) {final _that = this;
switch (_that) {
case _CreateActivityFoodDto() when $default != null:
return $default(_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateActivityFoodDto implements CreateActivityFoodDto {
  const _CreateActivityFoodDto({required this.foodName, this.description, required this.provinceId, required this.cityId, required final  List<String> pictureUrl}): _pictureUrl = pictureUrl;
  factory _CreateActivityFoodDto.fromJson(Map<String, dynamic> json) => _$CreateActivityFoodDtoFromJson(json);

@override final  String foodName;
@override final  String? description;
@override final  int provinceId;
@override final  int cityId;
 final  List<String> _pictureUrl;
@override List<String> get pictureUrl {
  if (_pictureUrl is EqualUnmodifiableListView) return _pictureUrl;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pictureUrl);
}


/// Create a copy of CreateActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateActivityFoodDtoCopyWith<_CreateActivityFoodDto> get copyWith => __$CreateActivityFoodDtoCopyWithImpl<_CreateActivityFoodDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateActivityFoodDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateActivityFoodDto&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.description, description) || other.description == description)&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other._pictureUrl, _pictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,foodName,description,provinceId,cityId,const DeepCollectionEquality().hash(_pictureUrl));

@override
String toString() {
  return 'CreateActivityFoodDto(foodName: $foodName, description: $description, provinceId: $provinceId, cityId: $cityId, pictureUrl: $pictureUrl)';
}


}

/// @nodoc
abstract mixin class _$CreateActivityFoodDtoCopyWith<$Res> implements $CreateActivityFoodDtoCopyWith<$Res> {
  factory _$CreateActivityFoodDtoCopyWith(_CreateActivityFoodDto value, $Res Function(_CreateActivityFoodDto) _then) = __$CreateActivityFoodDtoCopyWithImpl;
@override @useResult
$Res call({
 String foodName, String? description, int provinceId, int cityId, List<String> pictureUrl
});




}
/// @nodoc
class __$CreateActivityFoodDtoCopyWithImpl<$Res>
    implements _$CreateActivityFoodDtoCopyWith<$Res> {
  __$CreateActivityFoodDtoCopyWithImpl(this._self, this._then);

  final _CreateActivityFoodDto _self;
  final $Res Function(_CreateActivityFoodDto) _then;

/// Create a copy of CreateActivityFoodDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? foodName = null,Object? description = freezed,Object? provinceId = null,Object? cityId = null,Object? pictureUrl = null,}) {
  return _then(_CreateActivityFoodDto(
foodName: null == foodName ? _self.foodName : foodName // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,provinceId: null == provinceId ? _self.provinceId : provinceId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,pictureUrl: null == pictureUrl ? _self._pictureUrl : pictureUrl // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
