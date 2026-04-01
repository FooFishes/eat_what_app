import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/shared/location/data/data_sources/device_location_data_source.dart';
import 'package:eat_what_app/shared/location/data/repositories/location_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
DeviceLocationDataSource deviceLocationDataSource(Ref ref) {
  return const DeviceLocationDataSource();
}

@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  return LocationRepository(ref.read(apiProvider));
}
