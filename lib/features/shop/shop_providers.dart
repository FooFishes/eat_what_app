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

/// 分页列表状态, 包含当前已加载的分页数据及加载下一页失败的原因.
class const LoadedPages<T>({
  required final Paged<T> pages,
  final AppFailure? moreError,
});

/// 通用分页加载器, 保证同一时刻仅发起一次 [fetch] 请求, 失败时将异常记录在 [LoadedPages.moreError] 中.
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

/// 指定店铺的全部菜品分页列表, 按菜单顺序排序 (招牌菜优先, 其次按分类及赞数).
///
/// [LoadedPages.pages] 中的 total 即该店菜品总数. 发布新菜后会自动失效并重新请求, 离开页面后缓存保留 5 分钟.
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

/// 当前用户对指定店铺的评价与收藏状态.
class const ShopMine({
  final MyShopRatings ratings = const MyShopRatings(),
  final bool favorite = false,
});

/// 管理当前用户对指定店铺的评价与收藏状态, 操作时采用乐观更新并在失败时回滚.
///
/// 仅订阅店铺详情中的个人评价与收藏两个字段, 避免评价成功后重新请求店铺详情期间旧数据覆盖本地乐观值.
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

  /// 提交或撤回 [scene] 场景下的评价 ([rating] 为 null 表示撤回).
  ///
  /// 成功时返回 null 并重新请求店铺详情以同步推荐率, 失败时恢复原值并返回失败原因.
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

/// 指定店铺的修改记录分页列表, 按时间倒序排列.
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
