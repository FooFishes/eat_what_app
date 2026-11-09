// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eat_map.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前平台的地图实现. 测试中用 `overrideWithValue` 替换.

@ProviderFor(mapEngine)
final mapEngineProvider = MapEngineProvider._();

/// 当前平台的地图实现. 测试中用 `overrideWithValue` 替换.

final class MapEngineProvider
    extends $FunctionalProvider<MapEngine, MapEngine, MapEngine>
    with $Provider<MapEngine> {
  /// 当前平台的地图实现. 测试中用 `overrideWithValue` 替换.
  MapEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapEngineHash();

  @$internal
  @override
  $ProviderElement<MapEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapEngine create(Ref ref) {
    return mapEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapEngine>(value),
    );
  }
}

String _$mapEngineHash() => r'241f57b4923bf56224da75d473aa6600a97f0f57';
