import 'dart:convert';

import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// 每次读写都要等一会儿的存储, 让同时进行的索引更新有机会交错.
class _SlowKvStore implements KvStore {
  final inner = MemoryKvStore();

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 5));

  @override
  Future<String?> read(String key) async {
    await _wait();
    return inner.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _wait();
    await inner.write(key, value);
  }

  @override
  Future<void> delete(String key) => inner.delete(key);

  @override
  Future<void> deletePrefix(String prefix) => inner.deletePrefix(prefix);
}

List<String> _index(_SlowKvStore kv, String group) =>
    (jsonDecode(kv.inner.values['cache.$group._index']!) as List<dynamic>)
        .cast<String>();

void main() {
  test('读取不等访问顺序写完就返回', () async {
    final kv = _SlowKvStore();
    final cache = CacheStore(kv);
    await cache.write('g', 'a', 'A', maxEntries: 3);
    await cache.write('g', 'b', 'B', maxEntries: 3);

    expect(await cache.read('g', 'a'), 'A');
    expect(_index(kv, 'g'), ['a', 'b'], reason: '读完时访问顺序还没写');

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(_index(kv, 'g'), ['b', 'a']);
  });

  test('同时读写几条, 访问顺序不丢键, 超出上限时淘汰最久没访问的', () async {
    final kv = _SlowKvStore();
    final cache = CacheStore(kv);
    await cache.write('g', 'a', 'A', maxEntries: 3);
    await cache.write('g', 'b', 'B', maxEntries: 3);
    await cache.write('g', 'c', 'C', maxEntries: 3);

    await Future.wait([cache.read('g', 'a'), cache.read('g', 'b')]);
    await cache.write('g', 'd', 'D', maxEntries: 3);

    expect(_index(kv, 'g'), ['a', 'b', 'd']);
    expect(await cache.read('g', 'c'), isNull);
  });
}
