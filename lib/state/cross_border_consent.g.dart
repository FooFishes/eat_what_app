// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_border_consent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(crossBorderConsent)
final crossBorderConsentProvider = CrossBorderConsentProvider._();

final class CrossBorderConsentProvider
    extends
        $FunctionalProvider<
          CrossBorderConsent,
          CrossBorderConsent,
          CrossBorderConsent
        >
    with $Provider<CrossBorderConsent> {
  CrossBorderConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossBorderConsentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossBorderConsentHash();

  @$internal
  @override
  $ProviderElement<CrossBorderConsent> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CrossBorderConsent create(Ref ref) {
    return crossBorderConsent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrossBorderConsent value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrossBorderConsent>(value),
    );
  }
}

String _$crossBorderConsentHash() =>
    r'9ecb6b661a88fcb805e6f57332b801d3e9879bfe';
