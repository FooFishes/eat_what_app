import 'dart:convert';

import 'package:eat/core/platform/captcha/human_verifier.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/data/cancellation/cancellation_api.dart';
import 'package:eat/data/common/convert.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancellation_repository.g.dart';

/// 负责账号注销流程, 包括发送验证码, 提交注销申请及保存撤销凭据.
///
/// 撤销凭据保存在安全存储中, 退出登录时不清除. 仅提交申请的设备持有该凭据;
/// 冷静期内在该设备登录时随请求附带该凭据, 服务端校验密码或验证码后即撤销注销, 确认登录到申请注销的账号后删除本地凭据.
class CancellationRepository {
  CancellationRepository(this._api, this._secure);

  static const _key = 'account.deletion';

  final CancellationApi _api;
  final SecureStore _secure;

  Future<void> sendCode(CaptchaTicket? ticket) =>
      _api.sendCode(captchaHeaders: ticket?.headers ?? const {});

  /// 为 [userId] 提交注销申请并保存撤销凭据, 返回预计彻底删除的时间 (服务端未返回时为 null).
  ///
  /// 已绑定手机号的账号传入 [code], 未绑定手机号的账号传入 [password], 失败时抛出 `AppFailure`.
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

  /// 读取本机保存的撤销凭据. 登录时随请求附带, 若账号不在冷静期内则由服务端忽略.
  Future<String?> deletionKey() async => (await _stored())?.key;

  /// 在登录成功后调用. 若登录的正是申请注销的账号 [userId], 说明注销已被撤销, 此时清除本地凭据.
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
