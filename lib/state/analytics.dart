import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/device/device_identity.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/telemetry/telemetry_api.dart';
import 'package:eat/domain/models/usage_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'analytics.g.dart';

/// 使用统计的采集与批量上报.
///
/// 只在本机有同意记录 ([start] 之后) 且使用统计开着时采集, 游客和未登录时同样采集, 批次带上安装 ID.
/// 事件先在内存中攒批, 满 [batchSize] 条或最早一条等待满 [flushInterval] 时上报, 退到后台和回到前台时也上报.
/// 上报失败的事件存进 [queueKey], 最多保留 [maxQueued] 条, 超出时丢弃最旧的, 之后随下一次上报补发.
class Analytics {
  Analytics(this._api, this._kv, this._installId);

  /// 发不出去的事件. 设备级数据, 退出登录时先尝试上报再清空.
  static const queueKey = 'analytics.queue';

  /// 本机的使用统计开关, 值为 `false` 表示关闭, 没有记录时视为开启.
  ///
  /// 游客的开关只存在客户端. 登录用户以服务端为准, 登录时和打开隐私页时同步到本机.
  static const enabledKey = 'prefs.telemetry.enabled';

  static const batchSize = 20;

  /// 服务端每批最多接收的条数.
  static const maxBatch = 50;
  static const maxQueued = 500;
  static const flushInterval = Duration(seconds: 30);

  /// 退出登录前补发的最长等待时间, 避免网络不可达时退出登录长时间无响应.
  static const signOutFlushTimeout = Duration(seconds: 3);

  final TelemetryApi _api;
  final KvStore _kv;
  final Future<String> Function() _installId;

  var _consented = false;
  var _enabled = true;
  final _pending = <Map<String, Object?>>[];
  Timer? _timer;
  Future<void>? _flushing;
  AppLifecycleListener? _lifecycle;

  /// 当前是否采集事件.
  bool get active => _consented && _enabled;

  /// 在确认本机存在同意记录后开始采集, 并补发上次没发出去的事件. 重复调用仅生效一次.
  Future<void> start() async {
    if (_consented) return;
    _consented = true;
    try {
      _enabled = await _kv.read(enabledKey) != 'false';
      if (!_enabled) return;
      _pending.insertAll(0, _decode(await _kv.read(queueKey)));
    } on Object catch (e) {
      debugPrint('analytics start failed: $e');
    }
    if (_pending.isNotEmpty) unawaited(flush());
  }

  /// 记录一个事件. 未开始采集或使用统计关闭时忽略.
  void track(AnalyticsEvent event) {
    if (!active) return;
    final properties = event.toProperties();
    if (kDebugMode) debugPrint('[analytics] $properties');
    _pending.add({'eventId': const Uuid().v4(), 'properties': properties});
    if (_pending.length >= batchSize) {
      unawaited(flush());
    } else {
      _timer ??= Timer(flushInterval, () => unawaited(flush()));
    }
  }

  /// 上报全部待发事件. 并发调用共用同一次上报.
  Future<void> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<void> _flush() async {
    _timer?.cancel();
    _timer = null;
    if (!active) return;
    while (active && _pending.isNotEmpty) {
      final batch = _pending.take(maxBatch).toList();
      try {
        final enabled = await _api.upload(
          installId: await _installId(),
          events: batch,
        );
        _removeBatch(batch);
        if (!enabled) {
          await _setEnabled(false);
          return;
        }
      } on AppFailure catch (e) {
        if (_retryable(e.kind)) break;
        // 数据不合法等失败重发也不会成功, 丢弃这一批, 避免阻塞后续事件.
        _removeBatch(batch);
      } on Object catch (e) {
        debugPrint('analytics upload failed: $e');
        break;
      }
    }
    await _persist();
  }

