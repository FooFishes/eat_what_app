// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 网络层的会话回调. 默认为空, 由 `state/api_hooks.dart` 覆盖为实际处理.

@ProviderFor(apiHooks)
final apiHooksProvider = ApiHooksProvider._();

/// 网络层的会话回调. 默认为空, 由 `state/api_hooks.dart` 覆盖为实际处理.

final class ApiHooksProvider
    extends $FunctionalProvider<ApiHooks, ApiHooks, ApiHooks>
    with $Provider<ApiHooks> {
  /// 网络层的会话回调. 默认为空, 由 `state/api_hooks.dart` 覆盖为实际处理.
  ApiHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiHooksHash();

  @$internal
  @override
  $ProviderElement<ApiHooks> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiHooks create(Ref ref) {
    return apiHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiHooks value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiHooks>(value),
    );
  }
}

String _$apiHooksHash() => r'9356f30fd6d2f2140911e7ebeeb94100386e5fba';

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'e99b89f31cdd4bc8f8b8ce65d8815e2ed34f1237';
