// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presign_batch_upload_file_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PresignBatchUploadFileDto {

 String get fileName; String get contentType; int get fileSize;
/// Create a copy of PresignBatchUploadFileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignBatchUploadFileDtoCopyWith<PresignBatchUploadFileDto> get copyWith => _$PresignBatchUploadFileDtoCopyWithImpl<PresignBatchUploadFileDto>(this as PresignBatchUploadFileDto, _$identity);

  /// Serializes this PresignBatchUploadFileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignBatchUploadFileDto&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,contentType,fileSize);

@override
String toString() {
  return 'PresignBatchUploadFileDto(fileName: $fileName, contentType: $contentType, fileSize: $fileSize)';
}


}

/// @nodoc
abstract mixin class $PresignBatchUploadFileDtoCopyWith<$Res>  {
  factory $PresignBatchUploadFileDtoCopyWith(PresignBatchUploadFileDto value, $Res Function(PresignBatchUploadFileDto) _then) = _$PresignBatchUploadFileDtoCopyWithImpl;
@useResult
$Res call({
 String fileName, String contentType, int fileSize
});




}
/// @nodoc
class _$PresignBatchUploadFileDtoCopyWithImpl<$Res>
    implements $PresignBatchUploadFileDtoCopyWith<$Res> {
  _$PresignBatchUploadFileDtoCopyWithImpl(this._self, this._then);

  final PresignBatchUploadFileDto _self;
  final $Res Function(PresignBatchUploadFileDto) _then;

/// Create a copy of PresignBatchUploadFileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? contentType = null,Object? fileSize = null,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignBatchUploadFileDto].
extension PresignBatchUploadFileDtoPatterns on PresignBatchUploadFileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignBatchUploadFileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignBatchUploadFileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignBatchUploadFileDto value)  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadFileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignBatchUploadFileDto value)?  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadFileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String contentType,  int fileSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignBatchUploadFileDto() when $default != null:
return $default(_that.fileName,_that.contentType,_that.fileSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String contentType,  int fileSize)  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadFileDto():
return $default(_that.fileName,_that.contentType,_that.fileSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String contentType,  int fileSize)?  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadFileDto() when $default != null:
return $default(_that.fileName,_that.contentType,_that.fileSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignBatchUploadFileDto implements PresignBatchUploadFileDto {
  const _PresignBatchUploadFileDto({required this.fileName, required this.contentType, required this.fileSize});
  factory _PresignBatchUploadFileDto.fromJson(Map<String, dynamic> json) => _$PresignBatchUploadFileDtoFromJson(json);

@override final  String fileName;
@override final  String contentType;
@override final  int fileSize;

/// Create a copy of PresignBatchUploadFileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignBatchUploadFileDtoCopyWith<_PresignBatchUploadFileDto> get copyWith => __$PresignBatchUploadFileDtoCopyWithImpl<_PresignBatchUploadFileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignBatchUploadFileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignBatchUploadFileDto&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,contentType,fileSize);

@override
String toString() {
  return 'PresignBatchUploadFileDto(fileName: $fileName, contentType: $contentType, fileSize: $fileSize)';
}


}

/// @nodoc
abstract mixin class _$PresignBatchUploadFileDtoCopyWith<$Res> implements $PresignBatchUploadFileDtoCopyWith<$Res> {
  factory _$PresignBatchUploadFileDtoCopyWith(_PresignBatchUploadFileDto value, $Res Function(_PresignBatchUploadFileDto) _then) = __$PresignBatchUploadFileDtoCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String contentType, int fileSize
});




}
/// @nodoc
class __$PresignBatchUploadFileDtoCopyWithImpl<$Res>
    implements _$PresignBatchUploadFileDtoCopyWith<$Res> {
  __$PresignBatchUploadFileDtoCopyWithImpl(this._self, this._then);

  final _PresignBatchUploadFileDto _self;
  final $Res Function(_PresignBatchUploadFileDto) _then;

/// Create a copy of PresignBatchUploadFileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? contentType = null,Object? fileSize = null,}) {
  return _then(_PresignBatchUploadFileDto(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
