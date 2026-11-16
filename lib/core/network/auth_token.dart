import 'package:eat/core/storage/secure_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_token.g.dart';

/// 登录返回的会话凭证, 请求头名为 [name], 值为 `Bearer <value>`.
///
/// 头名以登录接口实际返回为准 (当前后端部署为 `satoken`), 并与凭证值一并存入安全存储.
class const AuthToken({
  required final String name,
  required final String value,
}) {
  String get headerValue => 'Bearer $value';
}

/// 当前登录凭证. 内存中的副本供网络层同步读取, 安全存储中的副本用于跨启动恢复.
class TokenStore {
  TokenStore(this._secure);

  static const _nameKey = 'auth.tokenName';
  static const _valueKey = 'auth.tokenValue';

  final SecureStore _secure;
  AuthToken? _current;

  AuthToken? get current => _current;

  /// 启动时从安全存储读取上次保存的凭证.
  Future<AuthToken?> load() async {
    final name = await _secure.read(_nameKey);
    final value = await _secure.read(_valueKey);
    if (name == null || name.isEmpty || value == null || value.isEmpty) {
      return _current = null;
    }
    return _current = AuthToken(name: name, value: value);
  }

  Future<void> save(AuthToken token) async {
    _current = token;
    await _secure.write(_nameKey, token.name);
    await _secure.write(_valueKey, token.value);
  }

  /// 清除凭证. 先清内存, 再删存储.
  ///
  /// 并发过期的多个请求中只有第一个能读到旧凭证, 因此登录过期只处理一次.
  Future<void> clear() async {
    _current = null;
    await _secure.delete(_nameKey);
    await _secure.delete(_valueKey);
  }
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => TokenStore(ref.watch(secureStoreProvider));
