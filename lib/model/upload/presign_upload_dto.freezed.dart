// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presign_upload_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PresignUploadRespDTO {

 String get putUrl; String get key; int get expireAt;
/// Create a copy of PresignUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignUploadRespDTOCopyWith<PresignUploadRespDTO> get copyWith => _$PresignUploadRespDTOCopyWithImpl<PresignUploadRespDTO>(this as PresignUploadRespDTO, _$identity);

  /// Serializes this PresignUploadRespDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignUploadRespDTO&&(identical(other.putUrl, putUrl) || other.putUrl == putUrl)&&(identical(other.key, key) || other.key == key)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,putUrl,key,expireAt);

@override
String toString() {
  return 'PresignUploadRespDTO(putUrl: $putUrl, key: $key, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class $PresignUploadRespDTOCopyWith<$Res>  {
  factory $PresignUploadRespDTOCopyWith(PresignUploadRespDTO value, $Res Function(PresignUploadRespDTO) _then) = _$PresignUploadRespDTOCopyWithImpl;
@useResult
$Res call({
 String putUrl, String key, int expireAt
});




}
/// @nodoc
class _$PresignUploadRespDTOCopyWithImpl<$Res>
    implements $PresignUploadRespDTOCopyWith<$Res> {
  _$PresignUploadRespDTOCopyWithImpl(this._self, this._then);

  final PresignUploadRespDTO _self;
  final $Res Function(PresignUploadRespDTO) _then;

/// Create a copy of PresignUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? putUrl = null,Object? key = null,Object? expireAt = null,}) {
  return _then(_self.copyWith(
putUrl: null == putUrl ? _self.putUrl : putUrl // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,expireAt: null == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignUploadRespDTO].
extension PresignUploadRespDTOPatterns on PresignUploadRespDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignUploadRespDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignUploadRespDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignUploadRespDTO value)  $default,){
final _that = this;
switch (_that) {
case _PresignUploadRespDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignUploadRespDTO value)?  $default,){
final _that = this;
switch (_that) {
case _PresignUploadRespDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String putUrl,  String key,  int expireAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignUploadRespDTO() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String putUrl,  String key,  int expireAt)  $default,) {final _that = this;
switch (_that) {
case _PresignUploadRespDTO():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String putUrl,  String key,  int expireAt)?  $default,) {final _that = this;
switch (_that) {
case _PresignUploadRespDTO() when $default != null:
return $default(_that.putUrl,_that.key,_that.expireAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignUploadRespDTO implements PresignUploadRespDTO {
  const _PresignUploadRespDTO({required this.putUrl, required this.key, required this.expireAt});
  factory _PresignUploadRespDTO.fromJson(Map<String, dynamic> json) => _$PresignUploadRespDTOFromJson(json);

@override final  String putUrl;
@override final  String key;
@override final  int expireAt;

/// Create a copy of PresignUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignUploadRespDTOCopyWith<_PresignUploadRespDTO> get copyWith => __$PresignUploadRespDTOCopyWithImpl<_PresignUploadRespDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignUploadRespDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignUploadRespDTO&&(identical(other.putUrl, putUrl) || other.putUrl == putUrl)&&(identical(other.key, key) || other.key == key)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,putUrl,key,expireAt);

@override
String toString() {
  return 'PresignUploadRespDTO(putUrl: $putUrl, key: $key, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class _$PresignUploadRespDTOCopyWith<$Res> implements $PresignUploadRespDTOCopyWith<$Res> {
  factory _$PresignUploadRespDTOCopyWith(_PresignUploadRespDTO value, $Res Function(_PresignUploadRespDTO) _then) = __$PresignUploadRespDTOCopyWithImpl;
@override @useResult
$Res call({
 String putUrl, String key, int expireAt
});




}
/// @nodoc
class __$PresignUploadRespDTOCopyWithImpl<$Res>
    implements _$PresignUploadRespDTOCopyWith<$Res> {
  __$PresignUploadRespDTOCopyWithImpl(this._self, this._then);

  final _PresignUploadRespDTO _self;
  final $Res Function(_PresignUploadRespDTO) _then;

/// Create a copy of PresignUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? putUrl = null,Object? key = null,Object? expireAt = null,}) {
  return _then(_PresignUploadRespDTO(
putUrl: null == putUrl ? _self.putUrl : putUrl // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,expireAt: null == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PresignBatchUploadRespDTO {

 List<PresignUploadRespDTO> get files;
/// Create a copy of PresignBatchUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignBatchUploadRespDTOCopyWith<PresignBatchUploadRespDTO> get copyWith => _$PresignBatchUploadRespDTOCopyWithImpl<PresignBatchUploadRespDTO>(this as PresignBatchUploadRespDTO, _$identity);

  /// Serializes this PresignBatchUploadRespDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignBatchUploadRespDTO&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'PresignBatchUploadRespDTO(files: $files)';
}


}

/// @nodoc
abstract mixin class $PresignBatchUploadRespDTOCopyWith<$Res>  {
  factory $PresignBatchUploadRespDTOCopyWith(PresignBatchUploadRespDTO value, $Res Function(PresignBatchUploadRespDTO) _then) = _$PresignBatchUploadRespDTOCopyWithImpl;
@useResult
$Res call({
 List<PresignUploadRespDTO> files
});




}
/// @nodoc
class _$PresignBatchUploadRespDTOCopyWithImpl<$Res>
    implements $PresignBatchUploadRespDTOCopyWith<$Res> {
  _$PresignBatchUploadRespDTOCopyWithImpl(this._self, this._then);

  final PresignBatchUploadRespDTO _self;
  final $Res Function(PresignBatchUploadRespDTO) _then;

/// Create a copy of PresignBatchUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? files = null,}) {
  return _then(_self.copyWith(
files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<PresignUploadRespDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignBatchUploadRespDTO].
extension PresignBatchUploadRespDTOPatterns on PresignBatchUploadRespDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignBatchUploadRespDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignBatchUploadRespDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignBatchUploadRespDTO value)  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadRespDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignBatchUploadRespDTO value)?  $default,){
final _that = this;
switch (_that) {
case _PresignBatchUploadRespDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PresignUploadRespDTO> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignBatchUploadRespDTO() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PresignUploadRespDTO> files)  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadRespDTO():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PresignUploadRespDTO> files)?  $default,) {final _that = this;
switch (_that) {
case _PresignBatchUploadRespDTO() when $default != null:
return $default(_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignBatchUploadRespDTO implements PresignBatchUploadRespDTO {
  const _PresignBatchUploadRespDTO({required final  List<PresignUploadRespDTO> files}): _files = files;
  factory _PresignBatchUploadRespDTO.fromJson(Map<String, dynamic> json) => _$PresignBatchUploadRespDTOFromJson(json);

 final  List<PresignUploadRespDTO> _files;
@override List<PresignUploadRespDTO> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of PresignBatchUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignBatchUploadRespDTOCopyWith<_PresignBatchUploadRespDTO> get copyWith => __$PresignBatchUploadRespDTOCopyWithImpl<_PresignBatchUploadRespDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignBatchUploadRespDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignBatchUploadRespDTO&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'PresignBatchUploadRespDTO(files: $files)';
}


}

/// @nodoc
abstract mixin class _$PresignBatchUploadRespDTOCopyWith<$Res> implements $PresignBatchUploadRespDTOCopyWith<$Res> {
  factory _$PresignBatchUploadRespDTOCopyWith(_PresignBatchUploadRespDTO value, $Res Function(_PresignBatchUploadRespDTO) _then) = __$PresignBatchUploadRespDTOCopyWithImpl;
@override @useResult
$Res call({
 List<PresignUploadRespDTO> files
});




}
/// @nodoc
class __$PresignBatchUploadRespDTOCopyWithImpl<$Res>
    implements _$PresignBatchUploadRespDTOCopyWith<$Res> {
  __$PresignBatchUploadRespDTOCopyWithImpl(this._self, this._then);

  final _PresignBatchUploadRespDTO _self;
  final $Res Function(_PresignBatchUploadRespDTO) _then;

/// Create a copy of PresignBatchUploadRespDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(_PresignBatchUploadRespDTO(
files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<PresignUploadRespDTO>,
  ));
}


}

// dart format on
