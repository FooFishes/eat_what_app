import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'kv_store.g.dart';

/// 丢了也无所谓的键值：偏好、同意记录、接口缓存。值都是字符串，结构化的内容存 JSON。
///
/// 键按用途加前缀分组（`prefs.*`、`cache.*`），退出登录时按前缀清掉账号作用域的数据。
/// 必须可靠的数据（登录 token）放 `SecureStore`。
abstract interface class KvStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// 删掉键以 [prefix] 开头的全部数据。
  Future<void> deletePrefix(String prefix);
}

/// 存在 `shared_preferences` 里：安卓 DataStore、iOS NSUserDefaults、Web localStorage。
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

/// 应用里唯一的 [KvStore]，测试里换成内存实现。
@Riverpod(keepAlive: true)
KvStore kvStore(Ref ref) => PrefsKvStore();
