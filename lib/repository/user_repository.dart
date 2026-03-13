import 'package:eat_what_app/core/api/api_parser.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/user/user_info_response.dart';

class UserRepository {
  final RequestClient _api;

  const UserRepository(this._api);

  Future<UserInfoResponse> getUserInfo() async {
    final result = await _api.get<UserInfoResponse>(
      Urls.userInfo,
      parser: (data) => ApiParser.parseObject(data, UserInfoResponse.fromJson),
    );

    if (result == null) {
      throw const ParseException(message: '用户信息为空');
    }

    return result;
  }
}
