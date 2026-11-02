import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_api.g.dart';

/// 接口分组 AccountConsent: 跨站同步同意.
///
/// 同意由用户在同意面板中确认后提交. 客户端只对接读取政策和同意两个接口, 不对接状态查询和撤回.
class ConsentApi {
  ConsentApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /auth/consent/policy',
    'POST /auth/consent/grant',
  ];

  /// 当前政策. 版本号为空时抛出 [AppFailure]. 说明页地址可能为空.
  Future<ConsentPolicyDto> policy() async {
    final policy = decodeJson(
      await _client.get('/auth/consent/policy'),
      ConsentPolicyDto.fromJson,
    );
    if (policy.version?.isEmpty ?? true) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no policy');
    }
    return policy;
  }

  /// 当前政策的版本号. 同意和注册都需要携带.
  Future<String> policyVersion() async => (await policy()).version!;

  /// 带 [proof] 时无需登录, [proof] 是登录返回的临时凭证. 不带时使用当前会话同意.
  ///
  /// 本接口收到要求同意的业务码时不再请用户同意, 否则会无限循环.
  Future<void> grant({required String policyVersion, String? proof}) =>
      _client.post(
        '/auth/consent/grant',
        body: {'policyVersion': policyVersion, 'proof': ?proof},
        consentRetry: false,
      );
}

/// `/auth/consent/policy` 的 `data`. [url] 是政策说明页, 可能是站内绝对路径, 如 `/api/policies/x.html`.
@JsonSerializable(createToJson: false)
class const ConsentPolicyDto({final String? version, final String? url}) {
  factory ConsentPolicyDto.fromJson(Map<String, dynamic> json) =>
      _$ConsentPolicyDtoFromJson(json);
}

@Riverpod(keepAlive: true)
ConsentApi consentApi(Ref ref) => ConsentApi(ref.watch(apiClientProvider));
