import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/data/push/push_api.dart';
import 'package:eat/domain/models/push.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_repository.g.dart';

/// 单个推送栏目的开关配置.
class const PushSetting({
  required final PushCategory category,
  required final bool enabled,
});

/// 推送设置仓库, 管理各推送栏目的开关状态.
///
/// 开关状态存一份本地缓存, 进入通知设置时先显示. 账号作用域的缓存在退出登录和登录过期时都会删除, 所以键里不带用户 id.
class PushRepository {
  PushRepository(this._api, this._cache);

  final PushApi _api;
  final CacheStore _cache;

  static const _group = 'settings';
  static const _key = 'push';

  /// 获取四个推送栏目的开关状态 (按 [PushCategory] 顺序排列), 接口未返回的栏目默认视为开启.
  Future<List<PushSetting>> settings({CancelToken? cancelToken}) async =>
      _save(_settings(await _api.settings(cancelToken: cancelToken)));

  /// 切换栏目 [category] 的开关状态, 并返回更新后的全部栏目开关.
  Future<List<PushSetting>> set(
    PushCategory category, {
    required bool enabled,
  }) async => _save(
    _settings(await _api.set(category: category.api, enabled: enabled)),
  );

  /// 读取本地缓存的开关状态, 没有缓存或缓存无法解析时返回 null.
  Future<List<PushSetting>?> cachedSettings() async {
    final raw = await _cache.read(_group, _key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return [
        for (final category in PushCategory.values)
          PushSetting(
            category: category,
            enabled: json[category.api] as bool? ?? true,
          ),
      ];
    } on Object {
      return null;
    }
  }

  Future<List<PushSetting>> _save(List<PushSetting> settings) async {
    await _cache.write(
      _group,
      _key,
      jsonEncode({for (final s in settings) s.category.api: s.enabled}),
      maxEntries: 4,
    );
    return settings;
  }

  static List<PushSetting> _settings(PushSettingsDto dto) => [
    for (final category in PushCategory.values)
      PushSetting(
        category: category,
        enabled: dto.categories?[category.api] ?? true,
      ),
  ];
}

@Riverpod(keepAlive: true)
PushRepository pushRepository(Ref ref) =>
    PushRepository(ref.watch(pushApiProvider), ref.watch(cacheStoreProvider));
