// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_site_consent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(crossSiteConsent)
final crossSiteConsentProvider = CrossSiteConsentProvider._();

final class CrossSiteConsentProvider
    extends
        $FunctionalProvider<
          CrossSiteConsent,
          CrossSiteConsent,
          CrossSiteConsent
        >
    with $Provider<CrossSiteConsent> {
  CrossSiteConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossSiteConsentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossSiteConsentHash();

  @$internal
  @override
  $ProviderElement<CrossSiteConsent> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrossSiteConsent create(Ref ref) {
    return crossSiteConsent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrossSiteConsent value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrossSiteConsent>(value),
    );
  }
}

String _$crossSiteConsentHash() => r'4cb7d631aaabd36a6f61ce6d201b50df29a9fb7c';
