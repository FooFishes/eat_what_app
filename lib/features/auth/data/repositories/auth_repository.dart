import 'package:eat_what_app/core/network/api_parser.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/features/auth/data/models/auth_request.dart';
import 'package:eat_what_app/features/auth/data/models/change_password_request.dart';
import 'package:eat_what_app/features/auth/data/models/token_response.dart';

class AuthRepository {
  final RequestClient _api;

  const new(this._api);

  Future<void> checkUsername(String username) async {
    await _api.postVoid(
      Urls.checkUsername,
      queryParameters: {'username': username},
    );
  }

  Future<String> register(AuthRequest request) async {
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

  Future<String> login(AuthRequest request) async {
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
    final result = await _api.get<bool>(
      Urls.verify,
      parser: (data) {
        if (data is List) return data.isNotEmpty;
        return false;
      },
    );
    return result ?? false;
  }

  Future<void> sendEmail(String email) async {
    await _api.get(
      Urls.sendEmail,
      queryParameters: {'email': email},
      parser: (_) => null,
    );
  }
}
