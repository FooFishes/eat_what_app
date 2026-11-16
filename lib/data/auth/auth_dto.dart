import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

/// 登录接口的 `data` (`SaTokenInfo`). 仅当 `tokenName` 和 `tokenValue` 均有值时才视为登录成功.
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

/// 手机验证码登录请求体. [policyVersion] 为用户同意的隐私政策版本, 服务端尚未发布政策时为 null 且不发送该字段.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const PhoneLoginRequestDto({
  required final String mobile,
  required final String code,
  required final String device,
  final String? policyVersion,

  /// 申请注销时保存在本机的撤销凭据. 若账号处于冷静期内, 验证码校验通过后将撤销注销.
  final String? deletionKey,
}) {
  Map<String, dynamic> toJson() => _$PhoneLoginRequestDtoToJson(this);
}

/// `/auth/phone/one-click/config` 的 `data`.
@JsonSerializable(createToJson: false)
class const OneClickConfigDto({final bool? enabled}) {
  factory OneClickConfigDto.fromJson(Map<String, dynamic> json) =>
      _$OneClickConfigDtoFromJson(json);
}

/// 一键登录请求体. [accessToken] 为号码认证 SDK 在用户授权后返回的取号凭证, 服务端凭其向阿里云换取手机号.
///
/// [policyVersion] 同 [PhoneLoginRequestDto.policyVersion].
@JsonSerializable(createFactory: false, includeIfNull: false)
class const OneClickLoginRequestDto({
  required final String accessToken,
  final String? policyVersion,
}) {
  Map<String, dynamic> toJson() => _$OneClickLoginRequestDtoToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class const PasswordLoginRequestDto({
  required final String userName,
  required final String password,
  required final String device,
  final String? policyVersion,

  /// 同 [PhoneLoginRequestDto.deletionKey].
  final String? deletionKey,
}) {
  Map<String, dynamic> toJson() => _$PasswordLoginRequestDtoToJson(this);
}

/// `/auth/captcha/config` 的 `data`. 当 [enabled] 为 false 时其余字段均为 null, 客户端跳过人机验证.
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

/// `/auth/sdu` 的 `data`, 包含带一次性 state 的统一认证地址, 在 [expiresIn] 秒内有效且仅能使用一次.
@JsonSerializable(createToJson: false)
class const SsoStartDto({final String? url, final int? expiresIn}) {
  factory SsoStartDto.fromJson(Map<String, dynamic> json) =>
      _$SsoStartDtoFromJson(json);
}
