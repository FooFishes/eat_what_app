// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preferenceApi)
final preferenceApiProvider = PreferenceApiProvider._();

final class PreferenceApiProvider
    extends $FunctionalProvider<PreferenceApi, PreferenceApi, PreferenceApi>
    with $Provider<PreferenceApi> {
  PreferenceApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferenceApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferenceApiHash();

  @$internal
  @override
  $ProviderElement<PreferenceApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PreferenceApi create(Ref ref) {
    return preferenceApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreferenceApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreferenceApi>(value),
    );
  }
}

String _$preferenceApiHash() => r'708b75b0d1275a6772e6e8fbe74578bf2e70add9';
