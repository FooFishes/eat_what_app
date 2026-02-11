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
    return await SecureStorageUtil.get(_tokenKey);
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
        state = AsyncValue.error(error, StackTrace.current);
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
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.logout();

    result.when(
      success: (_) async {
        await SecureStorageUtil.delete(_tokenKey);
        state = const AsyncValue.data(null);
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }
}
