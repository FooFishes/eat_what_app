import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/model/activity/page_result_activity_food_dto.dart';
import 'package:eat_what_app/model/location/province_dto.dart';

class FoodieMapRepository {
  final RequestClient _api;
  FoodieMapRepository(this._api);

  Future<Result<List<ProvinceDto>>> getProvinces() {
    return _api.get<List<ProvinceDto>>(
      Urls.provinces,
      fromJson: (json) => (json as List)
          .map((item) => ProvinceDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Result<PageResultActivityFoodDto>> getActivityFoodsByProvinceId(
    int provinceId,
    int page,
    int pageSize,
  ) {
    String url = Urls.provinceActivityFoods.replaceAll(
      "{provinceId}",
      provinceId.toString(),
    );
    final queryParameters = {"page": page, "pageSize": pageSize};
    return _api.get<PageResultActivityFoodDto>(
      url,
      queryParameters: queryParameters,
      fromJson: (json) =>
          PageResultActivityFoodDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<void>> like(String targetType, int activityId) {
    final body = {"targetType": targetType, "activityId": activityId};
    return _api.post(Urls.likes, data: body);
  }

  Future<Result<void>> disLike(String targetType, int activityId) {
    final body = {"targetType": targetType, "activityId": activityId};
    return _api.delete(Urls.likes, data: body);
  }
}
