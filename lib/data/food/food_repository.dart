import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_repository.g.dart';

/// 菜：把接口的 DTO 转成 [Dish]，并缓存上一批推荐和看过的菜品详情（技术架构 10.1）。
class FoodRepository {
  FoodRepository(this._api, this._cache, this._assetBaseUrl);

  final FoodApi _api;
  final CacheStore _cache;
  final String _assetBaseUrl;

  static const _recommendGroup = 'recommend';
  static const _detailGroup = 'dish';

  /// 推荐一批。拿到了就存成这个校区和饭点的「上一批」，拿不到时页面用 [lastBatch]。
  Future<List<Dish>> recommend({
    required int? campusId,
    required MealTime meal,
    DishCategory? category,
    CancelToken? cancelToken,
  }) async {
    final page = await _api.recommend(
      campusId: campusId,
      mealTime: meal.api,
      category: category?.api,
      cancelToken: cancelToken,
    );
    if (category == null && page.items.isNotEmpty) {
      await _cache.write(
        _recommendGroup,
        '${campusId ?? 0}.${meal.api}',
        jsonEncode([for (final dto in page.items) dto.toJson()]),
        maxEntries: 8,
      );
    }
    return page.items.map(toDish).toList();
  }

  /// 这个校区和饭点上一次拿到的那批推荐；没有返回空列表。
  Future<List<Dish>> lastBatch({
    required int? campusId,
    required MealTime meal,
  }) async {
    final raw = await _cache.read(
      _recommendGroup,
      '${campusId ?? 0}.${meal.api}',
    );
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List<dynamic>)
          toDish(FoodDto.fromJson(e as Map<String, dynamic>)),
      ];
    } on Object {
      return const [];
    }
  }

  Future<Dish> detail(int id, {CancelToken? cancelToken}) async {
    final dto = await _api.detail(id, cancelToken: cancelToken);
    await _cache.write(
      _detailGroup,
      '$id',
      jsonEncode(dto.toJson()),
      maxEntries: 50,
    );
    return toDish(dto);
  }

  /// 7 天内看过的这道菜，离线时先显示。
  Future<Dish?> cachedDetail(int id) async {
    final raw = await _cache.read(
      _detailGroup,
      '$id',
      maxAge: const Duration(days: 7),
    );
    if (raw == null) return null;
    try {
      return toDish(FoodDto.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } on Object {
      return null;
    }
  }

  Future<Paged<Dish>> list({
    int? shopId,
    int? hubId,
    String? keyword,
    List<int>? myTagIds,
    FoodSort? sort,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => _map(
    await _api.list(
      restaurantId: shopId,
      hubId: hubId,
      keyword: keyword,
      myCustomTagIds: myTagIds,
      sort: sort,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 一家店的全部菜，按赞数排。餐厅详情要用全部菜算招牌和口味汇总，接口没有汇总字段（现状差距 2.1），
  /// 所以一次拉完，最多 [limit] 道。
  Future<List<Dish>> menu(
    int shopId, {
    int limit = 200,
    CancelToken? cancelToken,
  }) async {
    final dishes = <Dish>[];
    var page = 1;
    while (dishes.length < limit) {
      final result = await list(
        shopId: shopId,
        sort: FoodSort.popular,
        page: page,
        pageSize: 50,
        cancelToken: cancelToken,
      );
      dishes.addAll(result.items);
      if (!result.hasNext || result.items.isEmpty) break;
      page++;
    }
    return dishes;
  }

  Future<Paged<Dish>> favorites({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _map(await _api.favorites(page: page, cancelToken: cancelToken));

  Future<Paged<Dish>> mine({int page = 1, CancelToken? cancelToken}) async =>
      _map(await _api.mine(page: page, cancelToken: cancelToken));

  Future<void> setLiked(int id, {required bool liked}) =>
      liked ? _api.like(id) : _api.unlike(id);

  Future<void> setFavorite(int id, {required bool favorite}) =>
      favorite ? _api.favorite(id) : _api.unfavorite(id);

  /// 口味词表。
  Future<List<TasteTag>> tasteVocabulary({CancelToken? cancelToken}) async => [
    for (final dto in await _api.systemTags(cancelToken: cancelToken))
      if (dto.id != null && dto.name != null)
        TasteTag(id: dto.id!, name: dto.name!),
  ];

  /// 这道菜现在的口味标签和我的标签。
  Future<({List<TasteTag> taste, List<MyTag> mine})> tagsOf(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final dto = await _api.tagsOf(id, cancelToken: cancelToken);
    return (taste: _tasteTags(dto.systemTags), mine: _myTags(dto.myCustomTags));
  }

  Future<void> addTasteTags(int id, List<int> tagIds) =>
      _api.addSystemTags(id, tagIds);

  Future<void> addMyTags(int id, List<String> names) =>
      _api.addCustomTags(id, names);

  Future<void> removeTag(int id, int tagId) => _api.removeTag(id, tagId);

  Paged<Dish> _map(Paged<FoodDto> page) => Paged(
    items: page.items.map(toDish).toList(),
    page: page.page,
    hasNext: page.hasNext,
  );

  Dish toDish(FoodDto dto) {
    final category = DishCategory.fromApi(dto.category);
    final stage = StageColor.values.asNameMap()[dto.stageColor];
    final lat = dto.restaurantGcjLat;
    final lng = dto.restaurantGcjLng;
    final crop = dto.coverCrop;
    return Dish(
      id: dto.id ?? 0,
      name: dto.name?.trim() ?? '',
      shopId: dto.restaurantId ?? 0,
      shopName: _text(dto.restaurantName),
      shopAddress: _text(dto.restaurantAddress),
      shopPoint: lat != null && lng != null ? GcjPoint(lat, lng) : null,
      hubId: dto.hubId,
      hubName: _text(dto.hubName),
      price: dto.price,
      category: category,
      mealTimes: [
        for (final meal in dto.mealTimes ?? const <String>[])
          ?MealTime.fromApi(meal),
      ],
      images: [
        for (final url in dto.pictureUrl ?? const <String>[])
          ?resolveImageUrl(url, _assetBaseUrl),
      ],
      stage: stage ?? category?.stage ?? StageColor.broth,
      stageAlternates: [
        for (final name in dto.stageAlternates ?? const <String>[])
          ?StageColor.values.asNameMap()[name],
      ],
      crop: crop == null
          ? const CoverCrop()
          : CoverCrop(
              centerX: crop.centerX ?? 0.5,
              centerY: crop.centerY ?? 0.5,
              diameter: crop.diameter ?? 1,
            ),
      tasteTags: _tasteTags(dto.systemTags),
      myTags: _myTags(dto.myCustomTags),
      liked: dto.isLiked ?? false,
      favorite: dto.isFavorite ?? false,
      likes: dto.likesCount ?? 0,
      uploaderId: dto.accountId,
      uploaderName: _text(dto.uploaderName),
      description: _text(dto.description),
      createdAt: dateFromMillis(dto.createdAt),
    );
  }

  static List<TasteTag> _tasteTags(List<FoodTagDto>? tags) => [
    for (final tag in tags ?? const <FoodTagDto>[])
      if (tag.id != null && tag.name != null)
        TasteTag(
          id: tag.id!,
          name: tag.name!,
          count: tag.count ?? 0,
          mine: tag.taggedByMe ?? false,
        ),
  ]..sort((a, b) => b.count.compareTo(a.count));

  static List<MyTag> _myTags(List<FoodTagDto>? tags) => [
    for (final tag in tags ?? const <FoodTagDto>[])
      if (tag.id != null && tag.name != null)
        MyTag(id: tag.id!, name: tag.name!, usage: tag.usageCount),
  ];

  static String? _text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}

@Riverpod(keepAlive: true)
FoodRepository foodRepository(Ref ref) => FoodRepository(
  ref.watch(foodApiProvider),
  ref.watch(cacheStoreProvider),
  ref.watch(appConfigProvider).assetBaseUrl,
);
