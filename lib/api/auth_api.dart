import 'package:eat_what_app/api/request/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/api/exception/business_exception.dart';
import 'package:eat_what_app/core/constant/biz_code.dart';
import 'package:eat_what_app/model/result.dart';
import 'package:eat_what_app/util/token_util.dart';
import 'package:dio/dio.dart';

class AuthApi {
  static final RequestClient client = RequestClient.instance;

  static Future<Result<bool>> checkUsername(String username) async {
    try {
      final params = {'username': username};
      await client.post(Urls.checkUsername, queryParameters: params);
      return Result.success(true);
    } on BusinessException catch (e) {
      if (e.code == BizCode.usernameExists.code) {
        return Result.success(false);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<void>> register(String account, String password) async {
    try {
      final body = {'username': account, 'password': password, 'device': 'APP'};
      final response = await client.post(Urls.register, data: body);
      final data = response as Map<String, dynamic>;
      final token = data['tokenValue'] as String;
      TokenUtil.saveToken(token);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.usernameExists.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
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
      if (e.code == BizCode.userNotFound.code ||
          e.code == BizCode.userDisabled.code ||
          e.code == BizCode.wrongPassword.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<void>> logout() async {
    try {
      await client.post(Urls.logout);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.userNotFound.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<void>> sendEmail(String email) async {
    try {
      final params = {'email': email};
      await client.get(Urls.sendEmail, queryParameters: params);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.userNotFound.code ||
          e.code == BizCode.userDisabled.code ||
          e.code == BizCode.emailAlreadyVerified.code ||
          e.code == BizCode.invalidEmailFormat.code ||
          e.code == BizCode.onlySduEmailAllowed.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<void>> verifyEmail() async {
    try {
      final token = await TokenUtil.getToken();
      final params = {'token': token};
      await client.get(Urls.verifyEmail, queryParameters: params);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.userNotFound.code ||
          e.code == BizCode.userDisabled.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<void>> authGetCode(String mobile) async {
    try {
      final params = {'mobile': mobile};
      await client.post(Urls.authGetCode, queryParameters: params);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.userNotFound.code ||
          e.code == BizCode.userDisabled.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final body = {'oldPassword': oldPassword, 'newPassword': newPassword};
      await client.post(Urls.changePassword, data: body);
      return Result.success(null);
    } on BusinessException catch (e) {
      if (e.code == BizCode.userNotFound.code ||
          e.code == BizCode.userDisabled.code ||
          e.code == BizCode.wrongPassword.code ||
          e.code == BizCode.wrongVerificationCode.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }

  static Future<Result<bool>> verify() async {
    try {
      final response = await client.get(Urls.verify);
      final data = response as List<String>;
      if (data.isEmpty) {
        return Result.success(false);
      } else {
        return Result.success(true);
      }
    } on BusinessException catch (e) {
      if (e.code == BizCode.userNotFound.code ||
          e.code == BizCode.userDisabled.code) {
        return Result.error(ErrorSource.client, e.message);
      }
      rethrow;
    } on DioException catch (_) {
      return Result.network();
    }
  }
}
