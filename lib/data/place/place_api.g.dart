// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeApi)
final placeApiProvider = PlaceApiProvider._();

final class PlaceApiProvider
    extends $FunctionalProvider<PlaceApi, PlaceApi, PlaceApi>
    with $Provider<PlaceApi> {
  PlaceApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeApiHash();

  @$internal
  @override
  $ProviderElement<PlaceApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaceApi create(Ref ref) {
    return placeApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceApi>(value),
    );
  }
}

String _$placeApiHash() => r'6f69174815e761fe74b58a216113ef6404697fe5';
