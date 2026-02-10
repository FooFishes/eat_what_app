import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../util/secure_storage_util.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  static const String _tokenKey = 'token';

  @override
  Future<String?> build() async {
    final token = await SecureStorageUtil.get(_tokenKey);
    return token;
  }

  Future<String?> getToken() async {
    final currentState = state;
    if (currentState is AsyncData<String?>) {
      return currentState.value;
    }
    return await SecureStorageUtil.get(_tokenKey);
  }

  Future<void> login(String token) async {
    await SecureStorageUtil.save(_tokenKey, token);
    state = AsyncValue.data(token);
  }

  Future<void> logout() async {
    await SecureStorageUtil.delete(_tokenKey);
    state = AsyncValue.data(null);
  }
}
