import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:eat/core/storage/kv_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'privacy_consent.g.dart';

/// 管理本机对 "隐私政策" 和 "用户协议" 的同意记录, 在登录成功或以游客身份进入时写入.
///
/// 记录含同意时间和用户同意的服务端政策版本. 版本以服务端为准, 客户端不另设版本号; 拿不到服务端版本时只记时间.
/// 该记录属于设备级数据, 退出登录时不清除; 崩溃上报和推送等第三方 SDK 须在该记录存在后初始化, 不看版本.
class PrivacyConsentStore {
  PrivacyConsentStore(this._kv);

  static const key = 'prefs.consent.privacy';

  final KvStore _kv;

  /// 记下本机已同意. [version] 是用户同意的服务端政策版本, 服务端还没发布政策或这次没有取到时为 null.
  Future<void> record(String? version) => _kv.write(
    key,
    jsonEncode({'version': ?version, 'at': clock.now().millisecondsSinceEpoch}),
  );

  /// 本机是否同意过. 早期版本写入的记录 (版本为客户端常量) 也算同意过.
  Future<bool> agreed() async => await _read() != null;

  /// 本机同意过的政策版本. 未同意过, 或同意时没有服务端版本时为 null.
  Future<String?> agreedVersion() async =>
      (await _read())?['version'] as String?;

  Future<Map<String, dynamic>?> _read() async {
    final raw = await _kv.read(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
PrivacyConsentStore privacyConsentStore(Ref ref) =>
    PrivacyConsentStore(ref.watch(kvStoreProvider));
