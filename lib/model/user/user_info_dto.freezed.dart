// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserInfoDto {

 int get id; String get userName; String get avatar; String get email; String get phone; bool get verified; String get method; String get studentId; String get realName; String get verifiedEmail; int get createdAt; int get updatedAt;
/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserInfoDtoCopyWith<UserInfoDto> get copyWith => _$UserInfoDtoCopyWithImpl<UserInfoDto>(this as UserInfoDto, _$identity);

  /// Serializes this UserInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserInfoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.method, method) || other.method == method)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.realName, realName) || other.realName == realName)&&(identical(other.verifiedEmail, verifiedEmail) || other.verifiedEmail == verifiedEmail)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,avatar,email,phone,verified,method,studentId,realName,verifiedEmail,createdAt,updatedAt);

@override
String toString() {
  return 'UserInfoDto(id: $id, userName: $userName, avatar: $avatar, email: $email, phone: $phone, verified: $verified, method: $method, studentId: $studentId, realName: $realName, verifiedEmail: $verifiedEmail, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserInfoDtoCopyWith<$Res>  {
  factory $UserInfoDtoCopyWith(UserInfoDto value, $Res Function(UserInfoDto) _then) = _$UserInfoDtoCopyWithImpl;
@useResult
$Res call({
 int id, String userName, String avatar, String email, String phone, bool verified, String method, String studentId, String realName, String verifiedEmail, int createdAt, int updatedAt
});




}
/// @nodoc
class _$UserInfoDtoCopyWithImpl<$Res>
    implements $UserInfoDtoCopyWith<$Res> {
  _$UserInfoDtoCopyWithImpl(this._self, this._then);

  final UserInfoDto _self;
  final $Res Function(UserInfoDto) _then;

/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userName = null,Object? avatar = null,Object? email = null,Object? phone = null,Object? verified = null,Object? method = null,Object? studentId = null,Object? realName = null,Object? verifiedEmail = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,realName: null == realName ? _self.realName : realName // ignore: cast_nullable_to_non_nullable
as String,verifiedEmail: null == verifiedEmail ? _self.verifiedEmail : verifiedEmail // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserInfoDto].
extension UserInfoDtoPatterns on UserInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _UserInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String userName,  String avatar,  String email,  String phone,  bool verified,  String method,  String studentId,  String realName,  String verifiedEmail,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
return $default(_that.id,_that.userName,_that.avatar,_that.email,_that.phone,_that.verified,_that.method,_that.studentId,_that.realName,_that.verifiedEmail,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String userName,  String avatar,  String email,  String phone,  bool verified,  String method,  String studentId,  String realName,  String verifiedEmail,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserInfoDto():
return $default(_that.id,_that.userName,_that.avatar,_that.email,_that.phone,_that.verified,_that.method,_that.studentId,_that.realName,_that.verifiedEmail,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String userName,  String avatar,  String email,  String phone,  bool verified,  String method,  String studentId,  String realName,  String verifiedEmail,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserInfoDto() when $default != null:
return $default(_that.id,_that.userName,_that.avatar,_that.email,_that.phone,_that.verified,_that.method,_that.studentId,_that.realName,_that.verifiedEmail,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserInfoDto implements UserInfoDto {
  const _UserInfoDto({required this.id, required this.userName, required this.avatar, required this.email, required this.phone, required this.verified, required this.method, required this.studentId, required this.realName, required this.verifiedEmail, required this.createdAt, required this.updatedAt});
  factory _UserInfoDto.fromJson(Map<String, dynamic> json) => _$UserInfoDtoFromJson(json);

@override final  int id;
@override final  String userName;
@override final  String avatar;
@override final  String email;
@override final  String phone;
@override final  bool verified;
@override final  String method;
@override final  String studentId;
@override final  String realName;
@override final  String verifiedEmail;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserInfoDtoCopyWith<_UserInfoDto> get copyWith => __$UserInfoDtoCopyWithImpl<_UserInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserInfoDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.method, method) || other.method == method)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.realName, realName) || other.realName == realName)&&(identical(other.verifiedEmail, verifiedEmail) || other.verifiedEmail == verifiedEmail)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,avatar,email,phone,verified,method,studentId,realName,verifiedEmail,createdAt,updatedAt);

@override
String toString() {
  return 'UserInfoDto(id: $id, userName: $userName, avatar: $avatar, email: $email, phone: $phone, verified: $verified, method: $method, studentId: $studentId, realName: $realName, verifiedEmail: $verifiedEmail, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserInfoDtoCopyWith<$Res> implements $UserInfoDtoCopyWith<$Res> {
  factory _$UserInfoDtoCopyWith(_UserInfoDto value, $Res Function(_UserInfoDto) _then) = __$UserInfoDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String userName, String avatar, String email, String phone, bool verified, String method, String studentId, String realName, String verifiedEmail, int createdAt, int updatedAt
});




}
/// @nodoc
class __$UserInfoDtoCopyWithImpl<$Res>
    implements _$UserInfoDtoCopyWith<$Res> {
  __$UserInfoDtoCopyWithImpl(this._self, this._then);

  final _UserInfoDto _self;
  final $Res Function(_UserInfoDto) _then;

/// Create a copy of UserInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userName = null,Object? avatar = null,Object? email = null,Object? phone = null,Object? verified = null,Object? method = null,Object? studentId = null,Object? realName = null,Object? verifiedEmail = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_UserInfoDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,realName: null == realName ? _self.realName : realName // ignore: cast_nullable_to_non_nullable
as String,verifiedEmail: null == verifiedEmail ? _self.verifiedEmail : verifiedEmail // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
