import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/core/storage/cache_store.dart';
import 'package:eat/core/storage/device_id.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_repository.g.dart';

/// 发布菜品的结果.
///
/// [pending] 为 true 时菜品进入审核, 审核通过前没有公开记录, 详情接口返回 `BizCodes.foodNotFound`.
/// 服务端未启用内容审核时不返回审核状态, 菜品直接公开.
class const PublishResult({required final int id, final bool pending = false});

/// 菜品数据. 把接口 DTO 转换为 [Dish], 并缓存上一批推荐和浏览过的菜品详情.
class FoodRepository {
  FoodRepository(this._api, this._cache, this._deviceId);

  final FoodApi _api;
  final CacheStore _cache;
  final DeviceId _deviceId;

  static const _recommendGroup = 'recommend';
  static const _detailGroup = 'dish';

  /// 请求一批推荐.
  ///
  /// 未按分类筛选且结果非空时, 结果保存为该校区和饭点的 "上一批".
  /// 请求失败时, 页面使用 [lastBatch].
  ///
  /// 请求总是携带设备标识, 服务端只对游客使用该标识.
  /// 游客请求不带标识时, 服务端不记录推荐过的菜, 每次返回相同的菜.
  Future<List<Dish>> recommend({
    required int? campusId,
    required MealTime meal,
    DishCategory? category,
    CancelToken? cancelToken,
  }) async {
    final items = await _api.recommend(
      campusId: campusId,
      mealTime: meal.api,
      category: category?.api,
      deviceId: await _deviceId.read(),
      cancelToken: cancelToken,
    );
    if (category == null && items.isNotEmpty) {
      await _cache.write(
        _recommendGroup,
        '${campusId ?? 0}.${meal.api}',
        jsonEncode([for (final dto in items) dto.toJson()]),
        maxEntries: 8,
      );
    }
    return items.map(toDish).toList();
  }

  /// 该校区和饭点上次获取的推荐. 没有缓存时返回空列表.
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

  /// 缓存的菜品详情, 用于离线或请求返回前先行显示. 过期的缓存不返回.
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

