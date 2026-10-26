// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(browser)
final browserProvider = BrowserProvider._();

final class BrowserProvider
    extends $FunctionalProvider<Browser, Browser, Browser>
    with $Provider<Browser> {
  BrowserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserHash();

  @$internal
  @override
  $ProviderElement<Browser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Browser create(Ref ref) {
    return browser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Browser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Browser>(value),
    );
  }
}

String _$browserHash() => r'e75f6cf8f4e6a9e9fc289c8fe8b6d782e93072fc';
