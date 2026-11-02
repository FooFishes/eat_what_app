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

// TODO: `/foods/list` 不返回商圈, 搜菜结果只显示店名和距离. 接口返回 `hubName` 后补充测试, 确认菜品方块显示商圈名.
/// 按菜名跨店搜索菜品.
///
/// 有定位时按店铺与用户的距离升序排列, 每道菜带距离. 没有定位时按后端默认的新建时间倒序.
/// 不使用校区中心代替定位, 因为与校区中心的距离不代表用户的实际步行距离.
@riverpod
Future<List<Dish>> dishSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final me = ref.read(currentLocationProvider).point;
  final page = await ref
      .watch(foodRepositoryProvider)
      .list(
        keyword: keyword,
        near: me,
        sort: me == null ? null : FoodSort.distance,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 按店名或菜名搜索当前校区的店铺, 包括已关门的店.
///
/// 按与用户的距离升序排列, 没有定位时按与校区中心的距离排列. 后端把已关门的店排在最后.
@riverpod
Future<List<Shop>> shopSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope == null) return const [];
  final page = await ref
      .watch(placeRepositoryProvider)
      .browseShops(
        keyword: keyword,
        campusId: scope.campusId,
        near: scope.point,
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
