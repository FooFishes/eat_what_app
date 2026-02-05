import 'secure_storage_util.dart';

class TokenUtil {
  static String? _token;
  static const String tokenKey = 'token';

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await SecureStorageUtil.get(tokenKey);
    return _token;
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    await SecureStorageUtil.save(tokenKey, token);
  }

  static Future<void> deleteToken() async {
    _token = null;
    await SecureStorageUtil.delete(tokenKey);
  }
}
