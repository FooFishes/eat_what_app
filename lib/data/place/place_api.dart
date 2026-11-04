import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_api.g.dart';

/// 店铺列表的排序. [api] 是接口中的取值. 同值时后端按店铺 id 倒序.
enum ShopSort {
  /// 距离升序, 需要坐标.
  distance('DISTANCE'),

  /// 推荐率降序. 没有推荐率的店排在最后.
  recommendation('RECOMMENDATION_RATE'),

  /// 可见菜数降序.
  dishCount('FOOD_COUNT');

  const new(this.api);

  final String api;
}

/// PlaceApi 调用的接口路径, 相对于业务接口地址.
abstract final class PlaceEndpoints {
  static const campuses = '/campus/list';
  static const hubs = '/hub/list';
  static const locateHub = '/hub/locate';
  static const addRestaurant = '/restaurant/add';
  static String restaurant(int id) => '/restaurant/detail/$id';
  static const searchRestaurants = '/restaurant/search';
  static const browseRestaurants = '/restaurant/browse';
  static String restaurantRating(int id) => '/restaurant/$id/rating';
  static String restaurantFavorite(int id) => '/restaurant/$id/favorite';
  static const favoriteRestaurants = '/restaurant/favorites';
}

/// 地点相关的三个接口分组: Campus (校区), Hub (商圈), Restaurant (餐厅的浏览, 搜索和新建).
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

  /// 新建店铺.
  ///
  /// [idempotencyKey] 是本次新建的 UUID. 超时重试同一份草稿时复用, 服务端据此去重.
  Future<CreatedRestaurantDto> createRestaurant(
    CreateRestaurantDto body, {
    required String idempotencyKey,
  }) async {
    final data = await _client.post(
      PlaceEndpoints.addRestaurant,
      body: body.toJson(),
      headers: {'Idempotency-Key': idempotencyKey},
    );
    final created = data is Map<String, dynamic>
        ? CreatedRestaurantDto.fromJson(data)
        : null;
    if (created == null || created.id == null) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no id');
    }
    return created;
  }

  Future<RestaurantDto> restaurant(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(
          PlaceEndpoints.restaurant(id),
          cancelToken: cancelToken,
        ),
        RestaurantDto.fromJson,
      );

  /// 搜索附近营业中的店. [keyword] 同时匹配店名和菜名, 不传 [campusId] 时只查默认校区.
  ///
  /// - 坐标可选, 必须成对传入. 不传 [sort] 时, 带坐标按距离升序排列, 不带按新建时间倒序.
  /// - [radius] 和 [ShopSort.distance] 都需要坐标.
  /// - [categories] 是菜品分类的接口取值, 店里有其中任一类菜即命中.
  /// - [recommendedOnly] 只保留推荐率不低于 80% 的店.
  /// - [favoritesOnly] 只保留当前账号收藏的店.
  /// - 不同筛选条件之间为 "与" 关系.
  Future<Paged<RestaurantDto>> searchRestaurants({
    double? gcjLat,
    double? gcjLng,
    int? campusId,
    String? keyword,
    int? hubId,
    int? radius,
    List<String>? categories,
    String? priceBand,
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
        'categories': ?categories,
        'priceBand': ?priceBand,
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

  /// 店铺目录, 包含已关门的店, 已关门的店排在最后.
  ///
  /// 传入坐标时按距离升序排列, 不传时按新建时间倒序. [keyword] 同时匹配店名和菜名.
  Future<Paged<RestaurantDto>> browseRestaurants({
    int? campusId,
    String? keyword,
    int? hubId,
    double? gcjLat,
    double? gcjLng,
    int? radius,
    int page = 1,
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      PlaceEndpoints.browseRestaurants,
      query: {
        'campusId': ?campusId,
        'keyword': ?keyword,
        'hubId': ?hubId,
        'gcjLat': ?gcjLat,
        'gcjLng': ?gcjLng,
        'radius': ?radius,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    ),
    RestaurantDto.fromJson,
  );

  /// 评价店铺, [rating] 为 null 时撤回. 返回服务端合并后的当前评价, 撤回后为 null.
  ///
  /// 评价要求已认证, 撤回只要求登录.
  Future<String?> rateRestaurant(int id, String? rating) async {
    final data = rating == null
        ? await _client.delete(PlaceEndpoints.restaurantRating(id))
        : await _client.put(
            PlaceEndpoints.restaurantRating(id),
            body: RestaurantRatingDto(rating: rating).toJson(),
          );
    return data is Map<String, dynamic>
        ? RestaurantRatingDto.fromJson(data).rating
        : null;
  }

  /// 收藏或取消收藏店铺. 收藏要求已认证, 取消只要求登录.
  Future<void> setRestaurantFavorite(int id, {required bool favorite}) =>
      favorite
      ? _client.put(PlaceEndpoints.restaurantFavorite(id))
      : _client.delete(PlaceEndpoints.restaurantFavorite(id));

  /// 我收藏的店, 包含已关门的店. 按营业中, 同步中, 已关门分组, 组内按新建时间倒序.
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
}

@Riverpod(keepAlive: true)
PlaceApi placeApi(Ref ref) => PlaceApi(ref.watch(apiClientProvider));
