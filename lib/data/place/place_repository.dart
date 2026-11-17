import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/dish_revision.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_repository.g.dart';

/// 修改店铺的变更集合, 为 null 的字段保持原值不变.
///
/// [photo] 与 [priceBand] 支持清空操作, 因此采用单字段 record 包装: 外层 record 为 null 表示不修改, 内层字段为 null 表示清空.
class const ShopChange({
  final String? name,
  final String? address,

  /// 新门头照片上传后的存储 key.
  final ({String? key})? photo,
  final ShopKind? kind,
  final List<MealTime>? mealTimes,
  final ({PriceBand? band})? priceBand,
  final List<ShopCategory>? categories,
  final List<Taste>? tastes,
  final bool? closed,
}) {
  bool get isEmpty =>
      name == null &&
      address == null &&
      photo == null &&
      kind == null &&
      mealTimes == null &&
      priceBand == null &&
      categories == null &&
      tastes == null &&
      closed == null;
}

/// 地点数据仓库, 负责管理校区, 商圈和店铺数据并将接口 DTO 转换为领域模型.
///
/// 缺少坐标的条目无法在地图展示或参与距离计算, 因此在转换时直接丢弃.
class PlaceRepository {
  PlaceRepository(this._api, this._map);

  final PlaceApi _api;
  final MapEngine _map;

  /// 当前地图引擎是否支持地点检索; 若不可用, 新建店铺时直接进入手动填写.
  bool get canSearchPlaces => _map.available;

  /// 检索 [near] 周围 [radius] 米内匹配 [keyword] 的地图地点 (最多 20 条), 检索失败时抛出异常.
  Future<List<MapPlace>> mapPlaces(
    String keyword,
    GcjPoint near, {
    int radius = 3000,
  }) async {
    final pois = await _map.searchNearby(
      keyword,
      MapLatLng(near.lat, near.lng),
      radius: radius,
    );
    return [
      for (final p in pois)
        MapPlace(
          uid: p.uid,
          name: p.name.trim(),
          address: p.address.trim(),
          point: GcjPoint(p.point.lat, p.point.lng),
        ),
    ];
  }

  /// 查询可能与新建店铺重复的已有店铺, 匹配同一地图地点 [poi] 或 [point] 周围 200 m 内与 [name] 同名 (忽略空白与大小写) 的店铺.
  ///
  /// 同地点结果优先排列, 其余按距离排序; 若 [name] 为空且未提供 [poi], 则直接返回空列表.
  Future<List<ShopDuplicate>> duplicates(
    String name,
    GcjPoint point, {
    String? poi,
    CancelToken? cancelToken,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty && poi == null) return const [];
    final list = await _api.duplicates(
      name: trimmed.isEmpty ? null : trimmed,
      gcjLat: point.lat,
      gcjLng: point.lng,
      poi: poi,
      cancelToken: cancelToken,
    );
    return [for (final dto in list) ?_duplicate(dto)];
  }

  static ShopDuplicate? _duplicate(ShopDuplicateDto dto) {
    final id = dto.id;
    if (id == null) return null;
    return ShopDuplicate(
      id: id,
      name: dto.name?.trim() ?? '',
      address: dto.address?.trim() ?? '',
      distance: (dto.distanceMeters ?? 0).round(),
      closed: dto.permanentlyClosed ?? false,
      samePlace: dto.reason == 'poi',
    );
  }

  /// 获取已开放的校区列表, 按服务端设定的顺序排列.
  Future<List<Campus>> campuses({CancelToken? cancelToken}) async {
    final list = await _api.campuses(cancelToken: cancelToken);
    final sorted = [...list]
      ..sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
    return [
      for (final dto in sorted)
        if (dto.id != null && dto.gcjLat != null && dto.gcjLng != null)
          Campus(
            id: dto.id!,
            name: dto.name ?? '',
            center: GcjPoint(dto.gcjLat!, dto.gcjLng!),
            isDefault: dto.isDefault ?? false,
          ),
    ];
  }

  // TODO: 只请求第一页, 商圈数超过单页上限时后面的商圈会丢失. 商圈增多后改为按 `hasNext` 翻页取完.
  /// 获取全部商圈列表; 当前单个校区周边商圈数量较少, 仅通过单页请求获取.
  Future<List<Hub>> hubs({CancelToken? cancelToken}) async {
    final page = await _api.hubs(cancelToken: cancelToken);
    return [for (final dto in page.items) ?_hub(dto)];
  }

