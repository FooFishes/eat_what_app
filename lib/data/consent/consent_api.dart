import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_api.g.dart';

/// ConsentApi 调用的接口路径, 相对于业务接口地址.
abstract final class ConsentEndpoints {
  static const policy = '/auth/consent/policy';
  static const grant = '/auth/consent/grant';
}

/// 接口分组 AccountConsent: 隐私政策和数据跨境说明的同意. 两份文档共用一个版本号.
///
/// 同意由用户在同意对话框中确认后提交. 客户端只对接读取政策和同意两个接口, 不对接状态查询.
class ConsentApi {
  ConsentApi(this._client);

  final ApiClient _client;

  /// 当前政策. 服务端还没发布过政策时版本为 null. 不需要登录.
  Future<ConsentPolicyDto> policy() async => decodeJson(
    await _client.get(ConsentEndpoints.policy),
    ConsentPolicyDto.fromJson,
  );

  /// 用当前会话同意 [policyVersion]. 需要登录.
  ///
  /// 本接口收到要求同意的业务码时不再请用户同意, 否则会无限循环.
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
