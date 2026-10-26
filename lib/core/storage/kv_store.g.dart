// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kv_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用里唯一的 [KvStore]，测试里换成内存实现。

@ProviderFor(kvStore)
final kvStoreProvider = KvStoreProvider._();

/// 应用里唯一的 [KvStore]，测试里换成内存实现。

final class KvStoreProvider
    extends $FunctionalProvider<KvStore, KvStore, KvStore>
    with $Provider<KvStore> {
  /// 应用里唯一的 [KvStore]，测试里换成内存实现。
  KvStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kvStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kvStoreHash();

  @$internal
  @override
  $ProviderElement<KvStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KvStore create(Ref ref) {
    return kvStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KvStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KvStore>(value),
    );
  }
}

String _$kvStoreHash() => r'c5b1503d9885709dafb5c7f91ecd1078e54b2428';
