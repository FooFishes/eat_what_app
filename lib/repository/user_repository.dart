import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/model/user/user_info_dto.dart';

import '../core/api/request_client.dart';

class UserRepository {
  final RequestClient _api;
  UserRepository(this._api);

  Future<Result<UserInfoDto>> getUserInfo() async {
    return _api.get<UserInfoDto>(
      Urls.userInfo,
      fromJson: (json) => UserInfoDto.fromJson(json as Map<String, dynamic>),
    );
  }
}