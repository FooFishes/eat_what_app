import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/features/profile/providers.dart';
import 'package:eat_what_app/features/profile/presentation/view_models/profile_overview_state.dart';
import 'package:eat_what_app/features/restaurant/providers.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/shared/food/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_overview_view_model.g.dart';

@Riverpod(keepAlive: true)
class ProfileOverviewViewModel extends _$ProfileOverviewViewModel {
  @override
  ProfileOverviewState build() {
    Future.microtask(_loadOverview);
    return const ProfileOverviewState();
  }

  Future<void> _loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userInfo = await ref.read(userRepositoryProvider).getUserInfo();
      final stats = await ref
          .read(userRepositoryProvider)
          .getUserProfileStats(userInfo.id);
      state = state.copyWith(
        isLoading: false,
        userInfo: userInfo,
        stats: stats,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> reload() => _loadOverview();

  Future<PaginatedData<FoodVO>> loadMyFoods(int page, int pageSize) {
    return ref
        .read(foodRepositoryProvider)
        .getMyFoods(page: page, pageSize: pageSize);
  }

  Future<PaginatedData<FoodVO>> loadMyFavorites(int page, int pageSize) {
    return ref
        .read(foodRepositoryProvider)
        .getMyFavorites(page: page, pageSize: pageSize);
  }

  Future<Map<int, String>> resolveRestaurantNames(List<int> ids) async {
    final entries = await Future.wait(
      ids.map((id) async {
        try {
          final restaurant = await ref
              .read(restaurantRepositoryProvider)
              .getRestaurantDetail(id);
          return MapEntry<int, String>(id, restaurant.name);
        } catch (_) {
          return MapEntry<int, String>(id, '餐厅 #$id');
        }
      }),
    );
    return Map<int, String>.fromEntries(entries);
  }
}
