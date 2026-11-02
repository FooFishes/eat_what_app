import 'package:dio/dio.dart';
import 'package:eat/core/network/recovery_capability.dart';
import 'package:eat/data/sessions/session_rotation.dart';
import 'package:eat/data/sessions/sessions_api.dart';
import 'package:eat/domain/models/device_session.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sessions_repository.g.dart';

/// 登录设备.
class SessionsRepository {
  SessionsRepository(this._api);

  final SessionsApi _api;

  /// 已登录的全部设备, 本机排在最前. 设备数量少, 一次获取全部, 最多请求 4 页.
  Future<List<DeviceSession>> list({CancelToken? cancelToken}) async {
    final devices = <DeviceSession>[];
    String? cursor;
    for (var page = 0; page < 4; page++) {
      final result = await _api.list(cursor: cursor, cancelToken: cancelToken);
      devices.addAll([
        for (final dto in result.devices ?? const <DeviceSessionDto>[])
          ?_toDevice(dto),
      ]);
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    devices.sort((a, b) => (b.current ? 1 : 0) - (a.current ? 1 : 0));
    return devices;
  }

  Future<void> revoke(String sessionId) => _api.revoke(sessionId);

  /// 下线其他设备. 本机的会话随之换发, 返回换发的结果.
  Future<Rotation> revokeOthers() async {
    final commandId = newIdempotencyKey();
    final capability = newRecoveryCapability();
    await _api.revokeOthers(
      commandId: commandId,
      recoveryCapability: capability,
    );
    return awaitRotation(
      () => _api.resume(commandId: commandId, recoveryCapability: capability),
    );
  }

  static DeviceSession? _toDevice(DeviceSessionDto dto) {
    final id = dto.sessionId;
    if (id == null || id.isEmpty) return null;
    return DeviceSession(
      id: id,
      platform: switch (dto.device) {
        'WEB' => DevicePlatform.web,
        'IOS' => DevicePlatform.ios,
        'ANDROID' => DevicePlatform.android,
        _ => DevicePlatform.unknown,
      },
      lastUsedAt: DateTime.tryParse(dto.lastSeenAt ?? dto.issuedAt ?? '')
          ?.toLocal(),
      current: dto.current ?? false,
    );
  }
}

@Riverpod(keepAlive: true)
SessionsRepository sessionsRepository(Ref ref) =>
    SessionsRepository(ref.watch(sessionsApiProvider));
