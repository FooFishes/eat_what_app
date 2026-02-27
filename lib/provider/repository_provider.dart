import 'package:eat_what_app/repository/activity_repository.dart';
import 'package:eat_what_app/repository/auth_repository.dart';
import 'package:eat_what_app/repository/location_repository.dart';
import 'package:eat_what_app/repository/upload_repository.dart';
import 'package:eat_what_app/repository/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

@riverpod
UploadRepository uploadRepository(Ref ref) {
  return UploadRepository(ref.read(apiProvider));
}

@riverpod
ActivityRepository activityRepository(Ref ref) {
  return ActivityRepository(ref.read(apiProvider));
}
