import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/remote_config/remote_config_repository.dart';
import 'package:eat/domain/models/client_config.dart';
import 'package:eat/domain/rules/remote_config_rules.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config.g.dart';

/// 远程配置快照 (技术架构第 17 节).
///
/// - 启动时由 `bootstrap` 调用 [restore], 读取本机快照, 没有快照时使用内置默认值, 不等待网络.
/// - 同意隐私政策后调用 [refresh] 获取最新配置, 回到前台时调用 [resume].
/// - 获取失败不提示用户, 继续使用当前配置 (产品 12.2).
@Riverpod(keepAlive: true)
class RemoteConfig extends _$RemoteConfig {
  /// 单次请求的超时时间. 超时按失败处理, 继续使用当前配置.
  static const timeout = Duration(seconds: 3);

  /// 回到前台时, 距上次成功获取超过该时长才重新请求.
  static const staleAfter = Duration(minutes: 10);

  var _fallback = ClientConfig.empty;
  String? _etag;
  DateTime? _fetchedAt;
  Future<bool>? _fetching;

  /// 是否已开始获取远程配置. 同意隐私政策之前不请求, 因此回到前台和切换校区时也不请求.
  var _started = false;

  @override
  ClientConfig build() {
    // 服务端按校区筛选公告, 切换校区后重新请求. 本机选择读出时校区由空变为已选值, 同样触发一次.
    ref.listen(placeAndMealProvider.select((p) => p.campusId), (prev, next) {
      if (_started && prev != next) unawaited(refresh());
    });
    return ClientConfig.empty;
  }

  RemoteConfigRepository get _repository =>
      ref.read(remoteConfigRepositoryProvider);

  /// 读取本机快照作为初始配置, 没有快照时使用内置默认值.
  Future<void> restore() async {
    _fallback = await _repository.defaults();
    final snapshot = await _repository.readSnapshot(_fallback);
    if (!ref.mounted) return;
    _etag = snapshot?.etag;
    state = snapshot?.config ?? _fallback;
  }

  /// 请求最新配置. 并发调用共用同一次请求, 失败时保留当前配置. 请求成功 (含配置没有变化) 时返回 true.
  Future<bool> refresh() {
    _started = true;
    return _fetching ??= _fetch().whenComplete(() => _fetching = null);
  }

  /// 回到前台时调用. 距上次成功获取超过 [staleAfter] 时重新请求.
  Future<void> resume() async {
    if (!_started) return;
    final fetched = _fetchedAt;
    if (fetched != null && clock.now().difference(fetched) < staleAfter) {
      return;
    }
    await refresh();
  }

  Future<bool> _fetch() async {
    try {
      final result = await _repository
          .fetch(
            fallback: _fallback,
            platform: clientPlatform,
            build: await _buildNumber(),
            campusId: ref.read(placeAndMealProvider).campusId,
            // 快照是否就是本次请求参数对应的配置由服务端按 ETag 判断, 参数变化时服务端会返回新配置.
            etag: _etag,
          )
          .timeout(timeout);
      if (!ref.mounted) return false;
      if (result case RemoteConfigFetched(:final snapshot)) {
        _etag = snapshot.etag;
        state = snapshot.config;
      }
      _fetchedAt = clock.now();
      return true;
    } on Object catch (e) {
      debugPrint('remote config fetch failed: $e');
      return false;
    }
  }

  Future<int?> _buildNumber() async {
    try {
      return int.tryParse(await ref.read(appBuildNumberProvider.future));
    } on Object {
      return null;
    }
  }
}

/// 当前客户端在远程配置中的平台名: `android`, `ios` 或 `web`. 其他平台 (桌面端调试) 为 null, 不做版本检查.
String? get clientPlatform {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };
}

/// 当前平台的版本线, 没有时为 null.
@Riverpod(keepAlive: true)
VersionLine? currentVersionLine(Ref ref) => switch (clientPlatform) {
  final platform? => ref.watch(
    remoteConfigProvider.select((c) => c.versions[platform]),
  ),
  null => null,
};

/// 本机构建号与当前平台版本线比较的结果. 构建号读出之前为 [UpdateDecision.none].
@Riverpod(keepAlive: true)
UpdateDecision appUpdate(Ref ref) => updateDecision(
  ref.watch(currentVersionLineProvider),
  int.tryParse(ref.watch(appBuildNumberProvider).value ?? ''),
);

/// 路由守卫需要的远程配置状态: 是否强制更新, 是否停服维护.
typedef AppGate = ({bool forceUpdate, bool down});

@Riverpod(keepAlive: true)
AppGate appGate(Ref ref) => (
  forceUpdate: ref.watch(appUpdateProvider) == UpdateDecision.force,
  down: ref.watch(
    remoteConfigProvider.select(
      (c) => c.maintenance.mode == MaintenanceMode.down,
    ),
  ),
);

