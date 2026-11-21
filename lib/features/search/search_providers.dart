import 'dart:convert';

import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_providers.g.dart';

/// 输入防抖时长.
///
/// 防抖期间关键词变化时, 旧的 Provider 已被释放. 等待结束后检查 `ref.mounted`, 已释放的不再发请求.
const _debounce = Duration(milliseconds: 300);

// TODO: `/foods/list` 还不收坐标. 后端支持后带上 `scope.point` 的坐标, 在菜品方块上补充距离.
// TODO: 不传 `mealTime` 时, 服务端仍按北京时间的当前饭点筛菜, 默认不限饭点目前做不到. 后端改为不传即不按饭点筛后删除本条; 若后端改为提供表示全部的取值, 则不选饭点时传该取值.
/// 按菜名跨店搜索菜品列表, 不限校区, 按发布时间倒序排列.
///
/// 请求固定带堂食场景, 因为服务端只在带场景时排除已关门的店. 堂食不按外卖状态筛菜, 所以不会漏掉不能点外卖的菜.
///
/// 选了 [meal] 时只搜这一顿的菜.
@riverpod
Future<List<Dish>> dishSearch(Ref ref, String keyword, MealTime? meal) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope == null) return const [];
  final page = await ref
      .watch(foodRepositoryProvider)
      .list(
        keyword: keyword,
        sort: FoodSort.newest,
        scene: RatingScene.dineIn,
        mealTime: meal,
        pageSize: 40,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 搜店的排序, [label] 是搜索页 "店" 栏筛选里的选项.
enum ShopOrder {
  /// 按与当前定位的距离升序, 无定位时按与校区中心的距离; 两者都没有时服务端按新建时间倒序.
  distance('离我近', ShopSort.distance),

  /// 按堂食推荐率倒序.
  dineIn('堂食推荐率', ShopSort.rating, RatingScene.dineIn),

  /// 按外卖推荐率倒序.
  delivery('外卖推荐率', ShopSort.rating, RatingScene.delivery),

  /// 按新建时间倒序.
  newest('最新', ShopSort.newest);

  const new(this.label, this.sort, [this.scene]);

  final String label;
  final ShopSort sort;

  /// [ShopSort.rating] 按哪个场景的推荐率排.
  final RatingScene? scene;
}

/// 按店名, 地址或店里的菜名搜索店铺 (含已关门店铺), 按 [order] 排序.
///
/// 已关门店铺不论哪种排序都统一置于末尾, 并保持服务端给的顺序.
@riverpod
Future<List<Shop>> shopSearch(Ref ref, String keyword, ShopOrder order) async {
  await Future<void>.delayed(_debounce);
  if (!ref.mounted) return const [];
  final scope = await shopSearchScope(ref);
  if (!ref.mounted || scope == null) return const [];
  final page = await ref
      .watch(placeRepositoryProvider)
      .searchShops(
        keyword: keyword,
        near: scope.point,
        sort: order.sort,
        scene: order.scene,
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
