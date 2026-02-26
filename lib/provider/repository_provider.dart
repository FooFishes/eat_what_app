import 'package:eat_what_app/repository/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/user_repository.dart';
import '../repository/location_repository.dart';
import 'api_provider.dart';

part 'repository_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.read(apiProvider));
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.read(apiProvider));
}

@riverpod
LocationRepository locationRepository(Ref ref) {
  return LocationRepository(ref.read(apiProvider));
}
