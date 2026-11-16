import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancellation_api.g.dart';

/// CancellationApi 调用的接口路径, 相对于业务接口地址.
abstract final class CancellationEndpoints {
  static const code = '/auth/account/delete/code';
  static const request = '/auth/account/delete';
}

/// 封装 Contact 分组中的账号注销接口, 包括发送注销验证码和提交注销申请.
///
/// 提交申请后将进入 7 天冷静期, 期间账号不可用且全部设备下线; 若在冷静期内通过原申请设备携带撤销凭据登录, 则可撤销注销.
/// 这两个接口在未确认新版政策或账号封禁期间均可调用.
class CancellationApi {
  CancellationApi(this._client);

  final ApiClient _client;

  /// 向账号绑定的手机号发送注销验证码, 发送前需完成人机验证. 未绑定手机号的账号改用密码确认, 无需发送验证码.
  Future<void> sendCode({Map<String, String> captchaHeaders = const {}}) =>
      _client.post(CancellationEndpoints.code, headers: captchaHeaders);

  /// 提交注销申请. 已绑定手机号的账号传入 [code], 未绑定手机号的账号传入 [password].
  ///
  /// 当 [deleteComments] 为 true 时, 账号彻底删除时将一并删除评论和回复; 为 false 时则匿名保留.
  Future<DeletionRequestedDto> request({
    String? code,
    String? password,
    required bool deleteComments,
  }) async => decodeJson(
    await _client.post(
      CancellationEndpoints.request,
      body: {
        'code': ?code,
        'password': ?password,
        'deleteComments': deleteComments,
      },
    ),
    DeletionRequestedDto.fromJson,
  );
}

/// 申请注销的结果 (`ContactDtos.DeletionRequested`).
///
/// [deleteAt] 为彻底删除时间戳 (Unix 毫秒); [deletionKey] 为撤销凭据, 仅在本次响应中返回一次.
@JsonSerializable(createToJson: false)
class const DeletionRequestedDto({
  final int? deleteAt,
  final String? deletionKey,
}) {
  factory DeletionRequestedDto.fromJson(Map<String, dynamic> json) =>
      _$DeletionRequestedDtoFromJson(json);

  @override
  String toString() => 'DeletionRequestedDto(deleteAt: $deleteAt)';
}

@Riverpod(keepAlive: true)
CancellationApi cancellationApi(Ref ref) =>
    CancellationApi(ref.watch(apiClientProvider));
