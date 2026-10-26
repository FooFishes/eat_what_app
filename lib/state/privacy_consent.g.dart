// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_consent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(privacyConsentStore)
final privacyConsentStoreProvider = PrivacyConsentStoreProvider._();

final class PrivacyConsentStoreProvider
    extends
        $FunctionalProvider<
          PrivacyConsentStore,
          PrivacyConsentStore,
          PrivacyConsentStore
        >
    with $Provider<PrivacyConsentStore> {
  PrivacyConsentStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyConsentStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyConsentStoreHash();

  @$internal
  @override
  $ProviderElement<PrivacyConsentStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PrivacyConsentStore create(Ref ref) {
    return privacyConsentStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrivacyConsentStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrivacyConsentStore>(value),
    );
  }
}

String _$privacyConsentStoreHash() =>
    r'e3fead13fbdb0904dd144b1b2a88981d598deade';
