import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'privacy_consent.g.dart';

/// 管理本机对 "隐私政策" 和 "用户协议" 的同意记录 (含版本号与时间戳), 在登录成功时写入.
///
/// 该记录属于设备级数据, 退出登录时不清除; 崩溃上报和推送等第三方 SDK 须在该记录存在后初始化.
class PrivacyConsentStore {
  PrivacyConsentStore(this._kv);

  static const key = 'prefs.consent.privacy';

  // TODO: 协议版本号目前硬编码在客户端, 协议更新后无法要求已同意旧版的用户重新勾选.
  // 远程配置上线后改为读取远程版本号, 本地版本更旧时回登录页重新勾选.
  /// 当前协议的版本. 协议改版时修改此值.
  static const currentVersion = '2026-10';

  final KvStore _kv;

  Future<void> record() => _kv.write(
    key,
    jsonEncode({
      'version': currentVersion,
      'at': clock.now().millisecondsSinceEpoch,
    }),
  );

  /// 本机同意过的协议版本. 未同意过时为 null.
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
