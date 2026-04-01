import 'package:eat_what_app/features/profile/data/models/browse_history_item_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_history_state.freezed.dart';

@freezed
abstract class ProfileHistoryState with _$ProfileHistoryState {
  const factory ProfileHistoryState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default([]) List<BrowseHistoryItemResponse> items,
    @Default(false) bool hasNext,
    @Default(0) int currentPage,
    @Default(0) int totalItems,
    Object? error,
  }) = _ProfileHistoryState;
}
