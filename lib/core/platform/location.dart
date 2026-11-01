import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location.g.dart';

/// 定位权限的状态.
enum LocationAccess {
  /// 尚未向系统申请.
  notAsked,
  granted,

  /// 已拒绝, 仍可再次申请.
  denied,

  /// 永久拒绝或系统定位服务已关闭. 只能由用户在系统设置中开启.
  blocked,
}

/// 设备定位, 封装 `geolocator`. 只返回 WGS-84 坐标, 由上层转换为 GCJ-02.
///
/// 只在需要时单次定位, 不持续监听, 不在后台定位, 位置不写入磁盘.
abstract interface class LocationService {
  Future<LocationAccess> access();

  /// 弹出系统权限框. 已永久拒绝时不弹出, 直接返回 [LocationAccess.blocked].
  Future<LocationAccess> request();

  /// 当前位置的 WGS-84 坐标.
  ///
  /// 定位失败时使用系统记录的上次位置. 两者都取不到时返回 null.
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
