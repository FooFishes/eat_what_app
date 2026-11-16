// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceRegistration)
final deviceRegistrationProvider = DeviceRegistrationProvider._();

final class DeviceRegistrationProvider
    extends
        $FunctionalProvider<
          DeviceRegistration,
          DeviceRegistration,
          DeviceRegistration
        >
    with $Provider<DeviceRegistration> {
  DeviceRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRegistrationHash();

  @$internal
  @override
  $ProviderElement<DeviceRegistration> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceRegistration create(Ref ref) {
    return deviceRegistration(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceRegistration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceRegistration>(value),
    );
  }
}

String _$deviceRegistrationHash() =>
    r'b17ef496cf4c14655415f1ecad85fde9022143ee';
