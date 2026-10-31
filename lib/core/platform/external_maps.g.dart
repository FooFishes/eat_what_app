// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_maps.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(externalMaps)
final externalMapsProvider = ExternalMapsProvider._();

final class ExternalMapsProvider
    extends $FunctionalProvider<ExternalMaps, ExternalMaps, ExternalMaps>
    with $Provider<ExternalMaps> {
  ExternalMapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalMapsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalMapsHash();

  @$internal
  @override
  $ProviderElement<ExternalMaps> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExternalMaps create(Ref ref) {
    return externalMaps(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalMaps value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExternalMaps>(value),
    );
  }
}

String _$externalMapsHash() => r'0e95cd3f6ab0a0f46951a1ffa81cda9f99aa6bea';
