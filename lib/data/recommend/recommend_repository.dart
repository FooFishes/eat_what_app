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

/// 店铺推荐仓库, 负责将推荐卡片解析为附带招牌菜与距离的 [Shop].
///
/// 每次请求的非空结果会按校区, 场景, 饭点与类型分别缓存为 "上一批", 以便请求失败时通过 [lastBatch] 降级展示.
class RecommendRepository {
  RecommendRepository(this._api, this._cache);

  final RecommendApi _api;
  final CacheStore _cache;

  static const _group = 'recommend';

  /// 获取一批推荐店铺, 缺少 id 或坐标的卡片将在转换时丢弃.
  ///
  /// 翻页请求固定传入 `page + 1`:
  /// - 游客按页码顺序翻页, 当日内排序保持不变.
  /// - 登录用户每次获取当日尚未推荐过的店铺, 页码仅作回显; 该去重池不区分校区, 场景, 饭点与类型, 且转盘与抽屉列表共用. 当日候选全部推荐完后服务端会重新循环, 此时可能返回重复店铺, 需由调用方去重.
  ///
  /// [near] 为当前位置坐标; 传入时堂食仅推荐 3000 m 内店铺, 外卖仅推荐 5000 m 内店铺.
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

  /// 读取指定校区, 场景, 饭点与类型对应的最近一次成功缓存; 若无缓存或解析失败则返回空列表.
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

  /// 摇一摇: 随机推荐一家店, 参数含义同 [recommend]; 没有候选或卡片缺少 id, 坐标时返回 null.
  ///
  /// 结果不写入 "上一批" 缓存.
  Future<Shop?> pick({
    required RatingScene scene,
    required MealTime meal,
    ShopKind kind = ShopKind.food,
    int? campusId,
    GcjPoint? near,
    CancelToken? cancelToken,
  }) async {
    final picked = await _api.pick(
      scene: scene.api,
      gcjLat: near?.lat,
      gcjLng: near?.lng,
      campusId: campusId,
      mealTime: meal.api,
      kind: kind.api,
      cancelToken: cancelToken,
    );
    final json = picked.restaurant;
    if (json == null) return null;
    try {
      return PlaceRepository.shopFromJson(json);
    } on Object catch (e) {
      throw AppFailure(FailureKind.unknown, serverMessage: '$e');
    }
  }

  /// 标记该店铺 30 天内不再推荐, 需登录账号.
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
