import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancellation_api.g.dart';

/// CancellationApi 调用的接口路径, 相对于业务接口地址.
abstract final class CancellationEndpoints {
  static const code = '/auth/account/delete/code';
  static const request = '/auth/account/delete';
}

/// 接口分组 Contact 中的注销账号: 发验证码, 申请注销.
///
/// 申请后有 7 天冷静期, 账号不能用, 全部设备下线. 冷静期内在申请的设备上登录时带上撤销凭据即撤销注销.
/// 两个接口在同意新版政策之前和封禁中都能用.
class CancellationApi {
  CancellationApi(this._client);

  final ApiClient _client;

  /// 给账号绑定的手机发注销验证码. 发送前需完成人机验证. 没有手机号的账号用密码确认, 不发验证码.
  Future<void> sendCode({Map<String, String> captchaHeaders = const {}}) =>
      _client.post(CancellationEndpoints.code, headers: captchaHeaders);

  /// 申请注销. 绑定了手机号的账号带 [code], 没有手机号的带 [password].
  ///
  /// [deleteComments] 为 true 时彻底删除时一并删除评论和回复, 为 false 时匿名保留.
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
/// [deleteAt] 是彻底删除的时间 (Unix 毫秒). [deletionKey] 是撤销凭据, 只返回这一次.
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
