import 'dart:async';
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
/// - 读取时不等访问顺序写完就返回, 访问顺序只影响淘汰哪条, 不影响读到的内容.
class CacheStore {
  CacheStore(this._kv);

  final KvStore _kv;

  /// 每个分组上一次索引更新, 新的更新排在它后面.
  ///
  /// 更新索引要先读后写, 同时进行的两次更新会互相覆盖, 丢了的键再也不会被淘汰.
  final _indexQueue = <String, Future<void>>{};

  /// 读取缓存记录, 若写入时间已超过 [maxAge] 则视为过期并返回 null.
  Future<String?> read(String group, String key, {Duration? maxAge}) async {
    try {
      final raw = await _kv.read(_key(group, key));
      if (raw == null) return null;
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final written = DateTime.fromMillisecondsSinceEpoch(entry['t'] as int);
      if (maxAge != null && clock.now().difference(written) > maxAge) {
        return null;
      }
      unawaited(_touch(group, key, null));
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

  /// 将 [key] 更新至 LRU 索引末尾 (最近访问); 传入 [maxEntries] 时同步淘汰最久未访问的超出记录.
  ///
  /// 同一分组的更新依次进行. 失败时忽略, 因为缓存允许丢失.
  Future<void> _touch(String group, String key, int? maxEntries) {
    final next = (_indexQueue[group] ?? Future<void>.value())
        .then((_) => _updateIndex(group, key, maxEntries))
        .catchError((Object _) {});
    _indexQueue[group] = next;
    return next;
  }

  Future<void> _updateIndex(String group, String key, int? maxEntries) async {
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
