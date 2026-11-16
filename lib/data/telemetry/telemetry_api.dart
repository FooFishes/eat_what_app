import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/domain/models/usage_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'telemetry_api.g.dart';

/// TelemetryApi 调用的接口路径, 相对于业务接口地址.
abstract final class TelemetryEndpoints {
  static const consent = '/telemetry/consent';
  static const events = '/telemetry/events';
}

/// 使用统计接口 (`Telemetry` 分组): 开关和事件上报, 都不要求登录.
///
/// 同意隐私政策后默认开启; 关闭后服务端会删除已收集的事件数据, 并直接丢弃后续上报.
/// 游客的开关只保存在客户端, 服务端对未登录的查询总是返回开启.
class TelemetryApi {
  TelemetryApi(this._client);

  final ApiClient _client;

  Future<UsageStats> consent({CancelToken? cancelToken}) async => _stats(
    await _client.get(TelemetryEndpoints.consent, cancelToken: cancelToken),
  );

  /// 开启 (`PUT`) 或关闭 (`DELETE`) 使用统计, 并返回更新后的开关状态.
  ///
  /// 关闭时带上 [installId], 服务端据此删除这台设备未登录时上报的事件.
  Future<UsageStats> set({
    required bool enabled,
    required String installId,
  }) async => _stats(
    enabled
        ? await _client.put(TelemetryEndpoints.consent)
        : await _client.delete(
            TelemetryEndpoints.consent,
            query: {'installId': installId},
          ),
  );

  /// 上报一批事件 (每批最多 50 条), 返回服务端是否仍开启使用统计.
  ///
  /// [events] 的每一项为 `{eventId, properties}`. 返回 false 表示本人已关闭使用统计, 这批没有记录.
  /// 上报在后台进行, 收到协议确认业务码时不弹出确认对话框.
  Future<bool> upload({
    required String installId,
    required List<Map<String, Object?>> events,
  }) async {
    final data = await _client.post(
      TelemetryEndpoints.events,
      body: {'installId': installId, 'events': events},
      consentRetry: false,
    );
    return switch (data) {
      {'enabled': false} => false,
      _ => true,
    };
  }

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
