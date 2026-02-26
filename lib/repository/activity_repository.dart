import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/model/activity/create_activity_food_dto.dart';

import '../core/constant/urls.dart';

class ActivityRepository {
  final RequestClient _api;
  ActivityRepository(this._api);

  Future<Result<void>> createActivityFood(CreateActivityFoodDto dto) {
    return _api.post<void>(Urls.activityFoods, data: dto.toJson());
  }
}