import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/features/foodie_map/data/repositories/foodie_map_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
FoodieMapRepository foodieMapRepository(Ref ref) {
  return FoodieMapRepository(ref.read(apiProvider));
}
