import 'package:eat_what_app/features/profile/presentation/view_models/profile_history_state.dart';
import 'package:eat_what_app/features/profile/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_history_view_model.g.dart';

/// [targetType] is 'restaurant' or 'food'.
@riverpod
class ProfileHistoryViewModel extends _$ProfileHistoryViewModel {
  static const int _pageSize = 20;

  @override
  ProfileHistoryState build(String targetType) {
    Future.microtask(() => loadMore(reset: true));
    return const ProfileHistoryState();
  }

  /// Loads the first page when [reset] is true, or the next page otherwise.
  Future<void> loadMore({bool reset = false}) async {
    if (reset) {
      if (state.isLoading) return;

      state = state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        error: null,
        items: const [],
        currentPage: 0,
        hasNext: false,
      );
    } else {
      if (state.isLoading || state.isLoadingMore || !state.hasNext) return;

      state = state.copyWith(isLoadingMore: true);
    }

    final nextPage = reset ? 1 : state.currentPage + 1;
    try {
      final page = await ref
          .read(userRepositoryProvider)
          .getBrowseHistory(
            targetType: targetType,
            page: nextPage,
            pageSize: _pageSize,
          );

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        items: reset ? page.items : [...state.items, ...page.items],
        hasNext: page.hasNext,
        currentPage: nextPage,
        totalItems: page.totalItems,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }
}
