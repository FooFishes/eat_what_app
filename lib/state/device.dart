import 'dart:convert';

import 'package:eat/core/platform/device/device_identity.dart';
import 'package:eat/core/platform/device/device_profile.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:eat/data/device/device_api.dart';
import 'package:eat/data/device/device_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device.g.dart';

/// 设备注册: 用户同意隐私政策后向服务端登记本机的安装 ID 和设备档案.
///
/// 上次注册成功的请求体摘要存在 `prefs.*`, 档案 (App 版本, 系统版本等) 和安装 ID 都没变时不重发.
/// 注册失败时不记录摘要, 下次冷启动重试. 退出登录不注销设备.
class DeviceRegistration {
  DeviceRegistration(this._identity, this._profile, this._kv, this._api);

  static const digestKey = 'prefs.device.registered';

  final DeviceIdentity _identity;
  final Future<DeviceProfile> Function() _profile;
  final KvStore _kv;
  final DeviceApi _api;
  Future<void>? _running;

  /// 必要时注册本机. 同一次运行内只执行一次, 失败时静默.
  ///
  /// 调用方须确认本机已有同意记录.
  Future<void> register() => _running ??= _register();

  Future<void> _register() async {
    try {
      final request = DeviceRegisterRequestDto.of(
        await _identity.installId(),
        await _profile(),
      );
      final digest = digestOf(jsonEncode(request.toJson()));
      if (await _kv.read(digestKey) == digest) return;
      await _api.register(request);
      await _kv.write(digestKey, digest);
    } on Object {
      // 设备注册只用于风控和登录设备列表, 失败不影响使用, 等下次冷启动重试.
    }
  }

  /// 请求体的 32 位 FNV-1a 摘要 (8 位十六进制).
  ///
  /// 本地只存摘要而不存原文, 避免硬件标识随 `shared_preferences` 进入系统备份.
  /// 乘法拆成两部分计算, 使中间值不超过 2^53, Web 上的结果与 App 一致.
  static String digestOf(String text) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(text)) {
      hash ^= byte;
      hash = (hash * 0x193 + ((hash << 24) & 0xffffffff)) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

@Riverpod(keepAlive: true)
DeviceRegistration deviceRegistration(Ref ref) => DeviceRegistration(
  ref.watch(deviceIdentityProvider),
  () => ref.read(deviceProfileProvider.future),
  ref.watch(kvStoreProvider),
  ref.watch(deviceApiProvider),
);
