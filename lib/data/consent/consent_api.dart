import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_api.g.dart';

/// 接口分组 AccountConsent: 跨站同步同意.
///
/// 产品默认替所有用户同意, 因此客户端只对接读取政策版本和同意两个接口, 不对接状态查询和撤回.
class ConsentApi {
  ConsentApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /auth/consent/policy',
    'POST /auth/consent/grant',
  ];

  /// 当前政策的版本号. 同意和注册都需要携带.
  Future<String> policyVersion() async {
    final policy = decodeJson(
      await _client.get('/auth/consent/policy'),
      ConsentPolicyDto.fromJson,
    );
    final version = policy.version;
    if (version == null || version.isEmpty) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no policy');
    }
    return version;
  }

  /// 带 [proof] 时无需登录, [proof] 是登录返回的临时凭证. 不带时使用当前会话同意.
  ///
  /// 本接口收到要求同意的业务码时不再自动同意, 否则会无限循环.
  Future<void> grant({required String policyVersion, String? proof}) =>
      _client.post(
        '/auth/consent/grant',
        body: {'policyVersion': policyVersion, 'proof': ?proof},
        consentRetry: false,
      );
}

@JsonSerializable(createToJson: false)
class const ConsentPolicyDto({final String? version, final String? url}) {
  factory ConsentPolicyDto.fromJson(Map<String, dynamic> json) =>
      _$ConsentPolicyDtoFromJson(json);
}

@Riverpod(keepAlive: true)
ConsentApi consentApi(Ref ref) => ConsentApi(ref.watch(apiClientProvider));
