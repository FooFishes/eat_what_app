import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location.g.dart';

/// 定位权限现在怎样。
enum LocationAccess {
  /// 还没问过系统。
  notAsked,
  granted,

  /// 拒绝了，还能再问。
  denied,

  /// 永久拒绝，或者系统定位服务关着：只能去系统设置里开。
  blocked,
}

/// 设备定位，包住 `geolocator`。只给 WGS-84 的经纬度，转 GCJ-02 由上层做（技术架构 14.1、14.2）。
///
/// 只在需要时定位一次，不持续监听、不后台定位，位置不落盘。
abstract interface class LocationService {
  Future<LocationAccess> access();

  /// 弹系统的权限框。已经永久拒绝时不弹，直接返回 [LocationAccess.blocked]。
  Future<LocationAccess> request();

  /// 当前位置的 WGS-84 经纬度；没有权限或定位失败时为 null。
  Future<({double lat, double lng})?> current();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationAccess> access() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.blocked;
      }
      return _map(await Geolocator.checkPermission());
    } on Object {
      return LocationAccess.blocked;
    }
  }

  @override
  Future<LocationAccess> request() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.blocked;
      }
      final current = await Geolocator.checkPermission();
      if (current == LocationPermission.deniedForever) {
        return LocationAccess.blocked;
      }
      return _map(await Geolocator.requestPermission(), asked: true);
    } on Object {
      return LocationAccess.blocked;
    }
  }

  @override
  Future<({double lat, double lng})?> current() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: position.latitude, lng: position.longitude);
    } on Object {
      final last = await Geolocator.getLastKnownPosition().catchError(
        (Object _) => null,
      );
      return last == null ? null : (lat: last.latitude, lng: last.longitude);
    }
  }

  static LocationAccess _map(
    LocationPermission permission, {
    bool asked = false,
  }) => switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.blocked,
    LocationPermission.denied when asked => LocationAccess.denied,
    LocationPermission.denied => LocationAccess.notAsked,
    LocationPermission.unableToDetermine => LocationAccess.notAsked,
  };
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => GeolocatorLocationService();
