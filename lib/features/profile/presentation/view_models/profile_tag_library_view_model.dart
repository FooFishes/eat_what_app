import 'package:eat_what_app/core/network/models/api_response.dart';
import 'package:eat_what_app/features/profile/presentation/view_models/profile_tag_library_state.dart';
import 'package:eat_what_app/features/profile/providers.dart';
import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/shared/food/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_tag_library_view_model.g.dart';

@Riverpod(keepAlive: true)
class ProfileTagLibraryViewModel extends _$ProfileTagLibraryViewModel {
  @override
  ProfileTagLibraryState build() {
    Future.microtask(loadTags);
    return const ProfileTagLibraryState();
  }

  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait<List<FoodTagSummaryVO>>([
        ref.read(foodRepositoryProvider).getSystemTags(),
        _loadCustomTags(),
      ]);
      state = state.copyWith(
        isLoading: false,
        systemTags: results[0],
        customTags: results[1],
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<List<FoodTagSummaryVO>> _loadCustomTags() async {
    final mergedTags = <String, FoodTagSummaryVO>{};

    await _collectFoodTags(
      loader: ({required int page, required int pageSize}) =>
          ref.read(foodRepositoryProvider).getMyFoods(page: page, pageSize: pageSize),
      sink: mergedTags,
    );
    await _collectFoodTags(
      loader: ({required int page, required int pageSize}) =>
          ref.read(foodRepositoryProvider).getMyFavorites(page: page, pageSize: pageSize),
      sink: mergedTags,
    );
    await _collectHistoryTags(sink: mergedTags);

    final tags = mergedTags.values.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    return tags;
  }

  Future<void> _collectFoodTags({
    required Future<PaginatedData<FoodVO>> Function({
      required int page,
      required int pageSize,
    }) loader,
    required Map<String, FoodTagSummaryVO> sink,
  }) async {
    const pageSize = 100;
    var page = 1;
    var hasNext = true;
    while (hasNext) {
      final result = await loader(page: page, pageSize: pageSize);
      for (final food in result.items) {
        _mergeTags(food.myCustomTags, sink);
      }
      hasNext = result.hasNext;
      page++;
    }
  }

  Future<void> _collectHistoryTags({
    required Map<String, FoodTagSummaryVO> sink,
  }) async {
    const pageSize = 100;
    var page = 1;
    var hasNext = true;
    while (hasNext) {
      final result = await ref
          .read(userRepositoryProvider)
          .getBrowseHistory(targetType: 'food', page: page, pageSize: pageSize);
      for (final item in result.items) {
        final food = item.food;
        if (food != null) _mergeTags(food.myCustomTags, sink);
      }
      hasNext = result.hasNext;
      page++;
    }
  }

  void _mergeTags(List<FoodTagSummaryVO> tags, Map<String, FoodTagSummaryVO> sink) {
    for (final tag in tags) {
      final name = tag.name.trim();
      if (name.isEmpty) continue;
      sink.putIfAbsent(name, () => FoodTagSummaryVO(id: tag.id, name: name));
    }
  }
}
