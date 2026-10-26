import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_store.g.dart';

/// 登录 token 这类必须可靠、不能被别的应用读到的值。
///
/// 安卓存 Keystore 加密的数据，iOS 存 Keychain，Web 用 WebCrypto 加密后存 localStorage
/// （密钥也在浏览器里，挡不住页面被注入的脚本，见技术架构待确认 A10）。
abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class PlatformSecureStore implements SecureStore {
  PlatformSecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// 应用里唯一的 [SecureStore]，测试里换成内存实现。
@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => PlatformSecureStore();
