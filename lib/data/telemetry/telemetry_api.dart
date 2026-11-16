import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/domain/models/usage_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'telemetry_api.g.dart';

// TODO: 尚未接入使用统计上报 (`POST /telemetry/events`), 当前仅提供开关控制. 接入上报后需在开关关闭时停止上报事件.
/// TelemetryApi 调用的接口路径, 相对于业务接口地址.
abstract final class TelemetryEndpoints {
  static const consent = '/telemetry/consent';
}

/// 使用统计开关接口 (`Telemetry` 分组), 管理当前账号的遥测授权状态.
///
/// 同意隐私政策后默认开启; 关闭后服务端会删除已收集的事件数据, 并直接丢弃后续上报.
class TelemetryApi {
  TelemetryApi(this._client);

  final ApiClient _client;

  Future<UsageStats> consent({CancelToken? cancelToken}) async => _stats(
    await _client.get(TelemetryEndpoints.consent, cancelToken: cancelToken),
  );

  /// 开启 (`PUT`) 或关闭 (`DELETE`) 使用统计, 并返回更新后的开关状态.
  Future<UsageStats> set({required bool enabled}) async => _stats(
    enabled
        ? await _client.put(TelemetryEndpoints.consent)
        : await _client.delete(TelemetryEndpoints.consent),
  );

  /// 若响应缺少状态字段, 则按服务端默认值视为开启.
  static UsageStats _stats(Object? data) => switch (data) {
    {'enabled': final bool enabled} => UsageStats(
      enabled: enabled,
      retentionDays: switch (data['retentionDays']) {
        final num days when days > 0 => days.toInt(),
        _ => null,
      },
    ),
    _ => const UsageStats(enabled: true),
  };
}

@Riverpod(keepAlive: true)
TelemetryApi telemetryApi(Ref ref) =>
    TelemetryApi(ref.watch(apiClientProvider));
