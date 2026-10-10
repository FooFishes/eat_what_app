import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageDataSource {
  const new();

  static const String tokenKey = 'token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveToken(String value) {
    return _storage.write(key: tokenKey, value: value);
  }

  Future<String?> readToken() {
    return _storage.read(key: tokenKey);
  }

  Future<void> clearToken() {
    return _storage.delete(key: tokenKey);
  }
}
