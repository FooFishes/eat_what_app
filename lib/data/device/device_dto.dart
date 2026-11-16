import 'package:eat/core/platform/device/device_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_dto.g.dart';

/// 设备注册的请求体 (后端 `DeviceDtos.Register`). 没有读到的档案项不发送.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const DeviceRegisterRequestDto({
  required final String installId,
  required final String platform,
  final String? hardwareId,
  final String? model,
  final String? osVersion,
  final String? appVersion,
  final String? appBuild,
  final int? screenWidth,
  final int? screenHeight,
  final double? pixelRatio,
}) {
  DeviceRegisterRequestDto.of(String installId, DeviceProfile profile)
    : this(
        installId: installId,
        platform: profile.platform,
        hardwareId: profile.hardwareId,
        model: profile.model,
        osVersion: profile.osVersion,
        appVersion: profile.appVersion,
        appBuild: profile.appBuild,
        screenWidth: profile.screenWidth,
        screenHeight: profile.screenHeight,
        pixelRatio: profile.pixelRatio,
      );

  Map<String, dynamic> toJson() => _$DeviceRegisterRequestDtoToJson(this);
}
