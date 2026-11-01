import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_store.g.dart';

/// 接口缓存. 每条记录是键 `cache.<分组>.<键>` 下的 JSON 字符串, 附带写入时间.
///
/// - 每个分组有条数上限, 超出时淘汰最久未访问的记录.
/// - 记录都在 `cache.` 前缀下, 退出登录时一并删除.
/// - 读写失败均视为无缓存, 不影响页面.
class CacheStore {
  CacheStore(this._kv);

  final KvStore _kv;

  /// 读取一条记录. 写入时间超过 [maxAge] 的记录视为不存在.
  Future<String?> read(String group, String key, {Duration? maxAge}) async {
    try {
      final raw = await _kv.read(_key(group, key));
      if (raw == null) return null;
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final written = DateTime.fromMillisecondsSinceEpoch(entry['t'] as int);
      if (maxAge != null && clock.now().difference(written) > maxAge) {
        return null;
      }
      await _touch(group, key, null);
      return entry['v'] as String;
    } on Object {
      return null;
    }
  }

  Future<void> write(
    String group,
    String key,
    String value, {
    required int maxEntries,
  }) async {
    try {
      await _kv.write(
        _key(group, key),
        jsonEncode({'t': clock.now().millisecondsSinceEpoch, 'v': value}),
      );
      await _touch(group, key, maxEntries);
    } on Object {
      // 写入失败不影响页面, 直接忽略.
    }
  }

  /// 把 [key] 移到最近访问的一端. 传入 [maxEntries] 时同时淘汰最久未访问的记录.
  Future<void> _touch(String group, String key, int? maxEntries) async {
    final indexKey = 'cache.$group._index';
    final raw = await _kv.read(indexKey);
    final keys = raw == null
        ? <String>[]
        : (jsonDecode(raw) as List<dynamic>).cast<String>();
    keys
      ..remove(key)
      ..add(key);
    if (maxEntries != null) {
      while (keys.length > maxEntries) {
        await _kv.delete(_key(group, keys.removeAt(0)));
      }
    }
    await _kv.write(indexKey, jsonEncode(keys));
  }

  static String _key(String group, String key) => 'cache.$group.$key';
}

@Riverpod(keepAlive: true)
CacheStore cacheStore(Ref ref) => CacheStore(ref.watch(kvStoreProvider));
