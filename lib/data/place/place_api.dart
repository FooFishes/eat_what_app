import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_api.g.dart';

/// 店铺列表的排序方式, [api] 为对应的接口参数值.
enum ShopSort {
  /// 按距离升序排列, 需传入坐标.
  distance('DISTANCE'),

  /// 按创建时间倒序排列.
  newest('NEWEST');

  const new(this.api);

  final String api;
}

/// PlaceApi 调用的接口路径, 相对于业务接口地址.
abstract final class PlaceEndpoints {
  static const campuses = '/campus/list';
  static const hubs = '/hub/list';
  static String hub(int id) => '/hub/detail/$id';
  static const locateHub = '/hub/locate';
  static const addRestaurant = '/restaurant/add';
  static const duplicates = '/restaurant/duplicates';
  static String editRestaurant(int id) => '/restaurant/edit/$id';
  static String restaurant(int id) => '/restaurant/detail/$id';
  static const searchRestaurants = '/restaurant/search';
  static const browseRestaurants = '/restaurant/browse';
  static String restaurantRating(int id) => '/restaurant/$id/rating';
  static String restaurantFavorite(int id) => '/restaurant/$id/favorite';
  static const favoriteRestaurants = '/restaurant/favorites';
  static String restaurantHistory(int id) => '/restaurant/$id/history';
  static String restoreRestaurant(int id, int revisionId) =>
      '/restaurant/$id/history/$revisionId/restore';
}

/// 地点相关接口, 涵盖校区 (`Campus`), 商圈 (`Hub`) 以及店铺 (`Restaurant`) 的浏览, 搜索, 创建与编辑.
class PlaceApi {
  PlaceApi(this._client);

  final ApiClient _client;

  Future<List<CampusDto>> campuses({CancelToken? cancelToken}) async =>
      decodeList(
        await _client.get(PlaceEndpoints.campuses, cancelToken: cancelToken),
        CampusDto.fromJson,
      );

