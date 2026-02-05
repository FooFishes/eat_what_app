import 'package:eat_what_app/api/request/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/api/exception/business_exception.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/model/result.dart';
import 'package:eat_what_app/util/token_util.dart';
import 'package:dio/dio.dart';

class AuthApi {
  static final RequestClient client = RequestClient.instance;

  static Future<bool> checkUsername(String username) async {
    try {
      final params = {'username': username};
      await client.get(Urls.checkUsername, queryParameters: params);
      return true;
    } on BusinessException catch (e) {
      if (e.code == BizCode.usernameExists.code) {
        return false;
      }
      rethrow;
    }
  }

  static Future<Result<void>> login(String account, String password) async {
    try {
      final body = {'username': account, 'password': password, 'device': 'APP'};
      final response = await client.post(Urls.login, data: body);
      final data = response as Map<String, dynamic>;
      final token = data['tokenValue'] as String;
      TokenUtil.saveToken(token);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.wrongPassword.code ||
          e.code == BizCode.userDisabled.code ||
          e.code == BizCode.userNotFound.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }
}
