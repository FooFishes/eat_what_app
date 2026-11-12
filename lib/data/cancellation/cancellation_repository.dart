import 'dart:convert';
import 'dart:math';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/storage/secure_store.dart';
import 'package:eat/data/cancellation/cancellation_api.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/cancellation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancellation_repository.g.dart';

/// 一次注销申请的参数. 申请失败重试时沿用, 改了选择要换新的.
class const CancellationDraft({
  required final String requestId,
  required final String recoveryCapability,
  required final bool deleteComments,
}) {
  @override
  String toString() => 'CancellationDraft[redacted]';
}

/// 撤销注销所需的凭据: 登录接口给出的申请, 以及申请时保存在本机的恢复凭据.
class const CancellationTicket({
  required final String subjectId,
  required final String requestId,
  required final String recoveryCapability,
}) {
  @override
  String toString() => 'CancellationTicket[redacted]';
}

/// 已发出的撤销验证码. 验证时提交同一个 [operationId].
class const RestoreCode({required final String operationId});

/// 注销账号: 申请, 冷静期内验证身份后撤销, 查询状态.
///
/// 冷静期内账号不能登录, 撤销只能凭申请时提交的恢复凭据. 凭据按申请 id 存在安全存储里,
/// 退出登录不删, 撤销成功后删除. 只有提交申请的这台设备能撤销.
class CancellationRepository {
  CancellationRepository(this._api, this._secure);

  static const _keyPrefix = 'lifecycle.recovery.';

  final CancellationApi _api;
  final SecureStore _secure;

  CancellationDraft draft({required bool deleteComments}) => CancellationDraft(
    requestId: _newId(),
    recoveryCapability: _newRecoveryCapability(),
    deleteComments: deleteComments,
  );

  /// 申请注销.
  ///
  /// 先保存恢复凭据再发请求: 请求已被受理但响应丢失时, 凭据仍在, 之后照样能撤销.
  Future<CancellationStatus> request(CancellationDraft draft) async {
    await _secure.write(_keyPrefix + draft.requestId, draft.recoveryCapability);
    return _status(
      await _api.request(
        requestId: draft.requestId,
        recoveryCapability: draft.recoveryCapability,
        deletePostsAndComments: draft.deleteComments,
      ),
    );
  }

  /// 本机保存的 [pending] 的恢复凭据. 申请不是在这台设备上提交的时返回 null.
  Future<CancellationTicket?> ticketFor(PendingCancellation pending) async {
    final capability = await _secure.read(_keyPrefix + pending.requestId);
    if (capability == null || capability.isEmpty) return null;
    return CancellationTicket(
      subjectId: pending.subjectId,
      requestId: pending.requestId,
      recoveryCapability: capability,
    );
  }

  Future<CancellationStatus> status(CancellationTicket ticket) async => _status(
    await _api.status(
      subjectId: ticket.subjectId,
      requestId: ticket.requestId,
      recoveryCapability: ticket.recoveryCapability,
    ),
  );

  /// 给账号绑定的手机发撤销用的验证码. 每次都用新的操作 id, 否则服务端不重发.
  Future<RestoreCode> sendRestoreCode(CancellationTicket ticket) async {
    final operationId = _newId();
    await _api.sendRecoveryCode(
      subjectId: ticket.subjectId,
      requestId: ticket.requestId,
      operationId: operationId,
      recoveryCapability: ticket.recoveryCapability,
    );
    return RestoreCode(operationId: operationId);
  }

  /// 用密码验证身份后撤销注销. [identifier] 是手机号, 用户名或邮箱.
  Future<CancellationStatus> restoreWithPassword(
    CancellationTicket ticket, {
    required String identifier,
    required String password,
  }) async {
    final grant = await _api.recoverWithPassword(
      identifier: identifier,
      password: password,
      subjectId: ticket.subjectId,
      requestId: ticket.requestId,
      operationId: _newId(),
      recoveryCapability: ticket.recoveryCapability,
    );
    return _cancel(ticket, grant);
  }

  /// 用 [sent] 发出的验证码验证身份后撤销注销.
  Future<CancellationStatus> restoreWithCode(
    CancellationTicket ticket,
    RestoreCode sent,
    String code,
  ) async {
    final grant = await _api.recoverWithCode(
      code: code,
      subjectId: ticket.subjectId,
      requestId: ticket.requestId,
      operationId: sent.operationId,
      recoveryCapability: ticket.recoveryCapability,
    );
    return _cancel(ticket, grant);
  }

  Future<CancellationStatus> _cancel(
    CancellationTicket ticket,
    RecoveryGrantDto grant,
  ) async {
    final operation = grant.operationId;
    if (operation == null) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no grant');
    }
    final status = _status(
      await _api.cancel(
        subjectId: ticket.subjectId,
        requestId: ticket.requestId,
        recoveryCapability: ticket.recoveryCapability,
        credentialOperation: operation,
      ),
    );
    await _secure.delete(_keyPrefix + ticket.requestId);
    return status;
  }

  static CancellationStatus _status(CancellationStatusDto dto) =>
      CancellationStatus(
        phase: CancellationPhase.parse(dto.phase),
        deadline: dateFromIso(dto.deadline),
        complete: dto.complete ?? false,
      );
}

/// 申请和操作的 id: 随机的 UUID v4. 旧版注销接口要求 id 为 UUID.
String _newId() {
  final r = Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) r.nextInt(256)];
  bytes[6] = bytes[6] & 0x0f | 0x40;
  bytes[8] = bytes[8] & 0x3f | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// 恢复凭据: 32 字节密码学随机值, 编码为不带填充的 Base64URL, 共 43 个字符.
String _newRecoveryCapability() {
  final r = Random.secure();
  final bytes = [for (var i = 0; i < 32; i++) r.nextInt(256)];
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// 旧版登录接口表示账号在注销冷静期内的业务码.
const cancellationPendingCode = 20006;

/// 登录失败是否因为账号正在注销. 是时返回登录接口给出的申请, 否则返回 null.
///
/// 冷静期内验证账号密码或验证码后, 登录接口返回 [cancellationPendingCode],
/// `data` 带 `recoveryRequired`, `subjectId`, `requestId` 和 `phase`.
PendingCancellation? pendingCancellationOf(AppFailure failure) =>
    switch (failure) {
      AppFailure(
        code: cancellationPendingCode,
        data: {
              'recoveryRequired': true,
              'subjectId': final String subjectId,
              'requestId': final String requestId,
            } &&
            final Map<Object?, Object?> data,
      ) =>
        PendingCancellation(
          subjectId: subjectId,
          requestId: requestId,
          phase: CancellationPhase.parse(data['phase'] as String?),
        ),
      _ => null,
    };

@Riverpod(keepAlive: true)
CancellationRepository cancellationRepository(Ref ref) =>
    CancellationRepository(
      ref.watch(cancellationApiProvider),
      ref.watch(secureStoreProvider),
    );
