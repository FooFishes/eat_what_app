import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_store.g.dart';

/// 接口缓存（技术架构 10.1）：每条记录是 `cache.<分组>.<键>` 下的一个 JSON 字符串，带写入时间。
///
/// 每个分组有条数上限，超了按最近访问淘汰；记录在 `cache.` 下，退出登录时一起删掉。
/// 读写失败都当作没有缓存，不影响页面。
class CacheStore {
  CacheStore(this._kv);

  final KvStore _kv;

  /// 读一条；超过 [maxAge] 的当作没有。
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
      // 缓存写不进去不影响页面。
    }
  }

  /// 把 [key] 挪到最近访问的一端；给了 [maxEntries] 时顺便淘汰最久没访问的。
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
