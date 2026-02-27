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
mixin _$CreateActivityFoodDTO {

 String get foodName; String? get description; int get provinceId; int get cityId; List<String> get pictureUrl;
/// Create a copy of CreateActivityFoodDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateActivityFoodDTOCopyWith<CreateActivityFoodDTO> get copyWith => _$CreateActivityFoodDTOCopyWithImpl<CreateActivityFoodDTO>(this as CreateActivityFoodDTO, _$identity);

  /// Serializes this CreateActivityFoodDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateActivityFoodDTO&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.description, description) || other.description == description)&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other.pictureUrl, pictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,foodName,description,provinceId,cityId,const DeepCollectionEquality().hash(pictureUrl));

@override
String toString() {
  return 'CreateActivityFoodDTO(foodName: $foodName, description: $description, provinceId: $provinceId, cityId: $cityId, pictureUrl: $pictureUrl)';
}


}

/// @nodoc
abstract mixin class $CreateActivityFoodDTOCopyWith<$Res>  {
  factory $CreateActivityFoodDTOCopyWith(CreateActivityFoodDTO value, $Res Function(CreateActivityFoodDTO) _then) = _$CreateActivityFoodDTOCopyWithImpl;
@useResult
$Res call({
 String foodName, String? description, int provinceId, int cityId, List<String> pictureUrl
});




}
/// @nodoc
class _$CreateActivityFoodDTOCopyWithImpl<$Res>
    implements $CreateActivityFoodDTOCopyWith<$Res> {
  _$CreateActivityFoodDTOCopyWithImpl(this._self, this._then);

  final CreateActivityFoodDTO _self;
  final $Res Function(CreateActivityFoodDTO) _then;

/// Create a copy of CreateActivityFoodDTO
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


/// Adds pattern-matching-related methods to [CreateActivityFoodDTO].
extension CreateActivityFoodDTOPatterns on CreateActivityFoodDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateActivityFoodDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateActivityFoodDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateActivityFoodDTO value)  $default,){
final _that = this;
switch (_that) {
case _CreateActivityFoodDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateActivityFoodDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CreateActivityFoodDTO() when $default != null:
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
case _CreateActivityFoodDTO() when $default != null:
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
case _CreateActivityFoodDTO():
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
case _CreateActivityFoodDTO() when $default != null:
return $default(_that.foodName,_that.description,_that.provinceId,_that.cityId,_that.pictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateActivityFoodDTO implements CreateActivityFoodDTO {
  const _CreateActivityFoodDTO({required this.foodName, this.description, required this.provinceId, required this.cityId, required final  List<String> pictureUrl}): _pictureUrl = pictureUrl;
  factory _CreateActivityFoodDTO.fromJson(Map<String, dynamic> json) => _$CreateActivityFoodDTOFromJson(json);

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


/// Create a copy of CreateActivityFoodDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateActivityFoodDTOCopyWith<_CreateActivityFoodDTO> get copyWith => __$CreateActivityFoodDTOCopyWithImpl<_CreateActivityFoodDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateActivityFoodDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateActivityFoodDTO&&(identical(other.foodName, foodName) || other.foodName == foodName)&&(identical(other.description, description) || other.description == description)&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other._pictureUrl, _pictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,foodName,description,provinceId,cityId,const DeepCollectionEquality().hash(_pictureUrl));

@override
String toString() {
  return 'CreateActivityFoodDTO(foodName: $foodName, description: $description, provinceId: $provinceId, cityId: $cityId, pictureUrl: $pictureUrl)';
}


}

/// @nodoc
abstract mixin class _$CreateActivityFoodDTOCopyWith<$Res> implements $CreateActivityFoodDTOCopyWith<$Res> {
  factory _$CreateActivityFoodDTOCopyWith(_CreateActivityFoodDTO value, $Res Function(_CreateActivityFoodDTO) _then) = __$CreateActivityFoodDTOCopyWithImpl;
@override @useResult
$Res call({
 String foodName, String? description, int provinceId, int cityId, List<String> pictureUrl
});




}
/// @nodoc
class __$CreateActivityFoodDTOCopyWithImpl<$Res>
    implements _$CreateActivityFoodDTOCopyWith<$Res> {
  __$CreateActivityFoodDTOCopyWithImpl(this._self, this._then);

  final _CreateActivityFoodDTO _self;
  final $Res Function(_CreateActivityFoodDTO) _then;

/// Create a copy of CreateActivityFoodDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? foodName = null,Object? description = freezed,Object? provinceId = null,Object? cityId = null,Object? pictureUrl = null,}) {
  return _then(_CreateActivityFoodDTO(
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