  /// 按条件查询菜品. 传入 [near] 时每道菜带 [Dish.distance].
  ///
  /// 没有 [near] 时不发送 [FoodSort.distance], 因为后端对缺少坐标的距离排序返回参数错误.
  Future<Paged<Dish>> list({
    int? shopId,
    int? hubId,
    String? keyword,
    List<int>? myTagIds,
    List<int>? tasteTagIds,
    GcjPoint? near,
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
      systemTagIds: tasteTagIds,
      gcjLat: near?.lat,
      gcjLng: near?.lng,
      sort: near == null && sort == FoodSort.distance ? null : sort,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  Future<Paged<Dish>> favorites({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _map(await _api.favorites(page: page, cancelToken: cancelToken));

  Future<Paged<Dish>> mine({int page = 1, CancelToken? cancelToken}) async =>
      _map(await _api.mine(page: page, cancelToken: cancelToken));

  /// 上一次未成功的发布: 请求正文和所用的幂等键.
  ({String body, String key})? _unconfirmedPublish;

  /// 发布菜品.
  ///
  /// 请求带 `Idempotency-Key`. 正文与上一次未成功的发布相同时视为重试, 沿用上一次的键.
  /// 超时的请求可能已被服务端受理, 沿用键可避免重复发布.
  ///
  /// 正文不同时使用新键, 因为服务端拒绝同一个键对应不同正文的请求.
  /// 发布成功后清除记录, 下一份草稿使用新键.
  Future<PublishResult> publish(NewDish dish) async {
    final body = CreateFoodDto(
      restaurantId: dish.shopId,
      name: dish.name,
      pictureUrl: dish.imageKeys,
      price: dish.price,
      category: dish.category.api,
      mealTimes: [for (final meal in dish.mealTimes) meal.api],
      description: dish.description,
      systemTagIds: dish.tasteTagIds.isEmpty ? null : dish.tasteTagIds,
      myCustomTagNames: dish.myTagNames.isEmpty ? null : dish.myTagNames,
      stageColor: dish.stage.name,
      stageAlternates: [for (final c in dish.stageAlternates) c.name],
      coverCrop: _cropDto(roundCrop(dish.crop)),
    );
    final text = jsonEncode(body.toJson());
    final previous = _unconfirmedPublish;
    final key = previous != null && previous.body == text
        ? previous.key
        : newIdempotencyKey();
    _unconfirmedPublish = (body: text, key: key);
    final created = await _api.create(body, idempotencyKey: key);
    _unconfirmedPublish = null;
    return PublishResult(
      id: created.id,
      pending: created.moderationStatus == 'PENDING',
    );
  }

  static CoverCropDto _cropDto(CoverCrop crop) => CoverCropDto(
    centerX: crop.centerX,
    centerY: crop.centerY,
    diameter: crop.diameter,
  );

  /// 把裁切参数取整到 4 位小数. 原取景圈在照片内时, 取整后的取景圈也在照片内.
  ///
  /// 接口对裁切参数最多接受 4 位小数, 超出时以 10001 拒绝整个请求.
  /// 接口和本层都不知道照片尺寸, 因此只按方向取整, 不做四舍五入:
  /// - 直径向下取整, 取景圈只会变小.
  /// - 圆心向 0.5 取整, 只会远离照片边缘. 0.5 本身是 4 位小数, 圆心不会越过照片中线.
  static CoverCrop roundCrop(CoverCrop crop) => CoverCrop(
    centerX: _toward(crop.centerX, up: crop.centerX < 0.5),
    centerY: _toward(crop.centerY, up: crop.centerY < 0.5),
    diameter: _toward(crop.diameter, up: false),
  );

  /// 把 [value] 向上或向下取到 4 位小数.
  ///
  /// `value * 10000` 有浮点误差, 取整后校正一次, 保证结果不小于 (或不大于) [value].
  static double _toward(double value, {required bool up}) {
    const scale = 10000;
    if (up) {
      var n = (value * scale).ceil();
      if (n / scale < value) n++;
      return n / scale;
    }
    var n = (value * scale).floor();
    if (n / scale > value) n--;
    return n / scale;
  }

  /// 该店中与 [name] 同名 (忽略空白) 的菜品. 没有时返回 null.
  Future<Dish?> sameName(
    int shopId,
    String name, {
    CancelToken? cancelToken,
  }) async {
    final key = PublishRules.compactName(name);
    if (key.isEmpty) return null;
    final page = await list(
      shopId: shopId,
      keyword: key,
      pageSize: 50,
      cancelToken: cancelToken,
    );
    for (final dish in page.items) {
      if (PublishRules.compactName(dish.name) == key) return dish;
    }
    return null;
  }

  Future<void> setLiked(int id, {required bool liked}) =>
      liked ? _api.like(id) : _api.unlike(id);

  Future<void> setFavorite(int id, {required bool favorite}) =>
      favorite ? _api.favorite(id) : _api.unfavorite(id);

  Future<List<TasteTag>> tasteVocabulary({CancelToken? cancelToken}) async => [
    for (final dto in await _api.systemTags(cancelToken: cancelToken))
      if (dto.id != null && dto.name != null)
        TasteTag(id: dto.id!, name: dto.name!),
  ];

  /// 该菜品当前的口味标签和我的标签.
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

  /// 我写过的全部标签, 按接口顺序. 标签数量少, 一次获取全部, 最多请求 10 页.
  Future<List<MyTag>> myTags({CancelToken? cancelToken}) async {
    final tags = <MyTag>[];
    var page = 1;
    while (true) {
      final result = await _api.myTags(page: page, cancelToken: cancelToken);
      tags.addAll(_myTags(result.items));
      if (!result.hasNext || result.items.isEmpty || page >= 10) break;
      page++;
    }
    return tags;
  }

  Future<void> renameMyTag(int tagId, String name) =>
      _api.renameMyTag(tagId, name);

  Future<void> deleteMyTag(int tagId) => _api.deleteMyTag(tagId);

  /// 用我的标签 [tagId] 标过的菜, 跨店查询.
  Future<Paged<Dish>> taggedWith(
    int tagId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async =>
      _map(await _api.taggedWith(tagId, page: page, cancelToken: cancelToken));

  Future<Paged<Dish>> byUser(
    int userId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async =>
      _map(await _api.byUser(userId, page: page, cancelToken: cancelToken));

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
    final images = [
      for (final url in dto.pictureUrl ?? const <String>[]) ?imageUrl(url),
    ];
    final crop = _coverConfirmed(dto, images) ? dto.coverCrop : null;
    return Dish(
      id: dto.id ?? 0,
      name: dto.name?.trim() ?? '',
      shopId: dto.restaurantId ?? 0,
      shopName: _text(dto.restaurantName),
      shopAddress: _text(dto.restaurantAddress),
      shopPoint: lat != null && lng != null ? GcjPoint(lat, lng) : null,
      hubId: dto.hubId,
      hubName: _text(dto.hubName),
      distance: dto.distanceMeters,
      price: dto.price,
      category: category,
      mealTimes: [
        for (final meal in dto.mealTimes ?? const <String>[])
          ?MealTime.fromApi(meal),
      ],
      images: images,
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

  // TODO: 原封面未通过审核被滤掉时 pictureKeys 和 pictureUrl 都从第二张开始, 后端不提供标记, 裁切参数会应用到第二张图上. 后端提供封面标记后改为按标记判断.
  /// 显示的第一张图能否确认对应 pictureKeys 的第一张. 不能确认时不使用裁切, 按居中内切圆显示.
  ///
  /// pictureUrl 由 pictureKeys 逐个签名得到, 签名失败的图被跳过. 两者张数相同时才逐项对应.
  /// 张数不同时第一张图可能不是封面, 裁切参数只针对封面.
  static bool _coverConfirmed(FoodDto dto, List<String> images) =>
      images.isNotEmpty && dto.pictureKeys.length == images.length;

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
  DeviceId(ref.watch(secureStoreProvider)),
);
