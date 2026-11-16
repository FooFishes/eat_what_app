import 'dart:ui';

import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/platform/hot_update.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_profile_io.dart'
    if (dart.library.js_interop) 'device_profile_web.dart'
    as platform;

part 'device_profile.g.dart';

/// 设备档案: 设备注册时随安装 ID 一起上报的设备与版本信息.
///
/// 读不到的项为 null, 不填推测值. 档案只作为风控线索, 客户端不据此判断设备是否可信.
class const DeviceProfile({
  /// `android`, `ios` 或 `web`.
  required final String platform,

  /// Android 的 ANDROID_ID 或 iOS 的 identifierForVendor. Web 没有.
  final String? hardwareId,

  /// 机型, 如 "Pixel 8", "iPhone 15 Pro". Web 不读取.
  final String? model,
  final String? osVersion,

  /// 版本名, 取自 `pubspec.yaml` 的 `version`.
  final String? appVersion,

  /// 构建号. 安装了热更新补丁时附加补丁号, 如 `62+3`.
  final String? appBuild,

  /// 屏幕的逻辑像素尺寸.
  final int? screenWidth,
  final int? screenHeight,
  final double? pixelRatio,
});

/// 设备中与平台相关的部分: 平台名, 硬件标识, 机型和系统版本.
typedef DeviceHardware = ({
  String platform,
  String? hardwareId,
  String? model,
  String? osVersion,
});

/// 构造构建号字段: 有补丁号时为 `构建号+补丁号`, 与后端设备档案的格式一致. 没有构建号时为 null.
String? appBuildOf(String? buildNumber, int? patch) => switch (buildNumber) {
  null || '' => null,
  final build when patch == null => build,
  final build => '$build+$patch',
};

/// 本机的设备档案. 每次运行只读取一次.
///
/// 读取设备信息须在用户同意隐私政策之后, 调用方负责把关. 单项读取失败只把该项置为 null, 整体不抛出异常.
@Riverpod(keepAlive: true)
Future<DeviceProfile> deviceProfile(Ref ref) async {
  final hardware = await platform.readHardware();
  Future<T?> safe<T>(Future<T> Function() read) async {
    try {
      return await read();
    } on Object {
      return null;
    }
  }

  final version = await safe(() => ref.read(appVersionProvider.future));
  final build = await safe(() => ref.read(appBuildNumberProvider.future));
  final patch = await safe(() => ref.read(currentPatchProvider.future));
  final display = PlatformDispatcher.instance.implicitView?.display;
  final ratio = display?.devicePixelRatio;
  final size = display == null || ratio == null || ratio <= 0
      ? null
      : display.size / ratio;
  int? side(double? value) => value == null || value < 1 ? null : value.round();
  return DeviceProfile(
    platform: hardware.platform,
    hardwareId: hardware.hardwareId,
    model: hardware.model,
    osVersion: hardware.osVersion,
    appVersion: version,
    appBuild: appBuildOf(build, patch),
    screenWidth: side(size?.width),
    screenHeight: side(size?.height),
    pixelRatio: size == null ? null : ratio,
  );
}
