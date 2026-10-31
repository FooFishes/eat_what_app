import 'dart:convert';

import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_providers.g.dart';

/// 输入停下 300ms 才发请求；这段时间里关键词变了，旧的 Provider 已经释放，不再发（技术架构 10.5）。
const _debounce = Duration(milliseconds: 300);

/// 搜菜名：跨店按菜名查。接口不能按距离排（现状差距 2.1），先按热度。
@riverpod
Future<List<Dish>> dishSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final page = await ref
      .watch(foodRepositoryProvider)
      .list(
        keyword: keyword,
        sort: FoodSort.popular,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 搜店名：离我近的在前，没有定位时按离校区中心的远近。
@riverpod
Future<List<Shop>> shopSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final me = ref.read(currentLocationProvider).point;
  final campus = ref.read(currentPlaceProvider).campus;
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword,
        near: me ?? campus?.center,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 最近搜过的词，最多 10 个，新的在前。按账号存，退出登录时删（技术架构 9.1）。
@riverpod
class SearchHistory extends _$SearchHistory {
  static const _max = 10;

  String get _key {
    final id = switch (ref.read(sessionProvider)) {
      SignedIn(:final user) => user?.id ?? 0,
      SignedOut() => 0,
    };
    return 'cache.search.$id';
  }

  @override
  Future<List<String>> build() async {
    final raw = await ref.watch(kvStoreProvider).read(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } on Object {
      return const [];
    }
  }

  Future<void> add(String keyword) async {
    final word = keyword.trim();
    if (word.isEmpty) return;
    final words = [
      word,
      ...?state.value?.where((w) => w != word),
    ].take(_max).toList();
    state = AsyncData(words);
    await ref.read(kvStoreProvider).write(_key, jsonEncode(words));
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await ref.read(kvStoreProvider).delete(_key);
  }
}