  /// 关闭或开启使用统计后更新本机开关. 关闭时清空待发事件, 之后不再采集.
  Future<void> _setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      if (enabled) {
        await _kv.delete(enabledKey);
      } else {
        _timer?.cancel();
        _timer = null;
        _pending.clear();
        await _kv.write(enabledKey, 'false');
        await _kv.delete(queueKey);
      }
    } on Object catch (e) {
      debugPrint('analytics setting not saved: $e');
    }
  }

  /// 读取使用统计开关. 已登录时同步服务端的状态到本机, 游客的开关只在本机.
  Future<UsageStats> loadConsent({
    required bool signedIn,
    CancelToken? cancelToken,
  }) async {
    final stats = await _api.consent(cancelToken: cancelToken);
    if (!signedIn) {
      return UsageStats(
        enabled: await _kv.read(enabledKey) != 'false',
        retentionDays: stats.retentionDays,
      );
    }
    await _setEnabled(stats.enabled);
    return stats;
  }

  /// 开启或关闭使用统计, 返回服务端确认后的状态. 失败时抛出 [AppFailure], 本机开关不变.
  ///
  /// 关闭时先停止采集并清空待发事件, 再请求服务端删除已收集的事件.
  Future<UsageStats> changeConsent({required bool enabled}) async {
    final before = _enabled;
    if (!enabled) await _setEnabled(false);
    try {
      final saved = await _api.set(
        enabled: enabled,
        installId: await _installId(),
      );
      await _setEnabled(saved.enabled);
      return saved;
    } on Object {
      await _setEnabled(before);
      rethrow;
    }
  }

  /// 登录后同步服务端的开关. 失败时保留本机的开关.
  Future<void> syncConsent() async {
    if (!_consented) return;
    try {
      await _setEnabled((await _api.consent()).enabled);
    } on Object catch (e) {
      debugPrint('analytics consent sync failed: $e');
    }
  }

  /// 退出登录前调用: 用当前凭证尝试补发, 然后清空待发事件.
  Future<void> flushBeforeSignOut() async {
    try {
      await flush().timeout(signOutFlushTimeout);
    } on TimeoutException {
      // 超时后照常退出登录, 剩余事件随清空丢弃.
    }
    _pending.clear();
    try {
      await _kv.delete(queueKey);
    } on Object catch (e) {
      debugPrint('analytics queue not cleared: $e');
    }
  }

  /// 监听应用生命周期: 记一次冷启动, 之后每次回到前台记一次并补发, 退到后台时上报.
  void observeLifecycle() {
    if (_lifecycle != null) return;
    track(const AppOpenEvent());
    _lifecycle = AppLifecycleListener(
      onShow: () {
        track(const AppOpenEvent());
        unawaited(flush());
      },
      onHide: () => unawaited(flush()),
    );
  }

  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
  }

  void _removeBatch(List<Map<String, Object?>> batch) {
    final sent = batch.map((e) => e['eventId']).toSet();
    _pending.removeWhere((e) => sent.contains(e['eventId']));
  }

  Future<void> _persist() async {
    if (_pending.length > maxQueued) {
      _pending.removeRange(0, _pending.length - maxQueued);
    }
    try {
      if (_pending.isEmpty) {
        await _kv.delete(queueKey);
      } else {
        await _kv.write(queueKey, jsonEncode(_pending));
      }
    } on Object catch (e) {
      debugPrint('analytics queue not saved: $e');
    }
  }

  static bool _retryable(FailureKind kind) => switch (kind) {
    FailureKind.network ||
    FailureKind.server ||
    FailureKind.tooFrequent ||
    FailureKind.sessionExpired ||
    FailureKind.cancelled => true,
    FailureKind.forbidden ||
    FailureKind.business ||
    FailureKind.unknown => false,
  };

  /// 读取本地队列. 内容损坏时整体丢弃.
  static List<Map<String, Object?>> _decode(String? raw) {
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List)
          if (item case {
            'eventId': final String _,
            'properties': final Map<String, Object?> _,
          })
            item as Map<String, Object?>,
      ];
    } on Object {
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) {
  final analytics = Analytics(
    ref.watch(telemetryApiProvider),
    ref.watch(kvStoreProvider),
    () => ref.read(deviceIdentityProvider).installId(),
  );
  ref.onDispose(analytics.dispose);
  return analytics;
}
