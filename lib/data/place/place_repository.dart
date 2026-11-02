import 'package:dio/dio.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_repository.g.dart';

/// 校区, 商圈和店铺数据. 把 DTO 转换为领域模型.
///
/// 缺少坐标的条目直接丢弃, 因为它们无法显示在地图上, 也无法计算距离.
class PlaceRepository {
  PlaceRepository(this._api);

  final PlaceApi _api;

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

  /// 新建店铺. [photoKey] 为门头照片上传后的存储 key.
  ///
  /// [idempotencyKey] 由同一份草稿的各次提交共用, 内容变化后换新值.
  /// 返回的 `pending` 为 true 时店铺已进入审核, 尚未公开, 不能挂菜.
  Future<({int id, bool pending})> createShop({
    required String name,
    required String address,
    required GcjPoint point,
    required String idempotencyKey,
    int? hubId,
    String? photoKey,
  }) async {
    final created = await _api.createRestaurant(
      CreateRestaurantDto(
        name: name,
        address: address,
        gcjLng: point.lng,
        gcjLat: point.lat,
        hubId: hubId,
        pictureUrl: photoKey == null ? null : [photoKey],
      ),
      idempotencyKey: idempotencyKey,
    );
    return (id: created.id!, pending: created.moderationStatus == 'PENDING');
  }

  // TODO: 已有店名含空白而 [name] 不含时 (如已有 "麻辣 烫", 输入 "麻辣烫"), 关键词匹配不到已有店名. 店铺目录接口支持忽略空白匹配后改为只用一个关键词请求.
  /// [point] 周围 [radius] 米内与 [name] 同名 (忽略空白) 的店铺, 包括已关门的店. 没有时返回 null.
  ///
  /// 使用店铺目录接口, 因为搜店接口不返回已关门的店.
  /// 目录接口按子串匹配关键词, 不忽略空白.
  /// 因此 [name] 含空白时, 原名和去掉空白的名字各请求一次, 合并结果后比较. 最多两次请求.
  Future<Shop?> sameNameNearby(
    String name,
    GcjPoint point, {
    int? campusId,
    int radius = 200,
    CancelToken? cancelToken,
  }) async {
    final key = PublishRules.compactName(name);
    if (key.isEmpty) return null;
    final pages = await Future.wait([
      for (final keyword in {name.trim(), key})
        browseShops(
          keyword: keyword,
          campusId: campusId,
          near: point,
          radius: radius,
          cancelToken: cancelToken,
        ),
    ]);
    for (final shop in pages.expand((page) => page.items)) {
      if (PublishRules.compactName(shop.name) == key &&
          GeoRules.distance(point, shop.point) <= radius) {
        return shop;
      }
    }
    return null;
  }

  Future<Shop> shop(int id, {CancelToken? cancelToken}) async {
    final shop = _shop(await _api.restaurant(id, cancelToken: cancelToken));
    if (shop == null) {
      throw StateError('restaurant $id has no location');
    }
    return shop;
  }

