import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/provider/api_provider.dart';
import 'package:eat_what_app/repository/auth_repository.dart';
import 'package:eat_what_app/repository/food_repository.dart';
import 'package:eat_what_app/repository/foodie_map_repository.dart';
import 'package:eat_what_app/repository/image_upload_repository.dart';
import 'package:eat_what_app/repository/location_repository.dart';
import 'package:eat_what_app/repository/restaurant_repository.dart';
import 'package:eat_what_app/repository/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.read(apiProvider));
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return UserRepository(
    api: ref.read(apiProvider),
    rawApi: RequestClient.raw(),
  );
}

@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  return LocationRepository(ref.read(apiProvider));
}

@Riverpod(keepAlive: true)
FoodieMapRepository foodieMapRepository(Ref ref) {
  return FoodieMapRepository(ref.read(apiProvider));
}

final Provider<RestaurantRepository> restaurantRepositoryProvider =
    Provider<RestaurantRepository>(
      (ref) => RestaurantRepository(ref.read(apiProvider)),
    );

final Provider<FoodRepository> foodRepositoryProvider =
    Provider<FoodRepository>((ref) => FoodRepository(ref.read(apiProvider)));

final Provider<ImageUploadRepository> imageUploadRepositoryProvider =
    Provider<ImageUploadRepository>(
      (ref) => ImageUploadRepository(
        api: ref.read(apiProvider),
        rawApi: RequestClient.raw(),
      ),
    );
