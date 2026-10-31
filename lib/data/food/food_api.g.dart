// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foodApi)
final foodApiProvider = FoodApiProvider._();

final class FoodApiProvider
    extends $FunctionalProvider<FoodApi, FoodApi, FoodApi>
    with $Provider<FoodApi> {
  FoodApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodApiHash();

  @$internal
  @override
  $ProviderElement<FoodApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FoodApi create(Ref ref) {
    return foodApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodApi>(value),
    );
  }
}

String _$foodApiHash() => r'c3182ca200a1ededb650b69ec292231fc31f120f';
