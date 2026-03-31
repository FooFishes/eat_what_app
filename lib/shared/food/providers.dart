import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/shared/food/data/repositories/food_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
FoodRepository foodRepository(Ref ref) {
  return FoodRepository(ref.read(apiProvider));
}
