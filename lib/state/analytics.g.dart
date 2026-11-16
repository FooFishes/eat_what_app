// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analytics)
final analyticsProvider = AnalyticsProvider._();

final class AnalyticsProvider
    extends $FunctionalProvider<Analytics, Analytics, Analytics>
    with $Provider<Analytics> {
  AnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsHash();

  @$internal
  @override
  $ProviderElement<Analytics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Analytics create(Ref ref) {
    return analytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Analytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Analytics>(value),
    );
  }
}

String _$analyticsHash() => r'dcd270a6432b54ce2648461755c9ceddd148802a';
