import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/telemetry/telemetry_api.dart';
import 'package:eat/state/analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fakes.dart';

/// 只把事件记在内存里的 [Analytics], 不检查同意记录, 不上报.
class RecordingAnalytics extends Analytics {
  RecordingAnalytics(Ref ref)
    : super(
        ref.watch(telemetryApiProvider),
        MemoryKvStore(),
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
