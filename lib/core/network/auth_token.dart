import 'package:eat/core/storage/secure_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_token.g.dart';

/// 登录返回的会话凭证：请求头名 [name]（当前部署是 `satoken`），值 `Bearer <value>`。
///
/// 头名以登录接口返回的为准，不写死；两者一起存进安全存储。
class const AuthToken({
  required final String name,
  required final String value,
}) {
  String get headerValue => 'Bearer $value';
}

/// 当前的登录凭证：内存里一份给网络层同步读取，安全存储里一份跨启动保留。
class TokenStore {
  TokenStore(this._secure);

  static const _nameKey = 'auth.tokenName';
  static const _valueKey = 'auth.tokenValue';

  final SecureStore _secure;
  AuthToken? _current;

  AuthToken? get current => _current;

  /// 启动时从安全存储读出上一次的凭证。
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

  /// 先清内存再删存储：同时过期的几个请求里，只有第一个看得到旧凭证，登录过期只处理一次。
  Future<void> clear() async {
    _current = null;
    await _secure.delete(_nameKey);
    await _secure.delete(_valueKey);
  }
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => TokenStore(ref.watch(secureStoreProvider));
