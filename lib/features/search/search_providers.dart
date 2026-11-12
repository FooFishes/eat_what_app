import 'dart:convert';

import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_providers.g.dart';

/// 输入防抖时长.
///
/// 防抖期间关键词变化时, 旧的 Provider 已被释放. 等待结束后检查 `ref.mounted`, 已释放的不再发请求.
const _debounce = Duration(milliseconds: 300);

// TODO: `/foods/list` 不返回商圈和距离, 也不按校区过滤. 后端支持后补充商圈, 距离和校区.
/// 按菜名跨店搜索菜品, 最新的在前.
@riverpod
Future<List<Dish>> dishSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final page = await ref
      .watch(foodRepositoryProvider)
      .list(
        keyword: keyword,
        sort: FoodSort.newest,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 按店名或地址搜索当前校区的店铺, 包括已关门的店.
///
/// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 已关门的店排在最后, 彼此之间保持距离顺序.
@riverpod
Future<List<Shop>> shopSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope == null) return const [];
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword,
        campusId: scope.campusId,
        near: scope.point,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return [
    for (final shop in page.items)
      if (!shop.closed) shop,
    for (final shop in page.items)
      if (shop.closed) shop,
  ];
}

/// 最近搜索的词, 按时间倒序, 数量有上限.
///
/// 按账号存储在 `cache.` 前缀下, 退出登录时随账号数据一起删除.
/// 游客搜过的词不保存, 也不显示本机上其他账号的记录.
@riverpod
class SearchHistory extends _$SearchHistory {
  static const _max = 10;

  /// 存储的键. 未登录 (含游客) 时为 null, 不读也不写.
  String? get _key => switch (ref.read(sessionProvider)) {
    SignedIn(:final user) => 'cache.search.${user?.id ?? 0}',
    SignedOut() || Guest() => null,
  };

  @override
  Future<List<String>> build() async {
    final key = _key;
    if (key == null) return const [];
    final raw = await ref.watch(kvStoreProvider).read(key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } on Object {
      return const [];
    }
  }

  Future<void> add(String keyword) async {
    final key = _key;
    final word = keyword.trim();
    if (key == null || word.isEmpty) return;
    final words = [
      word,
      ...?state.value?.where((w) => w != word),
    ].take(_max).toList();
    state = AsyncData(words);
    await ref.read(kvStoreProvider).write(key, jsonEncode(words));
  }

  Future<void> clear() async {
    final key = _key;
    state = const AsyncData([]);
    if (key != null) await ref.read(kvStoreProvider).delete(key);
  }
}
