import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/state/published.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_providers.g.dart';

/// 分页列表和加载下一页失败的原因.
class const LoadedPages<T>({
  required final Paged<T> pages,
  final AppFailure? moreError,
});

/// 按 [fetch] 加载下一页, 同一时刻只加载一页. 失败时把原因记在 [LoadedPages.moreError] 中.
class _MoreLoader<T> {
  var _loading = false;

  Future<void> load(
    Ref ref,
    LoadedPages<T>? current,
    Future<Paged<T>> Function(int page) fetch,
    void Function(LoadedPages<T> next) emit,
  ) async {
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await fetch(current.pages.page + 1);
      if (ref.mounted) emit(LoadedPages(pages: current.pages.append(next)));
    } on AppFailure catch (e) {
      if (ref.mounted) emit(LoadedPages(pages: current.pages, moreError: e));
    } finally {
      _loading = false;
    }
  }
}

/// 一家店的全部菜品, 按菜单顺序分页: 招牌菜在前, 然后按分类, 同一分类按赞数.
///
/// [LoadedPages.pages] 的 `total` 是这家店的菜数. 发布新菜后重新请求. 离开页面后保留 5 分钟.
@riverpod
class ShopMenu extends _$ShopMenu {
  final _more = _MoreLoader<Dish>();

  @override
  Future<LoadedPages<Dish>> build(int shopId) async {
    ref.cacheFor(const Duration(minutes: 5));
    ref.watch(publishedCountProvider);
    return LoadedPages(pages: await _fetch(1, cancelToken: ref.cancelToken()));
  }

  Future<Paged<Dish>> _fetch(int page, {CancelToken? cancelToken}) => ref
      .read(foodRepositoryProvider)
      .list(
        restaurantId: shopId,
        sort: FoodSort.menu,
        page: page,
        cancelToken: cancelToken,
      );

  Future<void> loadMore() =>
      _more.load(ref, state.value, _fetch, (next) => state = AsyncData(next));
}

/// 一家店的招牌菜, 至多 3 道, 按菜单顺序.
///
/// 店铺接口不返回招牌菜, 因此单独请求. 发布新菜后重新请求. 离开页面后保留 5 分钟.
@riverpod
Future<List<Dish>> shopSignatures(Ref ref, int shopId) async {
  ref.cacheFor(const Duration(minutes: 5));
  ref.watch(publishedCountProvider);
  final page = await ref
      .watch(foodRepositoryProvider)
      .list(
        restaurantId: shopId,
        signatureOnly: true,
        sort: FoodSort.menu,
        pageSize: 3,
        cancelToken: ref.cancelToken(),
      );
  return page.items;
}

/// 当前用户对一家店的评价和收藏.
class const ShopMine({
  final MyShopRatings ratings = const MyShopRatings(),
  final bool favorite = false,
});

/// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
///
/// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
/// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.
@riverpod
class ShopMineState extends _$ShopMineState {
  @override
  ShopMine build(int shopId) {
    final (ratings, favorite) = ref.watch(
      shopProvider(shopId)
          .select((s) => (s.value?.myRatings, s.value?.favorite ?? false)),
    );
    return ShopMine(
      ratings: ratings ?? const MyShopRatings(),
      favorite: favorite,
    );
  }

  /// 评价 [scene] 场景, [rating] 为 null 时撤回. 成功时返回 null, 并重新请求店铺详情以更新推荐率.
  ///
  /// 失败时恢复原值并返回失败原因.
  Future<AppFailure?> rate(RatingScene scene, ShopRating? rating) async {
    final before = state;
    state = ShopMine(
      ratings: before.ratings.withRating(scene, rating),
      favorite: before.favorite,
    );
    try {
      final saved = await ref
          .read(placeRepositoryProvider)
          .rateShop(shopId, scene, rating);
      if (!ref.mounted) return null;
      state = ShopMine(ratings: saved, favorite: state.favorite);
      ref.invalidate(shopProvider(shopId));
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = before;
      return e;
    }
  }

  Future<AppFailure?> toggleFavorite() async {
    final before = state;
    final favorite = !before.favorite;
    state = ShopMine(ratings: before.ratings, favorite: favorite);
    try {
      await ref
          .read(placeRepositoryProvider)
          .setShopFavorite(shopId, favorite: favorite);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = before;
      return e;
    }
  }
}

/// 一家店的修改记录, 最新的在前, 分页加载.
@riverpod
class ShopHistory extends _$ShopHistory {
  final _more = _MoreLoader<ShopRevision>();

  @override
  Future<LoadedPages<ShopRevision>> build(int shopId) async => LoadedPages(
    pages: await ref
        .watch(placeRepositoryProvider)
        .history(shopId, cancelToken: ref.cancelToken()),
  );

  Future<void> loadMore() => _more.load(
    ref,
    state.value,
    (page) => ref.read(placeRepositoryProvider).history(shopId, page: page),
    (next) => state = AsyncData(next),
  );
}
