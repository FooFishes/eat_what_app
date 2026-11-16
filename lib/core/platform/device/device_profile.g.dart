// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_profile.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本机的设备档案. 每次运行只读取一次.
///
/// 读取设备信息须在用户同意隐私政策之后, 调用方负责把关. 单项读取失败只把该项置为 null, 整体不抛出异常.

@ProviderFor(deviceProfile)
final deviceProfileProvider = DeviceProfileProvider._();

/// 本机的设备档案. 每次运行只读取一次.
///
/// 读取设备信息须在用户同意隐私政策之后, 调用方负责把关. 单项读取失败只把该项置为 null, 整体不抛出异常.

final class DeviceProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceProfile>,
          DeviceProfile,
          FutureOr<DeviceProfile>
        >
    with $FutureModifier<DeviceProfile>, $FutureProvider<DeviceProfile> {
  /// 本机的设备档案. 每次运行只读取一次.
  ///
  /// 读取设备信息须在用户同意隐私政策之后, 调用方负责把关. 单项读取失败只把该项置为 null, 整体不抛出异常.
  DeviceProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceProfileHash();

  @$internal
  @override
  $FutureProviderElement<DeviceProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeviceProfile> create(Ref ref) {
    return deviceProfile(ref);
  }
}

String _$deviceProfileHash() => r'3237ef964d8c48078c2a5b14bb92fa38a8355d13';
