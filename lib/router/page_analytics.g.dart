// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pageAnalytics)
final pageAnalyticsProvider = PageAnalyticsProvider._();

final class PageAnalyticsProvider
    extends $FunctionalProvider<PageAnalytics, PageAnalytics, PageAnalytics>
    with $Provider<PageAnalytics> {
  PageAnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageAnalyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageAnalyticsHash();

  @$internal
  @override
  $ProviderElement<PageAnalytics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PageAnalytics create(Ref ref) {
    return pageAnalytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageAnalytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageAnalytics>(value),
    );
  }
}

String _$pageAnalyticsHash() => r'dd5c3896f3aea144ad6b7d8f9ade034c6c6e0da9';
