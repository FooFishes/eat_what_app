// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceApi)
final deviceApiProvider = DeviceApiProvider._();

final class DeviceApiProvider
    extends $FunctionalProvider<DeviceApi, DeviceApi, DeviceApi>
    with $Provider<DeviceApi> {
  DeviceApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceApiHash();

  @$internal
  @override
  $ProviderElement<DeviceApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceApi create(Ref ref) {
    return deviceApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceApi>(value),
    );
  }
}

String _$deviceApiHash() => r'917372d7ace114a5347b3717b1b5ee62ec9ea768';
