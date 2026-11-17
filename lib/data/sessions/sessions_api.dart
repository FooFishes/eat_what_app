import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sessions_api.g.dart';

/// SessionsApi 调用的接口路径, 相对于业务接口地址.
abstract final class SessionsEndpoints {
  static const revokeOthers = '/auth/sessions/revoke-others';
  static String session(String sessionId) => '/auth/sessions/$sessionId';
  static const sessions = '/auth/sessions';
}

/// 登录设备会话接口 (`DeviceSessions` 分组), 提供设备列表查询与下线单个或其余设备.
class SessionsApi {
  SessionsApi(this._client);

  final ApiClient _client;

  /// 分页查询当前账号的已登录设备, 按登录时间倒序排列; [cursor] 为上一页末尾项的 `sessionId`.
  Future<DeviceSessionPageDto> list({
    String? cursor,
    int size = 50,
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      SessionsEndpoints.sessions,
      query: {'cursor': ?cursor, 'size': size},
      cancelToken: cancelToken,
    ),
    DeviceSessionPageDto.fromJson,
  );

  Future<void> revoke(String sessionId) =>
      _client.delete(SessionsEndpoints.session(sessionId));

  /// 下线除本机以外的所有其他设备, 当前设备会话保持有效.
  Future<void> revokeOthers() => _client.post(SessionsEndpoints.revokeOthers);
}

@JsonSerializable(createToJson: false)
class const DeviceSessionPageDto({
  final List<DeviceSessionDto>? devices,
  final String? nextCursor,
}) {
  factory DeviceSessionPageDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionPageDtoFromJson(json);
}

/// 已登录设备信息, [device] 取值为 `WEB`, `IOS`, `ANDROID` 或 `UNKNOWN`.
///
/// [name] 是服务端按安装 ID 读取的登记机型, 没有机型时为 "未知设备", 转换时和空白一样当作没有名称. [issuedAt] 与 [lastActiveAt] 分别为登录时间与最近活跃时间, 均为 ISO 8601 格式.
@JsonSerializable(createToJson: false)
class const DeviceSessionDto({
  final String? sessionId,
  final String? device,
  final String? name,
  final String? issuedAt,
  final String? lastActiveAt,
  final bool? current,
}) {
  factory DeviceSessionDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionDtoFromJson(json);
}

@Riverpod(keepAlive: true)
SessionsApi sessionsApi(Ref ref) => SessionsApi(ref.watch(apiClientProvider));
