import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_restaurant_state.freezed.dart';

@freezed
abstract class AddRestaurantState with _$AddRestaurantState {
  const factory AddRestaurantState({
    @Default(false) bool isSubmitting,
  }) = _AddRestaurantState;
}
