import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_api.g.dart';

/// 店铺列表的排序. [api] 是接口中的取值.
enum ShopSort {
  /// 距离升序, 需要坐标.
  distance('DISTANCE'),

  /// 新建时间倒序.
  newest('NEWEST');

  const new(this.api);

  final String api;
}

/// PlaceApi 调用的接口路径, 相对于业务接口地址.
abstract final class PlaceEndpoints {
  static const campuses = '/campus/list';
  static const hubs = '/hub/list';
  static const locateHub = '/hub/locate';
  static const addRestaurant = '/restaurant/add';
  static const duplicates = '/restaurant/duplicates';
  static String editRestaurant(int id) => '/restaurant/edit/$id';
  static String restaurant(int id) => '/restaurant/detail/$id';
  static const searchRestaurants = '/restaurant/search';
  static String restaurantRating(int id) => '/restaurant/$id/rating';
  static String restaurantFavorite(int id) => '/restaurant/$id/favorite';
  static const favoriteRestaurants = '/restaurant/favorites';
  static String restaurantHistory(int id) => '/restaurant/$id/history';
  static String restoreRestaurant(int id, int revisionId) =>
      '/restaurant/$id/history/$revisionId/restore';
}

/// 地点相关的三个接口分组: Campus (校区), Hub (商圈), Restaurant (店铺的浏览, 搜索, 新建和修改).
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

  /// 查询坐标所在的商圈. 不在任何商圈内时返回 null.
  Future<HubDto?> locateHub(double gcjLat, double gcjLng) async {
    final data = await _client.get(
      PlaceEndpoints.locateHub,
      query: {'gcjLat': gcjLat, 'gcjLng': gcjLng},
    );
    return data == null ? null : decodeJson(data, HubDto.fromJson);
  }

  /// 新建店时可能重复的店: 同一个地图地点 [poi], 或 200 m 内与 [name] 同名. 同地点的在前, 其余按距离.
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

  /// 新建店铺, 返回店铺 id. 店铺发布即公开.
  Future<int> createRestaurant(CreateRestaurantDto body) async =>
      decodeCreatedId(
        await _client.post(PlaceEndpoints.addRestaurant, body: body.toJson()),
      );

  /// 修改店铺. 认证用户都能修改任何店铺.
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

  /// 搜店, 包含已关门的店. [keyword] 匹配店名和地址.
  ///
  /// - 坐标可选, 必须成对传入. 不传 [sort] 时, 带坐标按距离升序排列, 不带按新建时间倒序.
  /// - [radius] 和 [ShopSort.distance] 都需要坐标.
  /// - 传入 [campusId] 时只查该校区. 默认校区还包括不属于任何商圈的店.
  /// - [categories] 和 [tags] 各自命中任一即可.
  /// - [delivery] 只保留开了外卖或有人评过外卖的店.
  /// - [recommendedOnly] 只保留任一场景至少 3 条评价且推荐率不低于 70% 的店.
  /// - [favoritesOnly] 只保留当前账号收藏的店, 游客传入时返回未登录.
  /// - 不同筛选条件之间为 "与" 关系.
  Future<Paged<RestaurantDto>> searchRestaurants({
    double? gcjLat,
    double? gcjLng,
    int? campusId,
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
      PlaceEndpoints.searchRestaurants,
      query: {
        'campusId': ?campusId,
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

  /// 评价店铺在 [scene] 场景下的体验, [rating] 为 null 时撤回. 返回本人在两个场景的评价.
  ///
  /// 评价要求已认证, 撤回只要求登录.
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

  /// 收藏或取消收藏店铺. 收藏要求已认证, 取消只要求登录.
  Future<void> setRestaurantFavorite(int id, {required bool favorite}) =>
      favorite
      ? _client.put(PlaceEndpoints.restaurantFavorite(id))
      : _client.delete(PlaceEndpoints.restaurantFavorite(id));

  /// 我收藏的店, 包含已关门的店, 按收藏时间倒序.
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

  /// 店铺的修改记录, 最新的在前. 不需要登录.
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

  /// 把店铺恢复到某条修改记录之后的内容, 记为一次新的修改.
  ///
  /// 当前内容已经是该版本时返回 `BizCodes.stateNotAllowed`.
  Future<EditedRestaurantDto> restoreRestaurant(int id, int revisionId) async =>
      decodeJson(
        await _client.post(PlaceEndpoints.restoreRestaurant(id, revisionId)),
        EditedRestaurantDto.fromJson,
      );
}

@Riverpod(keepAlive: true)
PlaceApi placeApi(Ref ref) => PlaceApi(ref.watch(apiClientProvider));
