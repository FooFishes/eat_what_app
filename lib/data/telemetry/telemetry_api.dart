import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/domain/models/usage_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'telemetry_api.g.dart';

// TODO: 还没有上报使用统计 (`POST /telemetry/events`), 只提供开关. 接入上报后在开关关闭时停止上报.
/// TelemetryApi 调用的接口路径, 相对于业务接口地址.
abstract final class TelemetryEndpoints {
  static const consent = '/telemetry/consent';
}

/// 接口分组 Telemetry: 本人的使用统计开关.
///
/// 同意隐私政策后默认开启. 关闭时服务端删除本人已收集的事件, 之后上报的直接丢弃.
class TelemetryApi {
  TelemetryApi(this._client);

  final ApiClient _client;

  Future<UsageStats> consent({CancelToken? cancelToken}) async => _stats(
    await _client.get(TelemetryEndpoints.consent, cancelToken: cancelToken),
  );

  /// 开启 (`PUT`) 或关闭 (`DELETE`) 使用统计, 返回修改后的开关.
  Future<UsageStats> set({required bool enabled}) async => _stats(
    enabled
        ? await _client.put(TelemetryEndpoints.consent)
        : await _client.delete(TelemetryEndpoints.consent),
  );

  /// 缺少字段时按服务端的默认值: 开启.
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
