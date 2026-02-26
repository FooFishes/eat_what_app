// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presign_batch_upload_resp_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PresignBatchUploadRespDto {

 List<PresignUploadRespDto>? get files;
/// Create a copy of PresignBatchUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignBatchUploadRespDtoCopyWith<PresignBatchUploadRespDto> get copyWith => _$PresignBatchUploadRespDtoCopyWithImpl<PresignBatchUploadRespDto>(this as PresignBatchUploadRespDto, _$identity);

  /// Serializes this PresignBatchUploadRespDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignBatchUploadRespDto&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'PresignBatchUploadRespDto(files: $files)';
}


}

/// @nodoc
abstract mixin class $PresignBatchUploadRespDtoCopyWith<$Res>  {
  factory $PresignBatchUploadRespDtoCopyWith(PresignBatchUploadRespDto value, $Res Function(PresignBatchUploadRespDto) _then) = _$PresignBatchUploadRespDtoCopyWithImpl;
@useResult
$Res call({
 List<PresignUploadRespDto>? files
});




}
/// @nodoc
class _$PresignBatchUploadRespDtoCopyWithImpl<$Res>
    implements $PresignBatchUploadRespDtoCopyWith<$Res> {
  _$PresignBatchUploadRespDtoCopyWithImpl(this._self, this._then);

  final PresignBatchUploadRespDto _self;
  final $Res Function(PresignBatchUploadRespDto) _then;

/// Create a copy of PresignBatchUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? files = freezed,}) {
  return _then(_self.copyWith(
files: freezed == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<PresignUploadRespDto>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignBatchUploadRespDto].
extension PresignBatchUploadRespDtoPatterns on PresignBatchUploadRespDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignBatchUploadRespDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignBatchUploadRespDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignBatchUploadRespDto value)  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadRespDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignBatchUploadRespDto value)?  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadRespDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PresignUploadRespDto>? files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignBatchUploadRespDto() when $default != null:
return $default(_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PresignUploadRespDto>? files)  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadRespDto():
return $default(_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PresignUploadRespDto>? files)?  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadRespDto() when $default != null:
return $default(_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignBatchUploadRespDto implements PresignBatchUploadRespDto {
  const _PresignBatchUploadRespDto({final  List<PresignUploadRespDto>? files}): _files = files;
  factory _PresignBatchUploadRespDto.fromJson(Map<String, dynamic> json) => _$PresignBatchUploadRespDtoFromJson(json);

 final  List<PresignUploadRespDto>? _files;
@override List<PresignUploadRespDto>? get files {
  final value = _files;
  if (value == null) return null;
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of PresignBatchUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignBatchUploadRespDtoCopyWith<_PresignBatchUploadRespDto> get copyWith => __$PresignBatchUploadRespDtoCopyWithImpl<_PresignBatchUploadRespDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignBatchUploadRespDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignBatchUploadRespDto&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'PresignBatchUploadRespDto(files: $files)';
}


}

/// @nodoc
abstract mixin class _$PresignBatchUploadRespDtoCopyWith<$Res> implements $PresignBatchUploadRespDtoCopyWith<$Res> {
  factory _$PresignBatchUploadRespDtoCopyWith(_PresignBatchUploadRespDto value, $Res Function(_PresignBatchUploadRespDto) _then) = __$PresignBatchUploadRespDtoCopyWithImpl;
@override @useResult
$Res call({
 List<PresignUploadRespDto>? files
});




}
/// @nodoc
class __$PresignBatchUploadRespDtoCopyWithImpl<$Res>
    implements _$PresignBatchUploadRespDtoCopyWith<$Res> {
  __$PresignBatchUploadRespDtoCopyWithImpl(this._self, this._then);

  final _PresignBatchUploadRespDto _self;
  final $Res Function(_PresignBatchUploadRespDto) _then;

/// Create a copy of PresignBatchUploadRespDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? files = freezed,}) {
  return _then(_PresignBatchUploadRespDto(
files: freezed == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<PresignUploadRespDto>?,
  ));
}


}

// dart format on
