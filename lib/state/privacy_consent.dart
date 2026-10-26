import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'privacy_consent.g.dart';

/// 本机同意《隐私政策》《用户协议》的记录（版本和时间）。登录页勾选后、登录成功时写入。
///
/// 是设备级的数据，退出登录不删。以后有了这条记录才初始化崩溃上报、推送这些 SDK（技术架构 9.4）。
class PrivacyConsentStore {
  PrivacyConsentStore(this._kv);

  static const key = 'prefs.consent.privacy';

  /// 当前协议的版本。远程配置上线前写死；协议改版时改这里（技术架构待确认 A7）。
  static const currentVersion = '2026-10';

  final KvStore _kv;

  Future<void> record() => _kv.write(
    key,
    jsonEncode({
      'version': currentVersion,
      'at': clock.now().millisecondsSinceEpoch,
    }),
  );

  /// 本机同意过的协议版本，没同意过为 null。
  Future<String?> agreedVersion() async {
    final raw = await _kv.read(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['version'] as String?;
    } on Object {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
PrivacyConsentStore privacyConsentStore(Ref ref) =>
    PrivacyConsentStore(ref.watch(kvStoreProvider));