  /// 按 id 获取单个商圈. 商圈缺少坐标时返回 null.
  Future<Hub?> hub(int id, {CancelToken? cancelToken}) async =>
      _hub(await _api.hub(id, cancelToken: cancelToken));

  Future<Hub?> locateHub(GcjPoint point) async {
    final dto = await _api.locateHub(point.lat, point.lng);
    return dto == null ? null : _hub(dto);
  }

  /// 新建店铺并返回其 id, 所属商圈由服务端根据坐标自动计算.
  ///
  /// - [photoKey] 为门头照片上传后得到的存储 key.
  /// - 若省略 [mealTimes], 服务端默认按午饭和晚饭时段处理.
  /// - 若同一地图地点或 200 m 内已存在同名店铺, 服务端返回业务码 40017 并在 `data.duplicates` 中附带重复项 (见 [shopDuplicatesOf]); 用户确认非同一家后可置 [force] 为 true 重新提交.
  Future<int> createShop({
    required String name,
    required String address,
    required GcjPoint point,
    required ShopKind kind,
    String? poi,
    String? photoKey,
    List<MealTime>? mealTimes,
    PriceBand? priceBand,
    List<ShopCategory>? categories,
    List<Taste>? tastes,
    bool force = false,
  }) => _api.createRestaurant(
    CreateRestaurantDto(
      name: name,
      address: address,
      gcjLng: point.lng,
      gcjLat: point.lat,
      poi: poi,
      picture: photoKey,
      kind: kind.api,
      mealTimes: mealTimes == null ? null : [for (final m in mealTimes) m.api],
      priceBand: priceBand?.api,
      categories: categories == null
          ? null
          : [for (final c in categories) c.api],
      tags: tastes == null ? null : [for (final t in tastes) t.api],
      force: force ? true : null,
    ),
  );

  /// 提交 [change] 中指定的店铺改动; 若内容未发生实际变更, 服务端不生成修改记录并返回 false.
  ///
  /// 编辑店铺时不触发查重, 确属重复的店铺通过信息纠错流程处理.
  Future<bool> editShop(int id, ShopChange change) async {
    final edited = await _api.editRestaurant(
      id,
      EditRestaurantDto(
        name: change.name,
        address: change.address,
        picture: switch (change.photo) {
          null => null,
          (:final key) => key ?? '',
        },
        kind: change.kind?.api,
        mealTimes: change.mealTimes == null
            ? null
            : [for (final m in change.mealTimes!) m.api],
        priceBand: switch (change.priceBand) {
          null => null,
          (:final band) => band?.api ?? '',
        },
        categories: change.categories == null
            ? null
            : [for (final c in change.categories!) c.api],
        tags: change.tastes == null
            ? null
            : [for (final t in change.tastes!) t.api],
        permanentlyClosed: change.closed,
      ),
    );
    return edited.revisionId != null;
  }

  /// 分页获取店铺的修改记录, 按时间倒序排列.
  Future<Paged<ShopRevision>> history(
    int id, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.restaurantHistory(
      id,
      page: page,
      cancelToken: cancelToken,
    );
    return Paged(
      items: [for (final dto in result.items) ?_revision(dto)],
      page: result.page,
      hasNext: result.hasNext,
      total: result.total,
    );
  }

  /// 将店铺内容恢复至修改记录 [revisionId] 时的状态.
  ///
  /// 若当前内容已与该版本一致, 则抛出 `BizCodes.stateNotAllowed`.
  Future<void> restore(int id, int revisionId) =>
      _api.restoreRestaurant(id, revisionId);

  Future<Shop> shop(int id, {CancelToken? cancelToken}) async {
    final shop = shopOf(await _api.restaurant(id, cancelToken: cancelToken));
    if (shop == null) {
      throw StateError('restaurant $id has no location');
    }
    return shop;
  }

