import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'device_identity.g.dart';

/// 本机的安装 ID: 首次使用时随机生成的 UUID v7, 保存在安全存储中, 退出登录时保留.
///
/// 生成不等于采集. 安装 ID 只随设备注册, 登录请求和使用统计发出, 这些请求都在用户同意隐私政策之后.
/// iOS 卸载重装后 Keychain 中的安装 ID 通常仍在, Android 卸载即清除, Web 清除站点数据即清除.
class DeviceIdentity {
  DeviceIdentity(this._store);

  static const key = 'device.installId';

  final SecureStore _store;
  Future<String>? _installId;

  /// 读取安装 ID, 不存在时生成并保存. 同一次运行内只读取一次存储.
  ///
  /// 读取失败 (如备份恢复后无法解密) 时重新生成并覆盖旧值, 保存失败时仅在本次运行内使用新值.
  /// 两种情况均不抛出异常, 避免阻断启动和登录.
  Future<String> installId() => _installId ??= _load();

  Future<String> _load() async {
    try {
      final saved = await _store.read(key);
      if (saved != null && Uuid.isValidUUID(fromString: saved)) return saved;
    } on Object catch (e) {
      CrashReporter.recordBreadcrumb(
        'device',
        'install id unreadable: ${e.runtimeType}',
      );
    }
    final created = const Uuid().v7();
    try {
      await _store.write(key, created);
    } on Object catch (e) {
      CrashReporter.recordBreadcrumb(
        'device',
        'install id not saved: ${e.runtimeType}',
      );
    }
    return created;
  }
}

@Riverpod(keepAlive: true)
DeviceIdentity deviceIdentity(Ref ref) =>
    DeviceIdentity(ref.watch(secureStoreProvider));
