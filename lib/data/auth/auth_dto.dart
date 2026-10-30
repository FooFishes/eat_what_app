import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

/// 登录接口的 `data`（`AuthReply`、`PhoneLoginReply`）。
///
/// 只有 `tokenName`、`tokenValue` 都有值才算登录成功；只带 [consentProof] 时要先同意再重新登录
/// （技术架构 9.5）。
@JsonSerializable(createToJson: false)
class const LoginReplyDto({
  final String? tokenName,
  final String? tokenValue,
  final bool? isLogin,
  final bool? newUser,
  final String? consentProof,
  final String? status,
}) {
  factory LoginReplyDto.fromJson(Map<String, dynamic> json) =>
      _$LoginReplyDtoFromJson(json);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class const PhoneLoginRequestDto({
  required final String mobile,
  required final String code,
  required final String device,
  final bool? crossBorderConsent,
  final String? consentPolicyVersion,
}) {
  Map<String, dynamic> toJson() => _$PhoneLoginRequestDtoToJson(this);
}

@JsonSerializable(createFactory: false)
class const PasswordLoginRequestDto({
  required final String userName,
  required final String password,
  required final String device,
}) {
  Map<String, dynamic> toJson() => _$PasswordLoginRequestDtoToJson(this);
}

/// `/auth/captcha/config` 的 `data`。[enabled] 为 false 时其余字段都是 null，跳过人机验证。
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

/// `/auth/sdu` 的 `data`：带一次性 state 的统一认证地址，[expiresIn] 秒内有效、只能用一次。
@JsonSerializable(createToJson: false)
class const SsoStartDto({final String? url, final int? expiresIn}) {
  factory SsoStartDto.fromJson(Map<String, dynamic> json) =>
      _$SsoStartDtoFromJson(json);
}