  // TODO: 搜店接口尚未排除已关门店铺, 也不会将其排在末尾. 后端提供排除参数后, 附近和选店改用该参数而不再在客户端过滤.
  /// 搜索店铺 (包含已关门店铺); 未指定 [sort] 时, 若传入 [near] 则按距离升序排列, 否则按创建时间倒序.
  ///
  /// - [keyword] 匹配店名, 地址和店内菜品名称, 因菜名命中的店铺会附带 [Shop.matchedDish].
  /// - [radius] 单位为米, 需配合 [near] 使用, 为 null 时不限制半径.
  /// - [categories] 和 [tastes] 各自满足任一取值即可命中; [delivery] 为 true 时仅保留支持外卖或有外卖评价的店铺.
  /// - [recommendedOnly] 为 true 时仅保留任一场景至少有 3 条评价且推荐率不低于 70% 的店铺.
  ///
  /// 若未传入 [near], 则不发送 [radius] 和 [ShopSort.distance], 避免后端因缺少坐标而返回参数错误.
  Future<Paged<Shop>> searchShops({
    GcjPoint? near,
    String? keyword,
    int? hubId,
    int? radius,
    ShopKind? kind,
    Set<ShopCategory> categories = const {},
    Set<Taste> tastes = const {},
    PriceBand? priceBand,
    bool delivery = false,
    bool recommendedOnly = false,
    bool favoritesOnly = false,
    ShopSort? sort,
    int page = 1,
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.searchRestaurants(
      keyword: keyword,
      hubId: hubId,
      gcjLat: near?.lat,
      gcjLng: near?.lng,
      radius: near == null ? null : radius,
      kind: kind?.api,
      categories: categories.isEmpty
          ? null
          : [for (final c in categories) c.api],
      tags: tastes.isEmpty ? null : [for (final t in tastes) t.api],
      priceBand: priceBand?.api,
      delivery: delivery ? true : null,
      recommendedOnly: recommendedOnly ? true : null,
      favoritesOnly: favoritesOnly ? true : null,
      sort: near == null && sort == ShopSort.distance ? null : sort,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 提交或撤回店铺在 [scene] 场景下的评价 ([rating] 为 null 时撤回), 返回服务端合并后的双场景个人评价.
  Future<MyShopRatings> rateShop(
    int id,
    RatingScene scene,
    ShopRating? rating,
  ) async {
    final mine = await _api.rateRestaurant(
      id,
      scene: scene.api,
      rating: rating?.api,
    );
    return _myRatings(mine);
  }

  Future<void> setShopFavorite(int id, {required bool favorite}) =>
      _api.setRestaurantFavorite(id, favorite: favorite);

  /// 分页获取当前用户收藏的店铺 (含已关门店铺), 按收藏时间倒序排列.
  Future<Paged<Shop>> favoriteShops({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.favoriteRestaurants(page: page, cancelToken: cancelToken),
  );

  /// 将店铺或推荐卡片的 JSON 解析为 [Shop], 缺少 id 或坐标时返回 null.
  static Shop? shopFromJson(Map<String, dynamic> json) =>
      shopOf(RestaurantDto.fromJson(json));

  /// 将店铺或推荐卡片 DTO 转换为 [Shop], 缺少 id 或坐标时返回 null.
  ///
  /// 未知的品类, 口味和饭点值会被忽略; 未知的店铺类型按默认值 [ShopKind.food] 处理, 以兼容后端后续新增枚举值.
  static Shop? shopOf(RestaurantDto dto) {
    if (dto.id == null || dto.gcjLat == null || dto.gcjLng == null) {
      return null;
    }
    return Shop(
      id: dto.id!,
      name: dto.name?.trim() ?? '',
      address: _text(dto.address),
      point: GcjPoint(dto.gcjLat!, dto.gcjLng!),
      poi: _text(dto.poi),
      photo: imageUrl(dto.pictureUrl),
      hubId: dto.hubId,
      hubName: _text(dto.hubName),
      kind: ShopKind.fromApi(dto.kind) ?? ShopKind.food,
      mealTimes: [
        for (final m in dto.mealTimes ?? const <String>[]) ?MealTime.fromApi(m),
      ],
      priceBand: PriceBand.fromApi(dto.priceBand),
      categories: [
        for (final c in dto.categories ?? const <String>[])
          ?ShopCategory.fromApi(c),
      ],
      tastes: [for (final t in dto.tags ?? const <String>[]) ?Taste.fromApi(t)],
      deliveryEnabled: dto.deliveryEnabled ?? false,
      dineIn: _stat(dto.dineIn),
      delivery: _stat(dto.delivery),
      myRatings: dto.myRatings == null ? null : _myRatings(dto.myRatings!),
      favorite: dto.isFavorite,
      closed: dto.permanentlyClosed ?? false,
      signatures: [
        for (final f in dto.signatureFoods ?? const <SignatureFoodDto>[])
          if (f.id != null && f.name != null)
            ShopDish(
              id: f.id!,
              name: f.name!.trim(),
              price: f.price,
              photo: imageUrl(f.pictureUrl),
              crop: switch (f.coverCrop) {
                final crop? when imageUrl(f.pictureUrl) != null => CoverCrop(
                  centerX: crop.centerX ?? 0.5,
                  centerY: crop.centerY ?? 0.5,
                  diameter: crop.diameter ?? 1,
                ),
                _ => const CoverCrop(),
              },
              signature: f.signature ?? false,
              rating: DishRating(
                score: f.rating?.score,
                count: f.rating?.count ?? 0,
              ),
            ),
      ],
      matchedDish: switch (dto.matchedFood) {
        MatchedFoodDto(:final id?, :final name?) when name.trim().isNotEmpty =>
          ShopDish(id: id, name: name.trim(), price: dto.matchedFood!.price),
        _ => null,
      },
      distance: dto.distanceMeters?.round(),
    );
  }

  static String? _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static ShopStat _stat(StatDto? dto) =>
      ShopStat(rate: dto?.rate, count: dto?.count ?? 0);

  static MyShopRatings _myRatings(MyRatingsDto dto) => MyShopRatings(
    dineIn: ShopRating.fromApi(dto.dineIn),
    delivery: ShopRating.fromApi(dto.delivery),
  );

  static ShopRevision? _revision(RevisionDto dto) {
    if (dto.id == null) return null;
    return ShopRevision(
      id: dto.id!,
      action: RevisionAction.fromApi(dto.action),
      editorId: dto.editor?.id,
      editorName: _text(dto.editor?.displayName),
      editorAvatar: imageUrl(dto.editor?.avatar),
      restoredFrom: dto.restoredFrom,
      fields: {
        for (final change in dto.changes ?? const <FieldChangeDto>[])
          ?ShopField.fromApi(change.field),
      }.toList(),
      createdAt: dateFromMillis(dto.createdAt),
    );
  }

  Paged<Shop> _page(Paged<RestaurantDto> result) => Paged(
    items: [for (final dto in result.items) ?shopOf(dto)],
    page: result.page,
    hasNext: result.hasNext,
    total: result.total,
  );

  static Hub? _hub(HubDto dto) {
    if (dto.id == null || dto.gcjLat == null || dto.gcjLng == null) return null;
    return Hub(
      id: dto.id!,
      name: dto.name ?? '',
      center: GcjPoint(dto.gcjLat!, dto.gcjLng!),
      boundary: _rings(dto.boundary),
    );
  }

  /// 提取 GeoJSON MultiPolygon 中各多边形的外环坐标 (忽略内环孔洞); 若结构不符则返回空列表, 地图跳过绘制.
  static List<List<GcjPoint>> _rings(GeoJsonDto? geometry) {
    if (geometry?.type != 'MultiPolygon') return const [];
    try {
      return [
        for (final polygon in geometry!.coordinates!)
          [
            for (final point
                in (polygon as List<dynamic>).first as List<dynamic>)
              GcjPoint(
                ((point as List<dynamic>)[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ),
          ],
      ];
    } on Object {
      return const [];
    }
  }
}

/// 当新建店铺因疑似重复 (错误码 40017) 被拒绝时, 从失败对象中提取重复店铺列表; 其他失败返回 null.
List<ShopDuplicate>? shopDuplicatesOf(AppFailure failure) => switch (failure) {
  AppFailure(
    code: BizCodes.shopMayExist,
    data: {'duplicates': final List<Object?> list},
  ) =>
    [
      for (final item in list)
        if (item is Map<String, dynamic>)
          ?PlaceRepository._duplicate(ShopDuplicateDto.fromJson(item)),
    ],
  AppFailure(code: BizCodes.shopMayExist) => const [],
  _ => null,
};

@Riverpod(keepAlive: true)
PlaceRepository placeRepository(Ref ref) =>
    PlaceRepository(ref.watch(placeApiProvider), ref.watch(mapEngineProvider));
