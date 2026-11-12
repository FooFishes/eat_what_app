// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recommendApi)
final recommendApiProvider = RecommendApiProvider._();

final class RecommendApiProvider
    extends $FunctionalProvider<RecommendApi, RecommendApi, RecommendApi>
    with $Provider<RecommendApi> {
  RecommendApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendApiHash();

  @$internal
  @override
  $ProviderElement<RecommendApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecommendApi create(Ref ref) {
    return recommendApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendApi>(value),
    );
  }
}

String _$recommendApiHash() => r'06c23812665c4aa4150391f8b62875cb5643c166';
