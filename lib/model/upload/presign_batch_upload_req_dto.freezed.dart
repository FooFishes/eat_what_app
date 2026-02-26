// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presign_batch_upload_req_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PresignBatchUploadReqDto {

 String? get biz; List<PresignBatchUploadFileDto> get files;
/// Create a copy of PresignBatchUploadReqDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignBatchUploadReqDtoCopyWith<PresignBatchUploadReqDto> get copyWith => _$PresignBatchUploadReqDtoCopyWithImpl<PresignBatchUploadReqDto>(this as PresignBatchUploadReqDto, _$identity);

  /// Serializes this PresignBatchUploadReqDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignBatchUploadReqDto&&(identical(other.biz, biz) || other.biz == biz)&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,biz,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'PresignBatchUploadReqDto(biz: $biz, files: $files)';
}


}

/// @nodoc
abstract mixin class $PresignBatchUploadReqDtoCopyWith<$Res>  {
  factory $PresignBatchUploadReqDtoCopyWith(PresignBatchUploadReqDto value, $Res Function(PresignBatchUploadReqDto) _then) = _$PresignBatchUploadReqDtoCopyWithImpl;
@useResult
$Res call({
 String? biz, List<PresignBatchUploadFileDto> files
});




}
/// @nodoc
class _$PresignBatchUploadReqDtoCopyWithImpl<$Res>
    implements $PresignBatchUploadReqDtoCopyWith<$Res> {
  _$PresignBatchUploadReqDtoCopyWithImpl(this._self, this._then);

  final PresignBatchUploadReqDto _self;
  final $Res Function(PresignBatchUploadReqDto) _then;

/// Create a copy of PresignBatchUploadReqDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? biz = freezed,Object? files = null,}) {
  return _then(_self.copyWith(
biz: freezed == biz ? _self.biz : biz // ignore: cast_nullable_to_non_nullable
as String?,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<PresignBatchUploadFileDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignBatchUploadReqDto].
extension PresignBatchUploadReqDtoPatterns on PresignBatchUploadReqDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignBatchUploadReqDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignBatchUploadReqDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignBatchUploadReqDto value)  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadReqDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignBatchUploadReqDto value)?  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadReqDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? biz,  List<PresignBatchUploadFileDto> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignBatchUploadReqDto() when $default != null:
return $default(_that.biz,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? biz,  List<PresignBatchUploadFileDto> files)  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadReqDto():
return $default(_that.biz,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? biz,  List<PresignBatchUploadFileDto> files)?  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadReqDto() when $default != null:
return $default(_that.biz,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignBatchUploadReqDto implements PresignBatchUploadReqDto {
  const _PresignBatchUploadReqDto({this.biz, required final  List<PresignBatchUploadFileDto> files}): _files = files;
  factory _PresignBatchUploadReqDto.fromJson(Map<String, dynamic> json) => _$PresignBatchUploadReqDtoFromJson(json);

@override final  String? biz;
 final  List<PresignBatchUploadFileDto> _files;
@override List<PresignBatchUploadFileDto> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of PresignBatchUploadReqDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignBatchUploadReqDtoCopyWith<_PresignBatchUploadReqDto> get copyWith => __$PresignBatchUploadReqDtoCopyWithImpl<_PresignBatchUploadReqDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignBatchUploadReqDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignBatchUploadReqDto&&(identical(other.biz, biz) || other.biz == biz)&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,biz,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'PresignBatchUploadReqDto(biz: $biz, files: $files)';
}


}

/// @nodoc
abstract mixin class _$PresignBatchUploadReqDtoCopyWith<$Res> implements $PresignBatchUploadReqDtoCopyWith<$Res> {
  factory _$PresignBatchUploadReqDtoCopyWith(_PresignBatchUploadReqDto value, $Res Function(_PresignBatchUploadReqDto) _then) = __$PresignBatchUploadReqDtoCopyWithImpl;
@override @useResult
$Res call({
 String? biz, List<PresignBatchUploadFileDto> files
});




}
/// @nodoc
class __$PresignBatchUploadReqDtoCopyWithImpl<$Res>
    implements _$PresignBatchUploadReqDtoCopyWith<$Res> {
  __$PresignBatchUploadReqDtoCopyWithImpl(this._self, this._then);

  final _PresignBatchUploadReqDto _self;
  final $Res Function(_PresignBatchUploadReqDto) _then;

/// Create a copy of PresignBatchUploadReqDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? biz = freezed,Object? files = null,}) {
  return _then(_PresignBatchUploadReqDto(
biz: freezed == biz ? _self.biz : biz // ignore: cast_nullable_to_non_nullable
as String?,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<PresignBatchUploadFileDto>,
  ));
}


}

// dart format on
