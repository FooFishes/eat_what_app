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

// TODO: `/foods/list` 接口暂不返回商圈和距离. 后端支持后在菜品方块上补充商圈与距离.
/// 按菜名在当前校区内跨店搜索菜品列表, 按发布时间倒序排列.
///
/// 校区列表没加载出来时不限校区. 带校区时服务端排除已关门的店.
@riverpod
Future<List<Dish>> dishSearch(Ref ref, String keyword) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope == null) return const [];
  final page = await ref
      .watch(foodRepositoryProvider)
      .list(
        keyword: keyword,
        sort: FoodSort.newest,
        campusId: scope.campusId,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 按店名或地址搜索当前校区内的店铺 (含已关门店铺).
///
/// 结果按与当前定位的距离升序排列, 无定位时按与校区中心的距离排列; 已关门店铺统一置于末尾并保持原有距离顺序.
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

/// 管理最近搜索关键词列表的控制器, 按搜索时间倒序排列并限制最大条数.
///
/// 记录按账号隔离存储在 `cache.` 前缀下, 退出登录时随账号缓存一并清除; 游客状态既不持久化记录, 也不读取本机其他账号的历史.
@riverpod
class SearchHistory extends _$SearchHistory {
  static const _max = 10;

  /// 本地缓存键名; 未登录或处于游客态时返回 null, 跳过所有读写操作.
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
