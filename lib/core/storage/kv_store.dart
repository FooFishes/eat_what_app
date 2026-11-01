import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'kv_store.g.dart';

/// 允许丢失的键值数据: 偏好, 同意记录, 接口缓存. 值均为字符串, 结构化内容存为 JSON.
///
/// 键按用途加前缀分组 (`prefs.*`, `cache.*`), 退出登录时按前缀清除账号作用域的数据.
/// 必须可靠保存的数据 (如登录 token) 使用 `SecureStore`.
abstract interface class KvStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// 删除键以 [prefix] 开头的全部数据.
  Future<void> deletePrefix(String prefix);
}

/// 基于 `shared_preferences` 的实现. Android 为 DataStore, iOS 为 NSUserDefaults, Web 为 localStorage.
class PrefsKvStore implements KvStore {
  PrefsKvStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);

  @override
  Future<void> deletePrefix(String prefix) async {
    final keys = await _prefs.getKeys();
    final matched = keys.where((key) => key.startsWith(prefix)).toSet();
    if (matched.isNotEmpty) await _prefs.clear(allowList: matched);
  }
}

/// 应用唯一的 [KvStore]. 测试中替换为内存实现.
@Riverpod(keepAlive: true)
KvStore kvStore(Ref ref) => PrefsKvStore();
