import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/provider/repository_provider.dart';
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
    return SecureStorageUtil.get(_tokenKey);
  }

  Future<void> login(String account, String password) async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(account, password);

    result.when(
      success: (token) async {
        await SecureStorageUtil.save(_tokenKey, token);
        state = AsyncValue.data(token);
      },
      failure: (error) {
        state = AsyncValue.error(error, _resolveStackTrace(error));
      },
    );
  }

  Future<void> register(String account, String password) async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.register(account, password);

    result.when(
      success: (token) async {
        await SecureStorageUtil.save(_tokenKey, token);
        state = AsyncValue.data(token);
      },
      failure: (error) {
        state = AsyncValue.error(error, _resolveStackTrace(error));
      },
    );
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.logout();

    result.when(
      success: (_) async {
        await clearSession();
      },
      failure: (error) {
        state = AsyncValue.error(error, _resolveStackTrace(error));
      },
    );
  }

  Future<void> clearSession() async {
    await SecureStorageUtil.delete(_tokenKey);
    state = const AsyncValue.data(null);
  }

  StackTrace _resolveStackTrace(Object error) {
    if (error is ApiException && error.stackTrace != null) {
      return error.stackTrace!;
    }
    return StackTrace.current;
  }
}
