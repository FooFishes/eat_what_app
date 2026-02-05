// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  userName: json['userName'] as String,
  avatar: json['avatar'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  verified: json['verified'] as bool,
  method: json['method'] as String,
  studentId: json['studentId'] as String,
  realName: json['realName'] as String,
  verifiedEmail: json['verifiedEmail'] as String,
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num).toInt(),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'userName': instance.userName,
  'avatar': instance.avatar,
  'email': instance.email,
  'phone': instance.phone,
  'verified': instance.verified,
  'method': instance.method,
  'studentId': instance.studentId,
  'realName': instance.realName,
  'verifiedEmail': instance.verifiedEmail,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
