import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sessions_api.g.dart';

/// 接口分组 DeviceSessions: 登录设备的列表, 下线单个设备和其他设备, 以及换发后的会话恢复.
class SessionsApi {
  SessionsApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /auth/sessions',
    'DELETE /auth/sessions/{sessionId}',
    'POST /auth/sessions/revoke-others',
    'POST /auth/sessions/{commandId}/resume',
  ];

  /// 当前账号已登录的设备, 按登录时间倒序. [cursor] 是上一页最后一项的 `sessionId`.
  Future<DeviceSessionPageDto> list({
    String? cursor,
    int size = 50,
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      '/auth/sessions',
      query: {'cursor': ?cursor, 'size': size},
      cancelToken: cancelToken,
    ),
    DeviceSessionPageDto.fromJson,
  );

  Future<void> revoke(String sessionId) =>
      _client.delete('/auth/sessions/$sessionId');

  /// 下线其他设备. 本机的会话随之换发, 之后用 [resume] 获取新凭证.
  Future<void> revokeOthers({
    required String commandId,
    required String recoveryCapability,
  }) => _client.post(
    '/auth/sessions/revoke-others',
    body: {'commandId': commandId, 'recoveryCapability': recoveryCapability},
  );

  Future<SessionOutcomeDto> resume({
    required String commandId,
    required String recoveryCapability,
  }) async => decodeJson(
    await _client.post(
      '/auth/sessions/$commandId/resume',
      headers: {'X-Recovery-Capability': recoveryCapability},
    ),
    SessionOutcomeDto.fromJson,
  );
}

@JsonSerializable(createToJson: false)
class const DeviceSessionPageDto({
  final List<DeviceSessionDto>? devices,
  final String? nextCursor,
}) {
  factory DeviceSessionPageDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionPageDtoFromJson(json);
}

/// 一台已登录的设备. [device] 为 `WEB`, `IOS`, `ANDROID` 或 `UNKNOWN`, 时间为 ISO 8601.
@JsonSerializable(createToJson: false)
class const DeviceSessionDto({
  final String? sessionId,
  final String? device,
  final String? issuedAt,
  final String? lastSeenAt,
  final bool? current,
}) {
  factory DeviceSessionDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionDtoFromJson(json);
}

/// 换发会话的结果. 下线其他设备和换绑手机共用.
///
/// [status] 为 `READY` 时 [tokenName] 和 [tokenValue] 是新凭证.
/// `COMMITTED` 和 `FACT_READY` 表示换发尚未完成. `SUPERSEDED` 和 `EXPIRED` 表示需要重新登录.
@JsonSerializable(createToJson: false)
class const SessionOutcomeDto({
  final String? status,
  final String? tokenName,
  final String? tokenValue,
  final bool? restricted,
}) {
  factory SessionOutcomeDto.fromJson(Map<String, dynamic> json) =>
      _$SessionOutcomeDtoFromJson(json);
}

@Riverpod(keepAlive: true)
SessionsApi sessionsApi(Ref ref) => SessionsApi(ref.watch(apiClientProvider));
