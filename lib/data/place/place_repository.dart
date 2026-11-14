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

/// 修改店铺时的改动. 字段为 null 表示不修改.
///
/// [photo] 和 [priceBand] 可以清除, 因此包一层记录: 记录为 null 表示不修改, 记录里的值为 null 表示清除.
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
  final bool? deliveryEnabled,
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
      deliveryEnabled == null &&
      closed == null;
}

/// 校区, 商圈和店铺数据. 把 DTO 转换为领域模型.
///
/// 缺少坐标的条目直接丢弃, 因为它们无法显示在地图上, 也无法计算距离.
class PlaceRepository {
  PlaceRepository(this._api, this._map);

  final PlaceApi _api;
  final MapEngine _map;

  /// 地图上能否检索地点. 不能时新建店直接手动添加.
  bool get canSearchPlaces => _map.available;

  /// [near] 周围 [radius] 米内和 [keyword] 匹配的地图地点, 最多 20 个. 检索失败时抛出异常.
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

  /// 新建店时可能重复的店: 同一个地图地点 [poi], 或 [point] 200 m 内与 [name] 同名 (忽略空白和大小写).
  ///
  /// 同地点的在前, 其余按距离. [name] 为空且没有 [poi] 时为空列表.
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

  /// 已开放的校区, 按运营设定的顺序排列.
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
  /// 全部商圈. 单个校区周边约十余个商圈, 因此一页取完.
  Future<List<Hub>> hubs({CancelToken? cancelToken}) async {
    final page = await _api.hubs(cancelToken: cancelToken);
    return [for (final dto in page.items) ?_hub(dto)];
  }

  Future<Hub?> locateHub(GcjPoint point) async {
    final dto = await _api.locateHub(point.lat, point.lng);
    return dto == null ? null : _hub(dto);
  }

  /// 新建店铺, 返回店铺 id. 所属商圈由后端按坐标计算.
  ///
  /// - [photoKey] 为门头照片上传后的存储 key.
  /// - 不传 [mealTimes] 时后端按午饭和晚饭处理.
  /// - 同一个地图地点已有店, 或 200 m 内有同名的店时, 后端返回 40017, `data.duplicates` 是这些店
  ///   (见 [shopDuplicatesOf]). 用户确认不是同一家后带 [force] 重新提交.
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
    bool? deliveryEnabled,
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
      deliveryEnabled: deliveryEnabled,
      force: force ? true : null,
    ),
  );

  /// 修改店铺, 只提交 [change] 中的字段. 内容没有变化时后端不记修改记录, 返回 false.
  ///
  /// 修改不查重, 真重复的店靠 "信息有误" 处理.
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
        deliveryEnabled: change.deliveryEnabled,
        permanentlyClosed: change.closed,
      ),
    );
    return edited.revisionId != null;
  }

  /// 店铺的修改记录, 最新的在前.
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

  /// 把店铺恢复到修改记录 [revisionId] 之后的内容.
  ///
  /// 当前内容已经是该版本时抛出 `BizCodes.stateNotAllowed`.
  Future<void> restore(int id, int revisionId) =>
      _api.restoreRestaurant(id, revisionId);

  Future<Shop> shop(int id, {CancelToken? cancelToken}) async {
    final shop = shopOf(await _api.restaurant(id, cancelToken: cancelToken));
    if (shop == null) {
      throw StateError('restaurant $id has no location');
    }
    return shop;
  }

  // TODO: 搜店接口不排除已关门的店, 也不把它们排在最后. 后端提供排除参数后, 附近和选店改用该参数, 不再在客户端过滤.
  /// 搜索 [campusId] 校区内的店, 包括已关门的店. 不传 [sort] 时, 传入 [near] 按距离升序排列, 否则按新建时间倒序.
  ///
  /// - [keyword] 匹配店名, 地址和店里的菜名. 因菜名命中的店带 [Shop.matchedDish].
  /// - [radius] 单位为米, 需要同时传入 [near], 为空时不限范围.
  /// - 不传 [campusId] 时后端不按校区限定范围.
  /// - [categories] 和 [tastes] 各自命中任一即可. [delivery] 只看能点外卖的店.
  /// - [recommendedOnly] 只看任一场景至少 3 条评价且推荐率不低于 70% 的店.
  ///
  /// 没有 [near] 时不发送 [radius] 和 [ShopSort.distance], 因为后端对缺少坐标的这两项返回参数错误.
  Future<Paged<Shop>> searchShops({
    GcjPoint? near,
    int? campusId,
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
      campusId: campusId,
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

  /// 评价店铺在 [scene] 场景下的体验, [rating] 为 null 时撤回. 返回服务端合并后本人在两个场景的评价.
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

  /// 我收藏的店, 包含已关门的店, 最近收藏的在前.
  Future<Paged<Shop>> favoriteShops({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.favoriteRestaurants(page: page, cancelToken: cancelToken),
  );

  /// 把店铺或推荐卡片的 JSON 转换为 [Shop]. 缺少 id 或坐标时返回 null.
  static Shop? shopFromJson(Map<String, dynamic> json) =>
      shopOf(RestaurantDto.fromJson(json));

  /// 把店铺或推荐卡片转换为 [Shop]. 缺少 id 或坐标时返回 null.
  ///
  /// 不认识的品类, 口味和饭点忽略. 不认识的类型按美食处理, 因为后端只在末尾追加取值, 美食是默认的类型.
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
      campusId: dto.campusId,
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
      campusId: dto.campusId,
      boundary: _rings(dto.boundary),
    );
  }

  /// MultiPolygon 中每个多边形的外环. 洞不绘制. 结构不符时返回空列表, 地图上不绘制范围.
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

/// 新建店被后端以 "可能已有这家店" (40017) 拒绝时, 响应里的已有店. 其他失败返回 null.
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
