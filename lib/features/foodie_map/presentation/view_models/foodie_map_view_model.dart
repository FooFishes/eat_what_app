import 'dart:async';

import 'package:eat_what_app/core/error/api_exception_ext.dart';
import 'package:eat_what_app/core/error/platform_exception.dart';
import 'package:eat_what_app/features/foodie_map/data/models/regional_food.dart';
import 'package:eat_what_app/features/foodie_map/presentation/view_models/foodie_map_state.dart';
import 'package:eat_what_app/features/foodie_map/providers.dart';
import 'package:eat_what_app/shared/location/data/models/province.dart';
import 'package:eat_what_app/shared/location/data/models/province_response.dart';
import 'package:eat_what_app/shared/location/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'foodie_map_view_model.g.dart';

@Riverpod(keepAlive: true)
class FoodieMapViewModel extends _$FoodieMapViewModel {
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  bool _didInitialize = false;
  bool _isDisposed = false;
  int _feedbackSeed = 0;
  Timer? _provinceDebounceTimer;

  @override
  FoodieMapPageState build() {
    _didInitialize = false;
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _provinceDebounceTimer?.cancel();
    });
    Future.microtask(_initialize);
    return const FoodieMapPageState();
  }

  Future<void> retryLoadProvinces() async {
    await _loadProvinces(force: true, keepInitialLoading: false);
  }

  void selectProvince(int provinceId) {
    if (state.selectedProvinceId == provinceId) {
      return;
    }

    _provinceDebounceTimer?.cancel();
    state = state.copyWith(
      selectedProvinceId: provinceId,
      committedProvinceId: null,
    );

    _provinceDebounceTimer = Timer(_debounceDuration, () {
      if (_isDisposed) {
        return;
      }
      state = state.copyWith(committedProvinceId: provinceId);
    });
  }

  void clearFeedback() {
    if (state.feedback == null) {
      return;
    }
    state = state.copyWith(feedback: null);
  }

  Future<void> _initialize() async {
    if (_didInitialize) {
      return;
    }
    _didInitialize = true;

    final localProvinceId = await _resolveLocalProvinceId();
    if (_isDisposed) {
      return;
    }

    state = state.copyWith(localProvinceId: localProvinceId);
    await _loadProvinces(force: true, keepInitialLoading: true);
  }

  Future<void> _loadProvinces({
    required bool force,
    required bool keepInitialLoading,
  }) async {
    if (state.isLoadingProvinces) {
      return;
    }
    if (!force && state.provinces.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isInitialLoading: keepInitialLoading ? true : state.isInitialLoading,
      isLoadingProvinces: true,
      hasProvincesError: false,
    );

    try {
      final provinces = await ref
          .read(foodieMapRepositoryProvider)
          .getProvinces();
      if (_isDisposed) {
        return;
      }

      final displayProvinces = _buildDisplayProvinces(
        provinces,
        state.localProvinceId,
      );
      final selectedProvinceId = _resolveSelectedProvinceId(displayProvinces);

      state = state.copyWith(
        isInitialLoading: false,
        isLoadingProvinces: false,
        hasProvincesError: false,
        provinces: displayProvinces,
        selectedProvinceId: selectedProvinceId,
        committedProvinceId: selectedProvinceId,
      );
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      state = state.copyWith(
        isInitialLoading: false,
        isLoadingProvinces: false,
        hasProvincesError: true,
        provinces: const [],
        selectedProvinceId: null,
        committedProvinceId: null,
        feedback: _createErrorFeedback(error),
      );
    }
  }

  int? _resolveSelectedProvinceId(List<ProvinceResponse> provinces) {
    final currentSelectedId = state.selectedProvinceId;
    if (currentSelectedId != null &&
        provinces.any((province) => province.id == currentSelectedId)) {
      return currentSelectedId;
    }
    if (provinces.isEmpty) {
      return null;
    }
    return provinces.first.id;
  }

  List<ProvinceResponse> _buildDisplayProvinces(
    List<ProvinceResponse> provinces,
    int? localProvinceId,
  ) {
    final displayProvinces = provinces
        .map(
          (province) => ProvinceResponse(
            id: province.id,
            name: Province.fromId(province.id)?.shortName ?? province.name,
          ),
        )
        .toList();

    if (localProvinceId == null) {
      return displayProvinces;
    }

    final localProvince = Province.fromId(localProvinceId);
    if (localProvince == null || localProvince.isNotMainland) {
      return displayProvinces;
    }

    displayProvinces.removeWhere((province) => province.id == localProvinceId);
    displayProvinces.insert(
      0,
      ProvinceResponse(id: localProvinceId, name: localProvince.shortName),
    );
    return displayProvinces;
  }

  Future<int?> _resolveLocalProvinceId() async {
    try {
      final province = await ref
          .read(deviceLocationDataSourceProvider)
          .getLocalProvince();
      return province?.id;
    } on LocationException catch (error) {
      if (_isDisposed) {
        return null;
      }

      final kind = switch (error.type) {
        LocationExceptionType.permissionDenied => FoodieMapFeedbackKind.warning,
        _ => FoodieMapFeedbackKind.error,
      };
      state = state.copyWith(
        feedback: _createFeedback(kind, _resolveLocationMessage(error)),
      );
      return null;
    } catch (error) {
      if (_isDisposed) {
        return null;
      }

      state = state.copyWith(
        feedback: _createFeedback(
          FoodieMapFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
      return null;
    }
  }

  String _resolveLocationMessage(LocationException error) {
    return switch (error.type) {
      LocationExceptionType.permissionDenied => '获取您的位置需开启定位权限',
      LocationExceptionType.timeout => '定位超时',
      _ => error.message,
    };
  }

  FoodieMapFeedback _createErrorFeedback(Object error) {
    return _createFeedback(
      FoodieMapFeedbackKind.error,
      resolveUserMessage(error),
    );
  }

  FoodieMapFeedback _createFeedback(
    FoodieMapFeedbackKind kind,
    String content,
  ) {
    _feedbackSeed++;
    return FoodieMapFeedback(id: _feedbackSeed, kind: kind, content: content);
  }
}

@riverpod
class FoodieMapFoodListViewModel extends _$FoodieMapFoodListViewModel {
  static const int _pageSize = 10;

  bool _didInitialize = false;
  bool _isDisposed = false;
  int _feedbackSeed = 0;

  @override
  FoodieMapFoodListState build(int provinceId) {
    _didInitialize = false;
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });
    Future.microtask(_initialize);
    return const FoodieMapFoodListState();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasNext) {
      return;
    }

    state = state.copyWith(isLoading: true, hasError: false);
    await _loadPage(reset: false);
  }

  Future<void> refresh() async {
    if (state.isLoading) {
      return;
    }
    state = state.copyWith(
      foods: const [],
      isLoading: true,
      hasError: false,
      hasNext: true,
      currentPage: 0,
    );
    await _loadPage(reset: true);
  }

  Future<void> toggleLike(int foodId) async {
    if (state.pendingLikeIds.contains(foodId)) {
      return;
    }

    final currentIndex = state.foods.indexWhere((food) => food.id == foodId);
    if (currentIndex == -1) {
      return;
    }

    final currentFood = state.foods[currentIndex];
    final nextLiked = !currentFood.isLiked;

    state = state.copyWith(
      foods: _replaceFood(
        state.foods,
        currentIndex,
        currentFood.copyWith(isLiked: nextLiked),
      ),
      pendingLikeIds: {...state.pendingLikeIds, foodId},
    );

    try {
      final repository = ref.read(foodieMapRepositoryProvider);
      if (nextLiked) {
        await repository.like('food', foodId);
      } else {
        await repository.disLike('food', foodId);
      }
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      state = state.copyWith(
        foods: _replaceFood(state.foods, currentIndex, currentFood),
        feedback: _createFeedback(
          FoodieMapFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
    } finally {
      if (!_isDisposed) {
        final nextPendingLikeIds = <int>{...state.pendingLikeIds}
          ..remove(foodId);
        state = state.copyWith(pendingLikeIds: nextPendingLikeIds);
      }
    }
  }

  void clearFeedback() {
    if (state.feedback == null) {
      return;
    }
    state = state.copyWith(feedback: null);
  }

  Future<void> _initialize() async {
    if (_didInitialize) {
      return;
    }
    _didInitialize = true;
    await _loadPage(reset: true);
  }

  Future<void> _loadPage({required bool reset}) async {
    final nextPage = reset ? 1 : state.currentPage + 1;

    try {
      final response = await ref
          .read(foodieMapRepositoryProvider)
          .getActivityFoodsByProvinceId(provinceId, nextPage, _pageSize);
      if (_isDisposed) {
        return;
      }

      final foods = response.items
          .map((item) => RegionalFood.fromActivityFoodResponse(item))
          .toList();

      state = state.copyWith(
        foods: reset ? foods : [...state.foods, ...foods],
        isLoading: false,
        hasError: false,
        hasNext: response.hasNext,
        currentPage: nextPage,
      );
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        hasError: state.foods.isEmpty || reset,
        feedback: _createFeedback(
          FoodieMapFeedbackKind.error,
          resolveUserMessage(error),
        ),
      );
    }
  }

  List<RegionalFood> _replaceFood(
    List<RegionalFood> foods,
    int index,
    RegionalFood nextFood,
  ) {
    final nextFoods = List<RegionalFood>.from(foods);
    nextFoods[index] = nextFood;
    return nextFoods;
  }

  FoodieMapFeedback _createFeedback(
    FoodieMapFeedbackKind kind,
    String content,
  ) {
    _feedbackSeed++;
    return FoodieMapFeedback(id: _feedbackSeed, kind: kind, content: content);
  }
}
