import 'package:eat_what_app/core/network/api_parser.dart';
import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant_dto.dart';

class RestaurantRepository {
  final RequestClient _api;

  const new(this._api);

  Future<PaginatedData<Restaurant>> searchRestaurants(
    String keyword, {
    double? gcjLng,
    double? gcjLat,
    double? radius,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _api.get<PaginatedData<Restaurant>>(
      Urls.restaurantSearch,
      queryParameters: {
        'keyword': keyword,
        'gcjLng': gcjLng,
        'gcjLat': gcjLat,
        'radius': radius,
        'page': page,
        'pageSize': pageSize,
      }..removeWhere((key, value) => value == null),
      parser: (data) =>
          ApiParser.parsePage(data, fromJson: Restaurant.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '餐厅搜索结果为空');
    }

    return result;
  }

  Future<void> addRestaurant(RestaurantDTO dto) async {
    await _api.postVoid(Urls.restaurantAdd, data: dto.toJson());
  }

  Future<Restaurant> getRestaurantDetail(int id) async {
    final result = await _api.get<Restaurant>(
      '${Urls.restaurantDetail}/$id',
      parser: (data) => ApiParser.parseObject(data, Restaurant.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '餐厅详情为空');
    }

    return result;
  }

  Future<Restaurant?> resolveCreatedRestaurant(RestaurantDTO dto) async {
    final result = await searchRestaurants(
      dto.name,
      gcjLng: dto.gcjLng,
      gcjLat: dto.gcjLat,
      page: 1,
      pageSize: 20,
    );

    for (final restaurant in result.items) {
      final sameName = restaurant.name == dto.name;
      final sameAddress = restaurant.address == dto.address;
      final sameCity = restaurant.cityId == dto.cityId;
      final samePoi = restaurant.poi == dto.poi;
      if (sameName && sameAddress && (samePoi || sameCity)) {
        return restaurant;
      }
    }

    return null;
  }
}
