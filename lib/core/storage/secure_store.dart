import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_store.g.dart';

// TODO: Web 的加密密钥同样存放在浏览器中, 无法防御注入页面的脚本.
// 后端支持 httpOnly Cookie 且同源部署后, Web 改用 Cookie 保存登录态.
/// 登录 token 等必须可靠保存, 且不能被其他应用读取的值.
///
/// - Android: 用 Keystore 加密后存储.
/// - iOS: 存入 Keychain.
/// - Web: 用 WebCrypto 加密后存入 localStorage.
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

/// 应用唯一的 [SecureStore]. 测试中替换为内存实现.
@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => PlatformSecureStore();
