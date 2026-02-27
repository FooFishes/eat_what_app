import 'dart:async';

import 'package:eat_what_app/model/province/province.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationUtil {
  static Future<Province?> getLocalProvince() async {
    //获取权限
    bool hasPermisson = await getPermission();
    if (!hasPermisson) return null;

    Position position = await Geolocator.getCurrentPosition(
      timeLimit: Duration(seconds: 6),
    );
    List<Placemark> placemarks =
        await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          Duration(seconds: 3),
          onTimeout: () => throw TimeoutException("反向地理编码超时"),
        );
    if (placemarks.isEmpty) {
      return null;
    }
    Placemark place = placemarks.first;
    return _getProvinceFromPlacemark(place);
  }

  static Future<bool> getPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();

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

  static Province? _getProvinceFromPlacemark(Placemark place) {
    if (place.country == null) {
      return null;
    }

    if (place.country == "中国" || place.country == "China") {
      return place.administrativeArea == null
          ? null
          : Province.fromName(place.administrativeArea!);
    } else {
      return Province.foreign;
    }
  }
}
