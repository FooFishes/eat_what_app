import 'package:eat/core/platform/device/device_profile.dart';

/// Web 没有硬件标识, 机型和系统版本也不读取, 均上报为 null.
Future<DeviceHardware> readHardware() async =>
    (platform: 'web', hardwareId: null, model: null, osVersion: null);
