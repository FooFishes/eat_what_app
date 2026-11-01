import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_api.g.dart';

/// 地点相关的三个接口分组: Campus (校区), Hub (商圈), Restaurant (餐厅的浏览, 搜索和新建).
class PlaceApi {
  PlaceApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /campus/list',
    'GET /hub/list',
    'GET /hub/locate',
    'GET /restaurant/detail/{id}',
    'GET /restaurant/search',
    'POST /restaurant/add',
  ];

  Future<List<CampusDto>> campuses({CancelToken? cancelToken}) async =>
      decodeList(
        await _client.get('/campus/list', cancelToken: cancelToken),
        CampusDto.fromJson,
      );

  Future<Paged<HubDto>> hubs({
    int page = 1,
    int pageSize = 100,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/hub/list',
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    HubDto.fromJson,
  );

  /// 查询坐标所在的商圈. 不在任何商圈内时返回 null.
  Future<HubDto?> locateHub(double gcjLat, double gcjLng) async {
    final data = await _client.get(
      '/hub/locate',
      query: {'gcjLat': gcjLat, 'gcjLng': gcjLng},
    );
    return data == null ? null : decodeJson(data, HubDto.fromJson);
  }

  /// 新建店铺, 返回店铺 id.
  Future<int> createRestaurant(CreateRestaurantDto body) async =>
      decodeCreatedId(
        await _client.post('/restaurant/add', body: body.toJson()),
      );

  Future<RestaurantDto> restaurant(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get('/restaurant/detail/$id', cancelToken: cancelToken),
        RestaurantDto.fromJson,
      );

  /// 按店名, 商圈或位置搜索店铺. 传入位置时按与该位置的距离排序, [radius] 单位为米.
  Future<Paged<RestaurantDto>> searchRestaurants({
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
      '/restaurant/search',
      query: {
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
}

@Riverpod(keepAlive: true)
PlaceApi placeApi(Ref ref) => PlaceApi(ref.watch(apiClientProvider));