/// 本机关于公告和建议更新的记录.
class const NoticeRecords({
  /// 关掉的普通公告 id.
  final Set<int> dismissed = const {},

  /// 弹出过的重要公告 id.
  final Set<int> seen = const {},

  /// 提示过建议更新的最新构建号.
  final int? promptedBuild,

  /// 本机记录是否已读出. 读出之前不展示公告和建议更新, 避免已看过的内容再次出现.
  final bool restored = false,
});

/// 管理本机的公告与建议更新记录. 记录属于设备, 退出登录时保留.
@Riverpod(keepAlive: true)
class Notices extends _$Notices {
  static const dismissedKey = 'prefs.notice.dismissed';
  static const seenKey = 'prefs.notice.seen';
  static const promptedKey = 'prefs.update.prompted';

  /// 每类记录最多保留的公告 id 数. 公告 id 递增, 超出时丢弃最早的记录.
  static const _maxIds = 50;

  @override
  NoticeRecords build() {
    unawaited(_restore());
    return const NoticeRecords();
  }

  KvStore get _kv => ref.read(kvStoreProvider);

  Future<void> _restore() async {
    Set<int> dismissed = const {};
    Set<int> seen = const {};
    int? prompted;
    final kv = _kv;
    try {
      dismissed = _decodeIds(await kv.read(dismissedKey));
      seen = _decodeIds(await kv.read(seenKey));
      prompted = int.tryParse(await kv.read(promptedKey) ?? '');
    } on Object catch (e) {
      debugPrint('restore notice records failed: $e');
    }
    if (!ref.mounted) return;
    state = NoticeRecords(
      dismissed: {...dismissed, ...state.dismissed},
      seen: {...seen, ...state.seen},
      promptedBuild: state.promptedBuild ?? prompted,
      restored: true,
    );
  }

  /// 关掉普通公告 [id], 同一条不再出现.
  Future<void> dismiss(int id) async {
    final ids = _trim({...state.dismissed, id});
    state = _copy(dismissed: ids);
    await _write(dismissedKey, jsonEncode(ids.toList()));
  }

  /// 记录重要公告 [id] 已弹出, 之后不再弹出.
  Future<void> markSeen(int id) async {
    final ids = _trim({...state.seen, id});
    state = _copy(seen: ids);
    await _write(seenKey, jsonEncode(ids.toList()));
  }

  /// 记录已就最新构建号 [build] 提示过建议更新.
  Future<void> markPrompted(int build) async {
    state = _copy(promptedBuild: build);
    await _write(promptedKey, '$build');
  }

  NoticeRecords _copy({
    Set<int>? dismissed,
    Set<int>? seen,
    int? promptedBuild,
  }) => NoticeRecords(
    dismissed: dismissed ?? state.dismissed,
    seen: seen ?? state.seen,
    promptedBuild: promptedBuild ?? state.promptedBuild,
    restored: state.restored,
  );

  Future<void> _write(String key, String value) async {
    try {
      await _kv.write(key, value);
    } on Object catch (e) {
      debugPrint('save notice records failed: $e');
    }
  }

  static Set<int> _decodeIds(String? raw) => raw == null
      ? const {}
      : {
          for (final id in jsonDecode(raw) as List<dynamic>)
            (id as num).toInt(),
        };

  static Set<int> _trim(Set<int> ids) {
    if (ids.length <= _maxIds) return ids;
    final sorted = ids.toList()..sort();
    return sorted.sublist(sorted.length - _maxIds).toSet();
  }
}

/// 发现页抽屉顶部要显示的普通公告, 没有时为 null.
@Riverpod(keepAlive: true)
Announcement? bannerNotice(Ref ref) {
  final records = ref.watch(noticesProvider);
  if (!records.restored) return null;
  return bannerAnnouncement(
    ref.watch(remoteConfigProvider.select((c) => c.announcements)),
    records.dismissed,
    clock.now(),
  );
}

/// 待弹出的重要公告, 没有时为 null.
@Riverpod(keepAlive: true)
Announcement? importantNotice(Ref ref) {
  final records = ref.watch(noticesProvider);
  if (!records.restored) return null;
  return pendingImportantAnnouncement(
    ref.watch(remoteConfigProvider.select((c) => c.announcements)),
    records.seen,
    clock.now(),
  );
}

/// 需要提示建议更新时为当前平台的版本线, 否则为 null.
@Riverpod(keepAlive: true)
VersionLine? updatePrompt(Ref ref) {
  final records = ref.watch(noticesProvider);
  if (!records.restored) return null;
  final line = ref.watch(currentVersionLineProvider);
  return shouldPromptUpdate(
        ref.watch(appUpdateProvider),
        line,
        records.promptedBuild,
      )
      ? line
      : null;
}
