// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceLocationDataSource)
final deviceLocationDataSourceProvider = DeviceLocationDataSourceProvider._();

final class DeviceLocationDataSourceProvider
    extends
        $FunctionalProvider<
          DeviceLocationDataSource,
          DeviceLocationDataSource,
          DeviceLocationDataSource
        >
    with $Provider<DeviceLocationDataSource> {
  DeviceLocationDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLocationDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLocationDataSourceHash();

  @$internal
  @override
  $ProviderElement<DeviceLocationDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceLocationDataSource create(Ref ref) {
    return deviceLocationDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceLocationDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceLocationDataSource>(value),
    );
  }
}

String _$deviceLocationDataSourceHash() =>
    r'f84774c8a2cd97199387b10ce0dffe8cab2d1c4b';

@ProviderFor(locationRepository)
final locationRepositoryProvider = LocationRepositoryProvider._();

final class LocationRepositoryProvider
    extends
        $FunctionalProvider<
          LocationRepository,
          LocationRepository,
          LocationRepository
        >
    with $Provider<LocationRepository> {
  LocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationRepository create(Ref ref) {
    return locationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationRepository>(value),
    );
  }
}

String _$locationRepositoryHash() =>
    r'7e3c8c0d1405c47206117e1f8b4423461fb3a22c';
