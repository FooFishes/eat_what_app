import 'package:eat_what_app/core/network/api_parser.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/features/foodie_map/data/models/activity_food_page_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';

class FoodieMapRepository {
  final RequestClient _api;

  const FoodieMapRepository(this._api);

  Future<List<ProvinceResponse>> getProvinces() async {
    final result = await _api.get<List<ProvinceResponse>>(
      Urls.provinces,
      parser: (data) => ApiParser.parseList(data, ProvinceResponse.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '省份列表为空');
    }

    return result;
  }

  Future<ActivityFoodPageResponse> getActivityFoodsByProvinceId(
    int provinceId,
    int page,
    int pageSize,
  ) async {
    final path = Urls.provinceActivityFoods.replaceAll(
      '{provinceId}',
      provinceId.toString(),
    );
    final result = await _api.get<ActivityFoodPageResponse>(
      path,
      queryParameters: {'page': page, 'pageSize': pageSize},
      parser: (data) =>
          ApiParser.parseObject(data, ActivityFoodPageResponse.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '美食列表为空');
    }

    return result;
  }

  Future<void> like(String targetType, int activityId) async {
    await _api.postVoid(
      Urls.likes,
      data: {'targetType': targetType, 'activityId': activityId},
    );
  }

  Future<void> disLike(String targetType, int activityId) async {
    await _api.deleteVoid(
      Urls.likes,
      data: {'targetType': targetType, 'activityId': activityId},
    );
  }
}
