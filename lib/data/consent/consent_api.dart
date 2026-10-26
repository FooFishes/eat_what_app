import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_api.g.dart';

/// 接口分组 AccountConsent：跨站同步同意。
///
/// 产品上默认替所有用户同意，客户端只接读政策版本和同意两个接口，查询状态、撤回都不接
/// （技术架构 9.5）。
class ConsentApi {
  ConsentApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /auth/consent/policy',
    'POST /auth/consent/grant',
  ];

  /// 当前政策的版本号。同意和注册都要带上它。
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

  /// 带 [proof] 时不需要登录（登录返回了临时凭证）；不带时用当前会话同意。
  ///
  /// 同意接口自己遇到「需要同意」的码不再自动同意，否则会一直绕圈。
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
