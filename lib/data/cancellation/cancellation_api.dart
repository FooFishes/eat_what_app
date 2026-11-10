import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancellation_api.g.dart';

/// CancellationApi 调用的接口路径, 相对于业务接口地址.
abstract final class CancellationEndpoints {
  static const request = '/user/cancellation';
  static const recoverPassword = '/user/cancellation/recover/password';
  static const recoverPhoneChallenge =
      '/user/cancellation/recover/phone/challenge';
  static const recoverPhoneVerify = '/user/cancellation/recover/phone/verify';
  static String status(String subjectId, String requestId) =>
      '/user/cancellation/$subjectId/$requestId/status';
  static String cancel(String subjectId, String requestId) =>
      '/user/cancellation/$subjectId/$requestId/cancel';
}

/// 状态和撤销接口用来传恢复凭据的请求头.
const recoveryHeader = 'X-Lifecycle-Recovery';

/// 接口分组 LifecycleCancellation: 申请注销, 冷静期内验证身份, 撤销和查询状态.
///
/// 只有申请需要登录. 其余接口凭申请时提交的恢复凭据 (`recoveryCapability`) 鉴权, 不用会话.
class CancellationApi {
  CancellationApi(this._client);

  final ApiClient _client;

  /// 申请注销. [requestId] 和 [recoveryCapability] 由客户端生成, 重试时沿用.
  ///
  /// [deletePostsAndComments] 为 true 时删除本人的评论和回复, 为 false 时匿名保留.
  /// 同一个 [requestId] 重试时不能改变这个选择.
  Future<CancellationStatusDto> request({
    required String requestId,
    required String recoveryCapability,
    required bool deletePostsAndComments,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.request,
      body: {
        'requestId': requestId,
        'recoveryCapability': recoveryCapability,
        'deletePostsAndComments': deletePostsAndComments,
      },
    ),
    CancellationStatusDto.fromJson,
  );

  Future<CancellationStatusDto> status({
    required String subjectId,
    required String requestId,
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.status(subjectId, requestId),
      headers: {recoveryHeader: recoveryCapability},
    ),
    CancellationStatusDto.fromJson,
  );

  /// 撤销注销. [credentialOperation] 是刚通过的身份验证的 `operationId`.
  Future<CancellationStatusDto> cancel({
    required String subjectId,
    required String requestId,
    required String recoveryCapability,
    required String credentialOperation,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.cancel(subjectId, requestId),
      body: {'credentialOperation': credentialOperation},
      headers: {recoveryHeader: recoveryCapability},
    ),
    CancellationStatusDto.fromJson,
  );

  /// 用密码验证身份. [identifier] 是登录时填的手机号, 用户名或邮箱.
  Future<RecoveryGrantDto> recoverWithPassword({
    required String identifier,
    required String password,
    required String subjectId,
    required String requestId,
    required String operationId,
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.recoverPassword,
      body: {
        'identifier': identifier,
        'password': password,
        'subjectId': subjectId,
        'requestId': requestId,
        'operationId': operationId,
        'recoveryCapability': recoveryCapability,
      },
    ),
    RecoveryGrantDto.fromJson,
  );

  /// 给账号绑定的手机发验证码. 同一个 [operationId] 重复调用不会再发.
  Future<RecoveryChallengeDto> sendRecoveryCode({
    required String subjectId,
    required String requestId,
    required String operationId,
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.recoverPhoneChallenge,
      body: {
        'subjectId': subjectId,
        'requestId': requestId,
        'operationId': operationId,
        'recoveryCapability': recoveryCapability,
      },
    ),
    RecoveryChallengeDto.fromJson,
  );

  /// 用验证码验证身份. [operationId] 与发码时相同.
  Future<RecoveryGrantDto> recoverWithCode({
    required String code,
    required String subjectId,
    required String requestId,
    required String operationId,
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.recoverPhoneVerify,
      body: {
        'code': code,
        'subjectId': subjectId,
        'requestId': requestId,
        'operationId': operationId,
        'recoveryCapability': recoveryCapability,
      },
    ),
    RecoveryGrantDto.fromJson,
  );
}

/// 注销申请的状态. [phase] 为 `ACTIVE`, `PREPARING`, `PENDING` 或 `FINALIZED`, [deadline] 为 ISO 8601.
@JsonSerializable(createToJson: false)
class const CancellationStatusDto({
  final String? requestId,
  final String? phase,
  final String? deadline,
  final bool? complete,
}) {
  factory CancellationStatusDto.fromJson(Map<String, dynamic> json) =>
      _$CancellationStatusDtoFromJson(json);
}

/// 身份验证通过的结果. 撤销时把 [operationId] 作为 `credentialOperation` 提交.
@JsonSerializable(createToJson: false)
class const RecoveryGrantDto({final String? operationId}) {
  factory RecoveryGrantDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryGrantDtoFromJson(json);
}

/// 验证码已发送. [expiresAt] 为 ISO 8601.
@JsonSerializable(createToJson: false)
class const RecoveryChallengeDto({final String? expiresAt}) {
  factory RecoveryChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryChallengeDtoFromJson(json);
}

@Riverpod(keepAlive: true)
CancellationApi cancellationApi(Ref ref) =>
    CancellationApi(ref.watch(apiClientProvider));
