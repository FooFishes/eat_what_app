import 'dart:async';

import 'package:eat_what_app/core/error/platform_exception.dart';
import 'package:eat_what_app/shared/location/data/models/province.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocationDataSource {
  const DeviceLocationDataSource();

  Future<Province?> getLocalProvince() async {
    final hasPermission = await _getPermission();
    if (!hasPermission) {
      throw const LocationException(
        message: '无定位权限',
        type: LocationExceptionType.permissionDenied,
      );
    }

    final position = await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 6),
      onTimeout: () => throw const LocationException(
        message: '获取定位超时',
        type: LocationExceptionType.timeout,
      ),
    );

    final placemarks =
        await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('反向地理编码超时'),
        );

    if (placemarks.isEmpty) {
      return null;
    }

    return _getProvinceFromPlacemark(placemarks.first);
  }

  Future<bool> _getPermission() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Province? _getProvinceFromPlacemark(Placemark place) {
    if (place.country == null) {
      return null;
    }

    if (place.country == '中国' || place.country == 'China') {
      return place.administrativeArea == null
          ? null
          : Province.fromName(place.administrativeArea!);
    }

    return Province.foreign;
  }
}
