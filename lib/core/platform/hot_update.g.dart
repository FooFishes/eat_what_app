// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_update.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(hotUpdate)
final hotUpdateProvider = HotUpdateProvider._();

final class HotUpdateProvider
    extends $FunctionalProvider<HotUpdate, HotUpdate, HotUpdate>
    with $Provider<HotUpdate> {
  HotUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotUpdateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotUpdateHash();

  @$internal
  @override
  $ProviderElement<HotUpdate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HotUpdate create(Ref ref) {
    return hotUpdate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HotUpdate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HotUpdate>(value),
    );
  }
}

String _$hotUpdateHash() => r'2fae77ec1616098db2fa7e5dbe29deb5cbaceb67';

/// 当前运行的补丁号. 显示在关于页, 并随崩溃上报.

@ProviderFor(currentPatch)
final currentPatchProvider = CurrentPatchProvider._();

/// 当前运行的补丁号. 显示在关于页, 并随崩溃上报.

final class CurrentPatchProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// 当前运行的补丁号. 显示在关于页, 并随崩溃上报.
  CurrentPatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPatchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPatchHash();

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    return currentPatch(ref);
  }
}

String _$currentPatchHash() => r'b94c04c18c95fe617969d6d0edebe21f4f1e9777';
