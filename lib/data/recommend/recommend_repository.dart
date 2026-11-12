import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/data/place/place_repository.dart';
import 'package:eat/data/recommend/recommend_api.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recommend_repository.g.dart';

/// 推荐店铺. 卡片按店铺的转换变成 [Shop], 带招牌菜和距离.
///
/// 每次拿到的非空结果保存为 "上一批", 按校区, 场景, 饭点和类型区分. 请求失败时页面用 [lastBatch] 显示.
class RecommendRepository {
  RecommendRepository(this._api, this._cache);

  final RecommendApi _api;
  final CacheStore _cache;

  static const _group = 'recommend';

  /// 一批推荐店铺. 缺少 id 或坐标的卡片丢弃.
  ///
  /// 下一批总是请求 `page + 1`:
  /// - 游客按页码翻页, 同一天的顺序不变.
  /// - 登录用户每次拿到当天还没推荐过的店, 页码只回显. 不分校区, 场景, 饭点和类型, 转盘和抽屉列表共用.
  ///   当天的候选都推荐过后, 后端从头再来, 可能返回已经拿到过的店, 由调用方去重.
  ///
  /// [near] 是我的位置. 带位置时堂食只推荐 3000 m 内的店, 外卖只推荐 5000 m 内的店.
  Future<Paged<Shop>> recommend({
    required RatingScene scene,
    required MealTime meal,
    ShopKind kind = ShopKind.food,
    int? campusId,
    GcjPoint? near,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    final feed = await _api.feed(
      scene: scene.api,
      gcjLat: near?.lat,
      gcjLng: near?.lng,
      campusId: campusId,
      mealTime: meal.api,
      kind: kind.api,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
    final items = feed.items ?? const <Map<String, dynamic>>[];
    final List<Shop> shops;
    try {
      shops = _shops(items);
    } on Object catch (e) {
      throw AppFailure(FailureKind.unknown, serverMessage: '$e');
    }
    if (items.isNotEmpty) {
      await _cache.write(
        _group,
        _key(campusId, scene, meal, kind),
        jsonEncode(items),
        maxEntries: 16,
      );
    }
    return Paged(
      items: shops,
      page: feed.currentPage ?? page,
      hasNext: feed.hasNext ?? false,
      total: feed.totalItems,
    );
  }

  /// 该校区, 场景, 饭点和类型上次拿到的一批. 没有缓存或缓存无法解析时返回空列表.
  Future<List<Shop>> lastBatch({
    required RatingScene scene,
    required MealTime meal,
    ShopKind kind = ShopKind.food,
    int? campusId,
  }) async {
    final raw = await _cache.read(_group, _key(campusId, scene, meal, kind));
    if (raw == null) return const [];
    try {
      return _shops([
        for (final e in jsonDecode(raw) as List<dynamic>)
          e as Map<String, dynamic>,
      ]);
    } on Object {
      return const [];
    }
  }

  /// 不想去这家: 30 天内不再推荐. 需要登录.
  Future<void> dismiss(int shopId) => _api.dismiss(shopId);

  static String _key(
    int? campusId,
    RatingScene scene,
    MealTime meal,
    ShopKind kind,
  ) => '${campusId ?? 0}.${scene.api}.${meal.api}.${kind.api}';

  static List<Shop> _shops(List<Map<String, dynamic>> items) => [
    for (final json in items) ?PlaceRepository.shopFromJson(json),
  ];
}

@Riverpod(keepAlive: true)
RecommendRepository recommendRepository(Ref ref) => RecommendRepository(
  ref.watch(recommendApiProvider),
  ref.watch(cacheStoreProvider),
);
