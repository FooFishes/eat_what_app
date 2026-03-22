import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/auth/auth_request.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../util/secure_storage_util.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
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
    return SecureStorageUtil.get(_tokenKey);
  }

  Future<void> login(String account, String password) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(authRepositoryProvider);
      final token = await repo.login(
        AuthRequest(account: account, password: password),
      );
      await SecureStorageUtil.save(_tokenKey, token);
      state = AsyncValue.data(token);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, _resolveStackTrace(error, stackTrace));
    }
  }

  Future<void> register(String account, String password) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(authRepositoryProvider);
      final token = await repo.register(
        AuthRequest(account: account, password: password),
      );
      await SecureStorageUtil.save(_tokenKey, token);
      state = AsyncValue.data(token);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, _resolveStackTrace(error, stackTrace));
    }
  }

  Future<void> logout() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, _resolveStackTrace(error, stackTrace));
    } finally {
      await clearSession();
    }
  }

  Future<bool> checkVerifyStatus() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      return await repo.verify();
    } catch (e) {
      return false;
    }
  }

  Future<void> sendVerifyEmail(String email) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.sendEmail(email);
  }

  Future<void> clearSession() async {
    await SecureStorageUtil.delete(_tokenKey);
    state = const AsyncValue.data(null);
  }

  StackTrace _resolveStackTrace(Object error, [StackTrace? fallback]) {
    if (error is ApiException && error.stackTrace != null) {
      return error.stackTrace!;
    }
    return fallback ?? StackTrace.current;
  }
}
