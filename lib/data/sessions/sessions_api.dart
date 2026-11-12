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

/// 接口分组 DeviceSessions: 登录设备的列表, 下线单个设备和其他设备.
class SessionsApi {
  SessionsApi(this._client);

  final ApiClient _client;

  /// 当前账号已登录的设备, 按登录时间倒序. [cursor] 是上一页最后一项的 `sessionId`.
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

  /// 下线本机以外的所有设备. 本机的会话不变.
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

/// 一台已登录的设备. [device] 为 `WEB`, `IOS`, `ANDROID` 或 `UNKNOWN`. [issuedAt] 是登录时间, ISO 8601.
@JsonSerializable(createToJson: false)
class const DeviceSessionDto({
  final String? sessionId,
  final String? device,
  final String? issuedAt,
  final bool? current,
}) {
  factory DeviceSessionDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionDtoFromJson(json);
}

@Riverpod(keepAlive: true)
SessionsApi sessionsApi(Ref ref) => SessionsApi(ref.watch(apiClientProvider));
