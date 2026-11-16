import 'package:eat/core/platform/external_maps.dart';
import 'package:eat/core/platform/share.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/telemetry/telemetry_api.dart';
import 'package:eat/state/analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fakes.dart';

/// 只把事件记在内存里的 [Analytics], 不检查同意记录, 不上报. 使用统计开关照常读写 [kvStoreProvider].
class RecordingAnalytics extends Analytics {
  RecordingAnalytics(Ref ref)
    : super(
        ref.watch(telemetryApiProvider),
        ref.watch(kvStoreProvider),
        () async => testInstallId,
      );

  final events = <AnalyticsEvent>[];

  @override
  void track(AnalyticsEvent event) => events.add(event);

  /// 记下的 [T] 类事件的属性, 便于和服务端收到的 `properties` 对照.
  List<Map<String, Object>> propertiesOf<T extends AnalyticsEvent>() => [
    for (final e in events.whereType<T>()) e.toProperties(),
  ];
}

/// 把 [analyticsProvider] 换成 [RecordingAnalytics], 测试里用 `container.read(analyticsProvider)` 取回.
final Override recordAnalytics = analyticsProvider.overrideWith(
  RecordingAnalytics.new,
);

/// 容器里的 [RecordingAnalytics].
RecordingAnalytics recordedIn(ProviderContainer container) =>
    container.read(analyticsProvider) as RecordingAnalytics;

/// 固定列出 [apps] 的地图. [opens] 为 false 时打开失败.
class FakeExternalMaps implements ExternalMaps {
  FakeExternalMaps({List<MapApp>? apps, this.opens = true})
    : apps = apps ?? [MapApp('高德地图', Uri.parse('amap://route'))];

  final List<MapApp> apps;
  final bool opens;
  final opened = <MapApp>[];

  @override
  Future<List<MapApp>> available({
    required double lat,
    required double lng,
    required String name,
  }) async => apps;

  @override
  Future<bool> open(MapApp app) async {
    opened.add(app);
    return opens;
  }
}

/// 分享总是返回 [outcome], 不拉起系统分享.
class FakeLinkSharer implements LinkSharer {
  FakeLinkSharer([this.outcome = ShareOutcome.shared]);

  final ShareOutcome outcome;

  @override
  Future<ShareOutcome> share(Uri link, {required String title}) async =>
      outcome;

  @override
  Future<ShareOutcome> copy(Uri link) async =>
      outcome == ShareOutcome.failed ? outcome : ShareOutcome.copied;
}
