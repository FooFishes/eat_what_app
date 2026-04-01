import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/features/auth/data/models/auth_request.dart';
import 'package:eat_what_app/features/auth/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_view_model.g.dart';

@Riverpod(keepAlive: true)
class AuthSessionViewModel extends _$AuthSessionViewModel {
  @override
  Future<String?> build() async {
    return ref.read(tokenStorageDataSourceProvider).readToken();
  }

  Future<String?> getToken() async {
    final currentState = state;
    if (currentState is AsyncData<String?>) {
      return currentState.value;
    }
    return ref.read(tokenStorageDataSourceProvider).readToken();
  }

  Future<void> login(String account, String password) async {
    state = const AsyncLoading();

    try {
      final token = await ref
          .read(authRepositoryProvider)
          .login(AuthRequest(account: account, password: password));
      await ref.read(tokenStorageDataSourceProvider).saveToken(token);
      state = AsyncValue.data(token);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, _resolveStackTrace(error, stackTrace));
    }
  }

  Future<void> register(String account, String password) async {
    state = const AsyncLoading();

    try {
      final token = await ref
          .read(authRepositoryProvider)
          .register(AuthRequest(account: account, password: password));
      await ref.read(tokenStorageDataSourceProvider).saveToken(token);
      state = AsyncValue.data(token);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, _resolveStackTrace(error, stackTrace));
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, _resolveStackTrace(error, stackTrace));
    } finally {
      await clearSession();
    }
  }

  Future<bool> checkVerifyStatus() async {
    try {
      return await ref.read(authRepositoryProvider).verify();
    } catch (_) {
      return false;
    }
  }

  Future<void> sendVerifyEmail(String email) {
    return ref.read(authRepositoryProvider).sendEmail(email);
  }

  Future<void> clearSession() async {
    await ref.read(tokenStorageDataSourceProvider).clearToken();
    state = const AsyncValue.data(null);
  }

  StackTrace _resolveStackTrace(Object error, [StackTrace? fallback]) {
    if (error is ApiException && error.stackTrace != null) {
      return error.stackTrace!;
    }
    return fallback ?? StackTrace.current;
  }
}
