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

/// 业务接口客户端实例. Web 端不能自定义 `User-Agent`, 由浏览器自动填充.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// 业务接口客户端实例. Web 端不能自定义 `User-Agent`, 由浏览器自动填充.

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// 业务接口客户端实例. Web 端不能自定义 `User-Agent`, 由浏览器自动填充.
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

String _$apiClientHash() => r'efbea5884227d8b6930caf572759150dd68319ef';
