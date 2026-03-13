import 'package:eat_what_app/core/api/api_parser.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/auth/auth_respuest.dart';
import 'package:eat_what_app/model/auth/change_password_request.dart';
import 'package:eat_what_app/model/auth/token_response.dart';

class AuthRepository {
  final RequestClient _api;

  const AuthRepository(this._api);

  Future<void> checkUsername(String username) async {
    await _api.postVoid(Urls.checkUsername, data: {'username': username});
  }

  Future<String> register(AuthRespuest request) async {
    final response = await _api.post<TokenResponse>(
      Urls.register,
      data: request.toJson(),
      parser: (data) => ApiParser.parseObject(data, TokenResponse.fromJson),
    );

    final token = response?.tokenValue;
    if (token == null || token.isEmpty) {
      throw const ParseException(message: '注册响应缺少 token');
    }

    return token;
  }

  Future<String> login(AuthRespuest request) async {
    final response = await _api.post<TokenResponse>(
      Urls.login,
      data: request.toJson(),
      parser: (data) => ApiParser.parseObject(data, TokenResponse.fromJson),
    );

    final token = response?.tokenValue;
    if (token == null || token.isEmpty) {
      throw const ParseException(message: '登录响应缺少 token');
    }

    return token;
  }

  Future<void> logout() async {
    await _api.postVoid(Urls.logout);
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    await _api.postVoid(Urls.changePassword, data: request.toJson());
  }

  Future<bool> verify() async {
    final result = await _api.post<bool>(
      Urls.verify,
      parser: (data) => data != null,
    );
    return result ?? true;
  }

  Future<void> sendEmail(String email) async {
    await _api.postVoid(Urls.sendEmail, data: {'email': email});
  }
}
