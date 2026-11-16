// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginReplyDto _$LoginReplyDtoFromJson(Map<String, dynamic> json) =>
    LoginReplyDto(
      tokenName: json['tokenName'] as String?,
      tokenValue: json['tokenValue'] as String?,
      newUser: json['newUser'] as bool?,
    );

Map<String, dynamic> _$PhoneLoginRequestDtoToJson(
  PhoneLoginRequestDto instance,
) => <String, dynamic>{
  'mobile': instance.mobile,
  'code': instance.code,
  'device': instance.device,
  'policyVersion': ?instance.policyVersion,
  'deletionKey': ?instance.deletionKey,
  'installId': ?instance.installId,
};

OneClickConfigDto _$OneClickConfigDtoFromJson(Map<String, dynamic> json) =>
    OneClickConfigDto(enabled: json['enabled'] as bool?);

Map<String, dynamic> _$OneClickLoginRequestDtoToJson(
  OneClickLoginRequestDto instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'policyVersion': ?instance.policyVersion,
  'installId': ?instance.installId,
};

Map<String, dynamic> _$PasswordLoginRequestDtoToJson(
  PasswordLoginRequestDto instance,
) => <String, dynamic>{
  'userName': instance.userName,
  'password': instance.password,
  'device': instance.device,
  'policyVersion': ?instance.policyVersion,
  'deletionKey': ?instance.deletionKey,
  'installId': ?instance.installId,
};

CaptchaConfigDto _$CaptchaConfigDtoFromJson(Map<String, dynamic> json) =>
    CaptchaConfigDto(
      enabled: json['enabled'] as bool?,
      appId: json['appId'] as String?,
      scriptUrl: json['scriptUrl'] as String?,
      aidEncrypted: json['aidEncrypted'] as String?,
      aidEncryptedType: json['aidEncryptedType'] as String?,
      expiresAt: (json['expiresAt'] as num?)?.toInt(),
    );

SsoStartDto _$SsoStartDtoFromJson(Map<String, dynamic> json) => SsoStartDto(
  url: json['url'] as String?,
  expiresIn: (json['expiresIn'] as num?)?.toInt(),
);
