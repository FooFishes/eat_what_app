import 'package:eat_what_app/core/network/api_parser.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/shared/location/data/models/city_response.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';

class LocationRepository {
  final RequestClient _api;

  const new(this._api);

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

  Future<List<CityResponse>> getCities(int provinceId) async {
    final result = await _api.get<List<CityResponse>>(
      Urls.cities(provinceId),
      parser: (data) => ApiParser.parseList(data, CityResponse.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '城市列表为空');
    }

    return result;
  }
}