  Future<Paged<HubDto>> hubs({
    int page = 1,
    int pageSize = 100,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      PlaceEndpoints.hubs,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    HubDto.fromJson,
  );

  Future<HubDto> hub(int id, {CancelToken? cancelToken}) async => decodeJson(
    await _client.get(PlaceEndpoints.hub(id), cancelToken: cancelToken),
    HubDto.fromJson,
  );

  /// 查询指定坐标所在的商圈, 若不在任何商圈内则返回 null.
  Future<HubDto?> locateHub(double gcjLat, double gcjLng) async {
    final data = await _client.get(
      PlaceEndpoints.locateHub,
      query: {'gcjLat': gcjLat, 'gcjLng': gcjLng},
    );
    return data == null ? null : decodeJson(data, HubDto.fromJson);
  }

  /// 查询可能重复的已有店铺, 匹配同一地图地点 [poi] 或 200 m 内与 [name] 同名的店铺; 同地点结果优先, 其余按距离排序.
  Future<List<ShopDuplicateDto>> duplicates({
    String? name,
    required double gcjLat,
    required double gcjLng,
    String? poi,
    CancelToken? cancelToken,
  }) async => decodeList(
    await _client.get(
      PlaceEndpoints.duplicates,
      query: {'name': ?name, 'gcjLng': gcjLng, 'gcjLat': gcjLat, 'poi': ?poi},
      cancelToken: cancelToken,
    ),
    ShopDuplicateDto.fromJson,
  );

  /// 新建店铺并返回其 id; 店铺发布后即公开可见.
  Future<int> createRestaurant(CreateRestaurantDto body) async =>
      decodeCreatedId(
        await _client.post(PlaceEndpoints.addRestaurant, body: body.toJson()),
      );

  /// 修改店铺信息, 所有已认证用户均可编辑任意店铺.
  Future<EditedRestaurantDto> editRestaurant(
    int id,
    EditRestaurantDto body,
  ) async => decodeJson(
    await _client.put(PlaceEndpoints.editRestaurant(id), body: body.toJson()),
    EditedRestaurantDto.fromJson,
  );

  Future<RestaurantDto> restaurant(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(
          PlaceEndpoints.restaurant(id),
          cancelToken: cancelToken,
        ),
        RestaurantDto.fromJson,
      );

  /// 搜索店铺 (包含已关门店铺), 各筛选条件之间为 "与" 关系.
  ///
  /// 没有 [keyword] 时请求 `/restaurant/browse`, 否则请求 `/restaurant/search`. 两者是服务端的同一个查询, 参数和返回相同.
  /// - [keyword] 匹配店名, 地址和店内菜品名称, 因菜名命中的店铺会附带 `matchedFood`.
  /// - 坐标可选但必须成对传入; 未指定 [sort] 时, 传坐标按距离升序排列, 否则按创建时间倒序.
  /// - [radius] 和 [ShopSort.distance] 均需配合坐标使用.
  /// - [categories] 和 [tags] 各自满足任一取值即可命中.
  /// - [delivery] 为 true 时仅保留支持外卖或存在外卖评价的店铺.
  /// - [recommendedOnly] 为 true 时仅保留任一场景至少有 3 条评价且推荐率不低于 70% 的店铺.
  /// - [favoritesOnly] 为 true 时仅保留当前账号收藏的店铺, 游客传入将返回未登录错误.
  Future<Paged<RestaurantDto>> searchRestaurants({
    double? gcjLat,
    double? gcjLng,
    String? keyword,
    int? hubId,
    int? radius,
    String? kind,
    List<String>? categories,
    List<String>? tags,
    String? priceBand,
    bool? delivery,
    bool? recommendedOnly,
    bool? favoritesOnly,
    ShopSort? sort,
    int page = 1,
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      keyword == null || keyword.isEmpty
          ? PlaceEndpoints.browseRestaurants
          : PlaceEndpoints.searchRestaurants,
      query: {
        'keyword': ?keyword,
        'hubId': ?hubId,
        'gcjLat': ?gcjLat,
        'gcjLng': ?gcjLng,
        'radius': ?radius,
        'kind': ?kind,
        'categories': ?categories,
        'tags': ?tags,
        'priceBand': ?priceBand,
        'delivery': ?delivery,
        'recommendedOnly': ?recommendedOnly,
        'favoritesOnly': ?favoritesOnly,
        'sort': ?sort?.api,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    ),
    RestaurantDto.fromJson,
  );

  /// 提交或撤回店铺在 [scene] 场景下的评价, 并返回当前用户在两个场景的评价结果.
  ///
  /// [rating] 为 null 时表示撤回评价; 提交评价需完成身份认证, 撤回仅需登录.
  Future<MyRatingsDto> rateRestaurant(
    int id, {
    required String scene,
    String? rating,
  }) async => decodeJson(
    rating == null
        ? await _client.delete(
            PlaceEndpoints.restaurantRating(id),
            query: {'scene': scene},
          )
        : await _client.put(
            PlaceEndpoints.restaurantRating(id),
            body: RatingRequestDto(scene: scene, rating: rating).toJson(),
          ),
    MyRatingsDto.fromJson,
  );

  /// 收藏或取消收藏店铺; 收藏操作需完成身份认证, 取消收藏仅需登录.
  Future<void> setRestaurantFavorite(int id, {required bool favorite}) =>
      favorite
      ? _client.put(PlaceEndpoints.restaurantFavorite(id))
      : _client.delete(PlaceEndpoints.restaurantFavorite(id));

  /// 获取当前用户收藏的店铺列表 (含已关门店铺), 按收藏时间倒序排列.
  Future<Paged<RestaurantDto>> favoriteRestaurants({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      PlaceEndpoints.favoriteRestaurants,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    RestaurantDto.fromJson,
  );

  /// 分页获取店铺的修改记录, 按时间倒序排列, 无需登录即可访问.
  Future<Paged<RevisionDto>> restaurantHistory(
    int id, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      PlaceEndpoints.restaurantHistory(id),
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    RevisionDto.fromJson,
  );

  /// 将店铺内容恢复至指定修改记录时的状态, 并记为一次新的修改.
  ///
  /// 若当前内容已与该版本一致, 服务端返回 `BizCodes.stateNotAllowed`.
  Future<EditedRestaurantDto> restoreRestaurant(int id, int revisionId) async =>
      decodeJson(
        await _client.post(PlaceEndpoints.restoreRestaurant(id, revisionId)),
        EditedRestaurantDto.fromJson,
      );
}

@Riverpod(keepAlive: true)
PlaceApi placeApi(Ref ref) => PlaceApi(ref.watch(apiClientProvider));
