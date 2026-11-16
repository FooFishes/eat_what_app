import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_api.g.dart';

/// ConsentApi 调用的接口路径, 相对于业务接口地址.
abstract final class ConsentEndpoints {
  static const policy = '/auth/consent/policy';
  static const grant = '/auth/consent/grant';
}

/// 封装 AccountConsent 接口分组, 负责隐私政策与数据跨境说明的读取及确认提交, 两份文档共用同一版本号.
///
/// 协议确认需由用户在对话框中操作后提交. 客户端仅对接读取政策与提交确认两个接口, 不调用状态查询接口.
class ConsentApi {
  ConsentApi(this._client);

  final ApiClient _client;

  /// 获取当前政策信息, 无需登录. 若服务端尚未发布过政策, 返回的版本号为 null.
  Future<ConsentPolicyDto> policy() async => decodeJson(
    await _client.get(ConsentEndpoints.policy),
    ConsentPolicyDto.fromJson,
  );

  /// 以当前登录会话确认 [policyVersion] 版本的协议, 需在登录后调用.
  ///
  /// 本接口收到要求确认协议的业务码时不再弹窗重试, 避免触发无限循环.
  Future<void> grant({required String policyVersion}) => _client.post(
    ConsentEndpoints.grant,
    body: {'policyVersion': policyVersion},
    consentRetry: false,
  );
}

/// `/auth/consent/policy` 的 `data`.
///
/// 隐私政策, 用户协议和个人信息出境说明使用托管的网页, 因此不读取接口返回的正文 `privacyText` 和 `crossBorderText`.
@JsonSerializable(createToJson: false)
class const ConsentPolicyDto({final String? version}) {
  factory ConsentPolicyDto.fromJson(Map<String, dynamic> json) =>
      _$ConsentPolicyDtoFromJson(json);
}

@Riverpod(keepAlive: true)
ConsentApi consentApi(Ref ref) => ConsentApi(ref.watch(apiClientProvider));
