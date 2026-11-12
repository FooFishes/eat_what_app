// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recommendRepository)
final recommendRepositoryProvider = RecommendRepositoryProvider._();

final class RecommendRepositoryProvider
    extends
        $FunctionalProvider<
          RecommendRepository,
          RecommendRepository,
          RecommendRepository
        >
    with $Provider<RecommendRepository> {
  RecommendRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecommendRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecommendRepository create(Ref ref) {
    return recommendRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendRepository>(value),
    );
  }
}

String _$recommendRepositoryHash() =>
    r'226f930b88ee22a9361477c046ac11183119f9a6';
