// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(api)
final apiProvider = ApiProvider._();

final class ApiProvider
    extends $FunctionalProvider<RequestClient, RequestClient, RequestClient>
    with $Provider<RequestClient> {
  ApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiHash();

  @$internal
  @override
  $ProviderElement<RequestClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RequestClient create(Ref ref) {
    return api(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestClient>(value),
    );
  }
}

String _$apiHash() => r'e1638fbf2c396b4ed5f9b9716d687796aa2b00e0';
