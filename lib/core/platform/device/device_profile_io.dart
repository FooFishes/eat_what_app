import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:eat/core/platform/device/device_profile.dart';
import 'package:flutter/foundation.dart';

/// 读取 Android 和 iOS 的硬件标识, 机型与系统版本. 读取失败的项为 null.
Future<DeviceHardware> readHardware() async {
  final info = DeviceInfoPlugin();
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      AndroidDeviceInfo? device;
      String? id;
      try {
        device = await info.androidInfo;
      } on Object {
        device = null;
      }
      try {
        id = await const AndroidId().getId();
      } on Object {
        id = null;
      }
      return (
        platform: 'android',
        hardwareId: id,
        model: device?.model,
        osVersion: device?.version.release,
      );
    case TargetPlatform.iOS:
      try {
        final device = await info.iosInfo;
        return (
          platform: 'ios',
          hardwareId: device.identifierForVendor,
          model: device.modelName,
          osVersion: device.systemVersion,
        );
      } on Object {
        return (
          platform: 'ios',
          hardwareId: null,
          model: null,
          osVersion: null,
        );
      }
    case final other:
      return (
        platform: other.name,
        hardwareId: null,
        model: null,
        osVersion: null,
      );
  }
}
