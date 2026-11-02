import 'package:eat/domain/models/current_user.dart';

/// 账号状态, 决定账号能执行哪些操作. 由登录态和当前用户计算得出.
sealed class AccountStatus {
  const AccountStatus();

  /// 未登录时为 [SignedOutStatus]. 已登录但尚未获取用户信息时按 [UnverifiedStatus] 处理.
  /// 此时若本次登录得到的是受限会话 ([restricted]), 按封禁中处理.
  ///
  /// 受限会话只能调用后端登记的接口, 按未认证处理会放行被服务端拒绝的操作.
  factory AccountStatus.of({
    required bool signedIn,
    CurrentUser? user,
    bool restricted = false,
  }) {
    if (!signedIn) return const SignedOutStatus();
    if (user == null) {
      return restricted ? const BannedStatus() : const UnverifiedStatus();
    }
    if (user.banned) {
      return BannedStatus(
        reason: user.banReason,
        since: user.bannedAt,
        until: user.banUntil,
      );
    }
    return user.verified ? const VerifiedStatus() : const UnverifiedStatus();
  }
}

final class SignedOutStatus extends AccountStatus {
  const SignedOutStatus();
}

/// 已注册但未完成学生认证. 可以浏览, 不能发布和互动.
final class UnverifiedStatus extends AccountStatus {
  const UnverifiedStatus();
}

final class VerifiedStatus extends AccountStatus {
  const VerifiedStatus();
}

/// 封禁中. 可以浏览, 不能发布和互动.
final class BannedStatus extends AccountStatus {
  const BannedStatus({this.reason, this.since, this.until});

  final String? reason;
  final DateTime? since;

  /// 封禁截止时间. null 表示永久封禁, 或服务端没有期限证明.
  ///
  /// 只用于展示. 是否已解封以服务端为准, 到期后客户端不自行放行.
  final DateTime? until;
}
