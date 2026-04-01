import 'package:eat_what_app/features/upload/presentation/view_models/add_food_state.dart';
import 'package:eat_what_app/features/upload/providers.dart';
import 'package:eat_what_app/shared/food/data/models/create_food_dto.dart';
import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/shared/food/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_food_view_model.g.dart';

@Riverpod(keepAlive: true)
class AddFoodViewModel extends _$AddFoodViewModel {
  @override
  AddFoodState build() {
    Future.microtask(_loadTags);
    return const AddFoodState();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await ref.read(foodRepositoryProvider).getSystemTags();
      state = state.copyWith(isLoadingTags: false, systemTags: tags);
    } catch (_) {
      state = state.copyWith(isLoadingTags: false);
    }
  }

  /// Returns the created [FoodVO] or null if the food was created but tags
  /// failed. Throws on hard failure — callers should handle errors.
  Future<FoodVO?> createFood({
    required int restaurantId,
    required String name,
    required String? description,
    required double? price,
    required String? category,
    required List<XFile> images,
    required Set<int> selectedSystemTagIds,
    required List<String> customTags,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final pictureUrl = await ref
          .read(imageUploadRepositoryProvider)
          .uploadImages(images: images);

      final dto = CreateFoodDTO(
        restaurantId: restaurantId,
        name: name,
        description: description,
        price: price,
        category: category,
        pictureUrl: pictureUrl,
      );

      final foodRepository = ref.read(foodRepositoryProvider);
      await foodRepository.uploadFood(dto);

      final createdFood = await foodRepository.resolveCreatedFood(
        restaurantId: restaurantId,
        name: name,
        pictureUrl: pictureUrl,
      );

      if (createdFood != null) {
        if (selectedSystemTagIds.isNotEmpty) {
          await foodRepository.addSystemTags(
            createdFood.id,
            selectedSystemTagIds.toList(),
          );
        }
        if (customTags.isNotEmpty) {
          await foodRepository.addCustomTags(createdFood.id, customTags);
        }
      }

      return createdFood;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
