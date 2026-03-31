import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/features/restaurant/providers.dart';
import 'package:eat_what_app/features/upload/providers.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/restaurant_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constant/restaurant_mock.dart';

part 'restaurant_search_view_model.g.dart';

@Riverpod(keepAlive: true)
class RestaurantSearchViewModel extends _$RestaurantSearchViewModel {
  int _resultsRequestSeed = 0;
  bool _hintDismissed = false;

  @override
  RestaurantSearchState build() {
    Future.microtask(_init);
    return const RestaurantSearchState();
  }

  Future<void> _init() async {
    // Load hint status and initial (empty-keyword) results concurrently.
    state = state.copyWith(isLoadingHint: true);
    final hintFuture = ref
        .read(restaurantSearchHintDataSourceProvider)
        .shouldShowIntroHint()
        .catchError((_) => false);
    final resultsFuture = _loadResults(
      keyword: '',
      hasSearched: false,
      rethrowOnError: false,
    );

    final hint = await hintFuture;
    state = state.copyWith(
      isLoadingHint: false,
      shouldShowIntroHint: _hintDismissed ? false : hint,
    );

    await resultsFuture;
  }

  Future<void> search(String keyword) async {
    final trimmed = keyword.trim();
    // Dismiss the intro hint on the first explicit search.
    if (state.shouldShowIntroHint && trimmed.isNotEmpty) {
      _dismissHint();
    }

    await _loadResults(
      keyword: trimmed,
      hasSearched: trimmed.isNotEmpty,
      rethrowOnError: true,
    );
  }

  Future<void> refresh() => search(state.keyword);

  void _dismissHint() {
    _hintDismissed = true;
    state = state.copyWith(shouldShowIntroHint: false);
    ref
        .read(restaurantSearchHintDataSourceProvider)
        .markIntroHintShown()
        .ignore();
  }

  Future<void> _loadResults({
    required String keyword,
    required bool hasSearched,
    required bool rethrowOnError,
  }) async {
    final requestId = ++_resultsRequestSeed;

    state = state.copyWith(
      isSearching: true,
      keyword: keyword,
      hasSearched: hasSearched,
    );

    try {
      final results = await _fetchRestaurants(keyword);
      if (requestId != _resultsRequestSeed) {
        return;
      }
      state = state.copyWith(isSearching: false, results: results);
    } catch (error) {
      if (requestId != _resultsRequestSeed) {
        return;
      }
      state = state.copyWith(isSearching: false);
      if (rethrowOnError) {
        rethrow;
      }
    }
  }

  Future<List<Restaurant>> _fetchRestaurants(String keyword) async {
    final response = await ref
        .read(restaurantRepositoryProvider)
        .searchRestaurants(
          keyword,
          gcjLat: RestaurantMock.gcjLat,
          gcjLng: RestaurantMock.gcjLng,
        );
    return response.items;
  }
}
