import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/features/auth/data/data_sources/token_storage_data_source.dart';
import 'package:eat_what_app/features/auth/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
TokenStorageDataSource tokenStorageDataSource(Ref ref) {
  return const TokenStorageDataSource();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.read(apiProvider));
}
