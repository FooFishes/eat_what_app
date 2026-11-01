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

/// 输入防抖时长.
///
/// 防抖期间关键词变化时, 旧的 Provider 已被释放. 等待结束后检查 `ref.mounted`, 已释放的不再发请求.
const _debounce = Duration(milliseconds: 300);

// TODO: 接口不支持按距离排序菜品, 目前按热度排序. 接口支持后改为按距离排序.
/// 按菜名跨店搜索菜品.
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

// TODO: 接口不返回营业状态, 已关门的店没有排到最后并标明. 接口返回营业状态后补上.
/// 按店名搜索店铺. 按与我的距离升序排列, 没有定位时按与校区中心的距离排列.
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

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
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