  /// 搜索 [campusId] 校区内营业中的店. 不传 [sort] 时, 传入 [near] 按距离升序排列, 否则按新建时间倒序.
  ///
  /// [keyword] 同时匹配店名和菜名. [radius] 单位为米, 需要同时传入 [near], 为空时不限范围.
  /// 不传 [campusId] 时后端只查默认校区.
  ///
  /// 没有 [near] 时不发送 [radius] 和 [ShopSort.distance], 因为后端对缺少坐标的这两项返回参数错误.
  Future<Paged<Shop>> searchShops({
    GcjPoint? near,
    int? campusId,
    String? keyword,
    int? hubId,
    int? radius,
    Set<DishCategory> categories = const {},
    PriceBand? priceBand,
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
      categories: categories.isEmpty
          ? null
          : [for (final c in categories) c.api],
      priceBand: priceBand?.api,
      recommendedOnly: recommendedOnly ? true : null,
      favoritesOnly: favoritesOnly ? true : null,
      sort: near == null && sort == ShopSort.distance ? null : sort,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 店铺目录, 包含已关门的店, 已关门的店排在最后. 传入 [near] 时按距离升序排列, 否则按新建时间倒序.
  ///
  /// [keyword] 同时匹配店名和菜名. [radius] 单位为米, 需要同时传入 [near].
  Future<Paged<Shop>> browseShops({
    int? campusId,
    String? keyword,
    GcjPoint? near,
    int? radius,
    int page = 1,
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.browseRestaurants(
      campusId: campusId,
      keyword: keyword,
      gcjLat: near?.lat,
      gcjLng: near?.lng,
      radius: near == null ? null : radius,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 评价店铺, [rating] 为 null 时撤回. 返回服务端合并后的当前评价.
  Future<ShopRating?> rateShop(int id, ShopRating? rating) async =>
      ShopRating.fromApi(await _api.rateRestaurant(id, rating?.api));

  Future<void> setShopFavorite(int id, {required bool favorite}) =>
      _api.setRestaurantFavorite(id, favorite: favorite);

  /// 我收藏的店, 包含已关门的店, 已关门的店排在最后.
  Future<Paged<Shop>> favoriteShops({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.favoriteRestaurants(page: page, cancelToken: cancelToken),
  );

  Paged<Shop> _page(Paged<RestaurantDto> result) => Paged(
    items: [for (final dto in result.items) ?_shop(dto)],
    page: result.page,
    hasNext: result.hasNext,
  );

  Shop? _shop(RestaurantDto dto) {
    if (dto.id == null || dto.gcjLat == null || dto.gcjLng == null) {
      return null;
    }
    return Shop(
      id: dto.id!,
      name: dto.name?.trim() ?? '',
      address: dto.address?.trim().isEmpty ?? true ? null : dto.address!.trim(),
      point: GcjPoint(dto.gcjLat!, dto.gcjLng!),
      hubId: dto.hubId,
      photos: [
        for (final url in dto.pictureUrl ?? const <String>[]) ?imageUrl(url),
      ],
      status: _status(dto),
      dishCount: dto.visibleFoodCount,
      priceBand: PriceBand.fromApi(dto.priceBand),
      ratingCount: dto.ratingCount,
      recommendRate: dto.recommendationRate,
      signatures: [for (final f in dto.signatureFoods) ?_dish(f)],
      matched: [for (final f in dto.matchedFoods) ?_dish(f)],
      tastes: [
        for (final t in dto.publicTastes)
          if (t.tagId != null && (t.name?.isNotEmpty ?? false))
            ShopTaste(id: t.tagId!, name: t.name!, count: t.taggerCount ?? 0),
      ],
      cover: imageUrl(dto.coverUrl),
      myRating: ShopRating.fromApi(dto.myRating),
      favorite: dto.isFavorite ?? false,
    );
  }

  static ShopStatus _status(RestaurantDto dto) {
    if (dto.operatingStatus == 'CLOSED' || dto.permanentlyClosed == true) {
      return ShopStatus.closed;
    }
    if (dto.operatingStatus == 'SYNC_PENDING') return ShopStatus.pending;
    return ShopStatus.open;
  }

  ShopDish? _dish(RestaurantFoodDto dto) {
    if (dto.id == null || dto.name == null) return null;
    return ShopDish(
      id: dto.id!,
      name: dto.name!.trim(),
      price: dto.price,
      cover: imageUrl(dto.coverUrl),
      stage: StageColor.values.asNameMap()[dto.stageColor],
      likes: dto.likesCount ?? 0,
    );
  }

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

  /// MultiPolygon 中每个多边形的外环. 结构不符时返回空列表, 地图上不绘制范围.
  static List<List<WgsPoint>> _rings(GeoJsonDto? geometry) {
    if (geometry?.type != 'MultiPolygon') return const [];
    try {
      return [
        for (final polygon in geometry!.coordinates!)
          [
            for (final point
                in (polygon as List<dynamic>).first as List<dynamic>)
              WgsPoint(
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

@Riverpod(keepAlive: true)
PlaceRepository placeRepository(Ref ref) =>
    PlaceRepository(ref.watch(placeApiProvider));
