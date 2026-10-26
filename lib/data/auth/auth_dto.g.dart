// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginReplyDto _$LoginReplyDtoFromJson(Map<String, dynamic> json) =>
    LoginReplyDto(
      tokenName: json['tokenName'] as String?,
      tokenValue: json['tokenValue'] as String?,
      isLogin: json['isLogin'] as bool?,
      newUser: json['newUser'] as bool?,
      consentProof: json['consentProof'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$PhoneLoginRequestDtoToJson(
  PhoneLoginRequestDto instance,
) => <String, dynamic>{
  'mobile': instance.mobile,
  'code': instance.code,
  'device': instance.device,
  'crossBorderConsent': ?instance.crossBorderConsent,
  'consentPolicyVersion': ?instance.consentPolicyVersion,
};

Map<String, dynamic> _$PasswordLoginRequestDtoToJson(
  PasswordLoginRequestDto instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'device': instance.device,
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
