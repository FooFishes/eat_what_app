import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';

class ActivityRepository {
  final RequestClient _api;
  ActivityRepository(this._api);

  Future<Result<void>> createActivityFood({
    required String foodName,
    String? description,
    required int provinceId,
    required int cityId,
    required List<String> pictureUrl,
  }) {
    final body = {
      'foodName': foodName,
      'description': description,
      'provinceId': provinceId,
      'cityId': cityId,
      'pictureUrl': pictureUrl,
    };
    return _api.post<void>(Urls.activityFoods, data: body);
  }
}
