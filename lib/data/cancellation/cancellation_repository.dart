import 'dart:convert';

import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/data/cancellation/cancellation_api.dart';
import 'package:eat/data/common/convert.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancellation_repository.g.dart';

/// 注销账号: 发验证码, 申请, 保存撤销凭据.
///
/// 撤销凭据存在安全存储里, 退出登录不删. 只有提交申请的这台设备有凭据, 冷静期内在这里登录时随登录请求带上,
/// 服务端验证密码或验证码之后即撤销注销. 登录的是申请注销的账号时, 登录后删除凭据.
class CancellationRepository {
  CancellationRepository(this._api, this._secure);

  static const _key = 'account.deletion';

  final CancellationApi _api;
  final SecureStore _secure;

  Future<void> sendCode(CaptchaTicket? ticket) =>
      _api.sendCode(captchaHeaders: ticket?.headers ?? const {});

  /// 申请注销 [userId], 保存撤销凭据, 返回彻底删除的时间. 服务端没有给出时为 null.
  ///
  /// 有手机号的账号带 [code], 没有手机号的带 [password]. 失败时抛出 `AppFailure`.
  Future<DateTime?> request({
    required int userId,
    String? code,
    String? password,
    required bool deleteComments,
  }) async {
    final dto = await _api.request(
      code: code,
      password: password,
      deleteComments: deleteComments,
    );
    if (dto.deletionKey case final key? when key.isNotEmpty) {
      await _secure.write(_key, jsonEncode({'userId': userId, 'key': key}));
    }
    return dateFromMillis(dto.deleteAt);
  }

  /// 本机保存的撤销凭据. 登录时带上, 账号不在冷静期时服务端忽略它.
  Future<String?> deletionKey() async => (await _stored())?.key;

  /// 登录成功后调用. 登录的是申请注销的账号 [userId] 时, 注销已撤销, 删除凭据.
  Future<void> signedIn(int userId) async {
    if ((await _stored())?.userId == userId) await _secure.delete(_key);
  }

  Future<({int userId, String key})?> _stored() async {
    final raw = await _secure.read(_key);
    if (raw == null) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    if (decoded case {'userId': final num userId, 'key': final String key}) {
      return (userId: userId.toInt(), key: key);
    }
    await _secure.delete(_key);
    return null;
  }
}

@Riverpod(keepAlive: true)
CancellationRepository cancellationRepository(Ref ref) =>
    CancellationRepository(
      ref.watch(cancellationApiProvider),
      ref.watch(secureStoreProvider),
    );
