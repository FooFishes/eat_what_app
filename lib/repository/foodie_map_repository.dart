import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/model/activity/page_result_activity_food_dto.dart';

enum LikeTargetType {
  food;

  String get value => name;
}

class FoodieMapRepository {
  final RequestClient _api;
  FoodieMapRepository(this._api);

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

  Future<Result<void>> like(LikeTargetType targetType, int activityId) {
    final body = {"targetType": targetType.value, "activityId": activityId};
    return _api.post(Urls.likes, data: body);
  }

  Future<Result<void>> disLike(LikeTargetType targetType, int activityId) {
    final body = {"targetType": targetType.value, "activityId": activityId};
    return _api.delete(Urls.likes, data: body);
  }
}
