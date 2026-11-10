// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(growthRepository)
final growthRepositoryProvider = GrowthRepositoryProvider._();

final class GrowthRepositoryProvider
    extends
        $FunctionalProvider<
          GrowthRepository,
          GrowthRepository,
          GrowthRepository
        >
    with $Provider<GrowthRepository> {
  GrowthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'growthRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$growthRepositoryHash();

  @$internal
  @override
  $ProviderElement<GrowthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GrowthRepository create(Ref ref) {
    return growthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrowthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrowthRepository>(value),
    );
  }
}

String _$growthRepositoryHash() => r'c757225506428815b4ac51d7b51fc61a49e6791c';
