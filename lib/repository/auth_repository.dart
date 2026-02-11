import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';

import '../core/constant/urls.dart';

class AuthRepository {
  final RequestClient _api;
  AuthRepository(this._api);

  Future<Result<void>> checkUsername(String username) async {
    final body = {'username': username};
    return _api.post<void>(Urls.checkUsername, data: body);
  }

  Future<Result<String>> register(String username, String password) async {
    final body = {'username': username, 'password': password, 'device': 'APP'};
    return _api.post<String>(
      Urls.register,
      data: body,
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        return map['tokenValue'] as String;
      },
    );
  }

  Future<Result<String>> login(String account, String password) async {
    final body = {'username': account, 'password': password, 'device': 'APP'};
    return _api.post<String>(
      Urls.login,
      data: body,
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        return map['tokenValue'] as String;
      },
    );
  }

  Future<Result<void>> logout() async {
    return _api.post<void>(Urls.logout);
  }

  Future<Result<void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final body = {'oldPassword': oldPassword, 'newPassword': newPassword};
    return _api.post<void>(Urls.changePassword, data: body);
  }

  Future<Result<bool>> verify() async {
    return _api.post<bool>(Urls.verify, fromJson: (json) => json != null);
  }

  Future<Result<void>> sendEmail(String email) async {
    final body = {'email': email};
    return _api.post<void>(Urls.sendEmail, data: body);
  }
}
