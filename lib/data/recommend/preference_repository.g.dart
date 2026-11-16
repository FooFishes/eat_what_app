// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preferenceRepository)
final preferenceRepositoryProvider = PreferenceRepositoryProvider._();

final class PreferenceRepositoryProvider
    extends
        $FunctionalProvider<
          PreferenceRepository,
          PreferenceRepository,
          PreferenceRepository
        >
    with $Provider<PreferenceRepository> {
  PreferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferenceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<PreferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreferenceRepository create(Ref ref) {
    return preferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreferenceRepository>(value),
    );
  }
}

String _$preferenceRepositoryHash() =>
    r'bb1fd36c3d3e3372db35cddae109248cbe8a5ae3';
