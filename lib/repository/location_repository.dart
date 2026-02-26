import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/model/location/city_dto.dart';
import 'package:eat_what_app/model/location/province_dto.dart';

import '../core/constant/urls.dart';

class LocationRepository {
  final RequestClient _api;
  LocationRepository(this._api);

  Future<Result<List<ProvinceDto>>> getProvinces() {
    return _api.get<List<ProvinceDto>>(
      Urls.provinces,
      fromJson: (json) => (json as List)
          .map((item) => ProvinceDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Result<List<CityDto>>> getCities(int provinceId) {
    return _api.get<List<CityDto>>(
      '${Urls.cities}/$provinceId/cities',
      fromJson: (json) => (json as List)
          .map((item) => CityDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
