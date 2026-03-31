import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/features/restaurant/data/repositories/restaurant_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
RestaurantRepository restaurantRepository(Ref ref) {
  return RestaurantRepository(ref.read(apiProvider));
}
