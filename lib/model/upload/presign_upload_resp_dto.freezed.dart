// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presign_upload_resp_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PresignUploadRespDto {

 String? get putUrl; String? get key; int? get expireAt;
/// Create a copy of PresignUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignUploadRespDtoCopyWith<PresignUploadRespDto> get copyWith => _$PresignUploadRespDtoCopyWithImpl<PresignUploadRespDto>(this as PresignUploadRespDto, _$identity);

  /// Serializes this PresignUploadRespDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignUploadRespDto&&(identical(other.putUrl, putUrl) || other.putUrl == putUrl)&&(identical(other.key, key) || other.key == key)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,putUrl,key,expireAt);

@override
String toString() {
  return 'PresignUploadRespDto(putUrl: $putUrl, key: $key, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class $PresignUploadRespDtoCopyWith<$Res>  {
  factory $PresignUploadRespDtoCopyWith(PresignUploadRespDto value, $Res Function(PresignUploadRespDto) _then) = _$PresignUploadRespDtoCopyWithImpl;
@useResult
$Res call({
 String? putUrl, String? key, int? expireAt
});




}
/// @nodoc
class _$PresignUploadRespDtoCopyWithImpl<$Res>
    implements $PresignUploadRespDtoCopyWith<$Res> {
  _$PresignUploadRespDtoCopyWithImpl(this._self, this._then);

  final PresignUploadRespDto _self;
  final $Res Function(PresignUploadRespDto) _then;

/// Create a copy of PresignUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? putUrl = freezed,Object? key = freezed,Object? expireAt = freezed,}) {
  return _then(_self.copyWith(
putUrl: freezed == putUrl ? _self.putUrl : putUrl // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignUploadRespDto].
extension PresignUploadRespDtoPatterns on PresignUploadRespDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignUploadRespDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignUploadRespDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignUploadRespDto value)  $default,){
final _that = this;
switch (_that) {
case _PresignUploadRespDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignUploadRespDto value)?  $default,){
final _that = this;
switch (_that) {
case _PresignUploadRespDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? putUrl,  String? key,  int? expireAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignUploadRespDto() when $default != null:
return $default(_that.putUrl,_that.key,_that.expireAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? putUrl,  String? key,  int? expireAt)  $default,) {final _that = this;
switch (_that) {
case _PresignUploadRespDto():
return $default(_that.putUrl,_that.key,_that.expireAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? putUrl,  String? key,  int? expireAt)?  $default,) {final _that = this;
switch (_that) {
case _PresignUploadRespDto() when $default != null:
return $default(_that.putUrl,_that.key,_that.expireAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignUploadRespDto implements PresignUploadRespDto {
  const _PresignUploadRespDto({this.putUrl, this.key, this.expireAt});
  factory _PresignUploadRespDto.fromJson(Map<String, dynamic> json) => _$PresignUploadRespDtoFromJson(json);

@override final  String? putUrl;
@override final  String? key;
@override final  int? expireAt;

/// Create a copy of PresignUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignUploadRespDtoCopyWith<_PresignUploadRespDto> get copyWith => __$PresignUploadRespDtoCopyWithImpl<_PresignUploadRespDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignUploadRespDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignUploadRespDto&&(identical(other.putUrl, putUrl) || other.putUrl == putUrl)&&(identical(other.key, key) || other.key == key)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,putUrl,key,expireAt);

@override
String toString() {
  return 'PresignUploadRespDto(putUrl: $putUrl, key: $key, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class _$PresignUploadRespDtoCopyWith<$Res> implements $PresignUploadRespDtoCopyWith<$Res> {
  factory _$PresignUploadRespDtoCopyWith(_PresignUploadRespDto value, $Res Function(_PresignUploadRespDto) _then) = __$PresignUploadRespDtoCopyWithImpl;
@override @useResult
$Res call({
 String? putUrl, String? key, int? expireAt
});




}
/// @nodoc
class __$PresignUploadRespDtoCopyWithImpl<$Res>
    implements _$PresignUploadRespDtoCopyWith<$Res> {
  __$PresignUploadRespDtoCopyWithImpl(this._self, this._then);

  final _PresignUploadRespDto _self;
  final $Res Function(_PresignUploadRespDto) _then;

/// Create a copy of PresignUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? putUrl = freezed,Object? key = freezed,Object? expireAt = freezed,}) {
  return _then(_PresignUploadRespDto(
putUrl: freezed == putUrl ? _self.putUrl : putUrl // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
