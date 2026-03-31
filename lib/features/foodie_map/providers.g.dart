// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foodieMapRepository)
final foodieMapRepositoryProvider = FoodieMapRepositoryProvider._();

final class FoodieMapRepositoryProvider
    extends
        $FunctionalProvider<
          FoodieMapRepository,
          FoodieMapRepository,
          FoodieMapRepository
        >
    with $Provider<FoodieMapRepository> {
  FoodieMapRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodieMapRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodieMapRepositoryHash();

  @$internal
  @override
  $ProviderElement<FoodieMapRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FoodieMapRepository create(Ref ref) {
    return foodieMapRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodieMapRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodieMapRepository>(value),
    );
  }
}

String _$foodieMapRepositoryHash() =>
    r'219df267f71c6fc087a92f7d2b5235f9206e5d95';
