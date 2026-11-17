import 'package:dio/dio.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/sessions/sessions_api.dart';
import 'package:eat/domain/models/device_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sessions_repository.g.dart';

/// 登录设备会话仓库.
class SessionsRepository {
  SessionsRepository(this._api);

  final SessionsApi _api;

  /// 获取当前账号的全部已登录设备, 并将本机置于首位; 因设备总数通常较少, 方法内连续翻页获取全部记录 (最多 4 页).
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

  /// 下线除本机以外的所有其他设备, 当前设备会话保持有效.
  Future<void> revokeOthers() => _api.revokeOthers();

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
      name: deviceNameOf(dto.name),
      signedInAt: DateTime.tryParse(dto.issuedAt ?? '')?.toLocal(),
      lastActiveAt: DateTime.tryParse(dto.lastActiveAt ?? '')?.toLocal(),
      current: dto.current ?? false,
    );
  }
}

@Riverpod(keepAlive: true)
SessionsRepository sessionsRepository(Ref ref) =>
    SessionsRepository(ref.watch(sessionsApiProvider));
