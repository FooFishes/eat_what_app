import 'package:eat_what_app/core/constant/restaurant_mock.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant_dto.dart';
import 'package:eat_what_app/features/restaurant/providers.dart';
import 'package:eat_what_app/features/upload/presentation/view_models/add_restaurant_state.dart';
import 'package:eat_what_app/features/upload/providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_restaurant_view_model.g.dart';

@Riverpod(keepAlive: true)
class AddRestaurantViewModel extends _$AddRestaurantViewModel {
  @override
  AddRestaurantState build() => const AddRestaurantState();

  /// Uploads images, creates the restaurant, then resolves and returns it.
  /// Returns null if the restaurant was created but could not be resolved yet.
  Future<Restaurant?> createRestaurant({
    required String name,
    required String address,
    required List<XFile> images,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final pictureUrl = await ref
          .read(imageUploadRepositoryProvider)
          .uploadImages(images: images);

      final dto = RestaurantDTO(
        name: name,
        address: address,
        cityId: null,
        gcjLng: RestaurantMock.gcjLng,
        gcjLat: RestaurantMock.gcjLat,
        hubId: RestaurantMock.hubId,
        poi: null,
        pictureUrl: pictureUrl,
      );

      await ref.read(restaurantRepositoryProvider).addRestaurant(dto);
      return await ref
          .read(restaurantRepositoryProvider)
          .resolveCreatedRestaurant(dto);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
