import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

/// 登录接口的 `data` (`SaTokenInfo`). `tokenName` 和 `tokenValue` 都有值才算登录成功.
@JsonSerializable(createToJson: false)
class const LoginReplyDto({
  final String? tokenName,
  final String? tokenValue,

  // TODO: 后端登录响应没有 newUser, 新号码注册后不进认证引导. 后端在验证码登录的响应中加上 newUser 后删除本 TODO.
  /// 本次验证码登录是否自动注册了新号码.
  final bool? newUser,
}) {
  factory LoginReplyDto.fromJson(Map<String, dynamic> json) =>
      _$LoginReplyDtoFromJson(json);
}

/// [policyVersion] 是用户同意的隐私政策版本. 服务端还没发布政策时为 null, 不带该字段.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const PhoneLoginRequestDto({
  required final String mobile,
  required final String code,
  required final String device,
  final String? policyVersion,
}) {
  Map<String, dynamic> toJson() => _$PhoneLoginRequestDtoToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class const PasswordLoginRequestDto({
  required final String userName,
  required final String password,
  required final String device,
  final String? policyVersion,
}) {
  Map<String, dynamic> toJson() => _$PasswordLoginRequestDtoToJson(this);
}

/// `/auth/captcha/config` 的 `data`. [enabled] 为 false 时其余字段均为 null, 跳过人机验证.
@JsonSerializable(createToJson: false)
class const CaptchaConfigDto({
  final bool? enabled,
  final String? appId,
  final String? scriptUrl,
  final String? aidEncrypted,
  final String? aidEncryptedType,
  final int? expiresAt,
}) {
  factory CaptchaConfigDto.fromJson(Map<String, dynamic> json) =>
      _$CaptchaConfigDtoFromJson(json);
}

/// `/auth/sdu` 的 `data`: 带一次性 state 的统一认证地址, 在 [expiresIn] 秒内有效且只能使用一次.
@JsonSerializable(createToJson: false)
class const SsoStartDto({final String? url, final int? expiresIn}) {
  factory SsoStartDto.fromJson(Map<String, dynamic> json) =>
      _$SsoStartDtoFromJson(json);
}
