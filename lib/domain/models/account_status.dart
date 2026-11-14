import 'package:eat/domain/models/current_user.dart';

/// 账号状态, 决定账号能执行哪些操作. 由登录态和当前用户计算得出.
sealed class AccountStatus {
  const AccountStatus();

  /// 未登录时为 [SignedOutStatus]. 已登录但尚未获取用户信息时按 [UnverifiedStatus] 处理.
  ///
  /// 封禁的账号仍能登录, 拿到只能浏览的受限会话. 是否封禁以 [user] 的 `banned` 为准.
  factory AccountStatus.of({required bool signedIn, CurrentUser? user}) {
    if (!signedIn) return const SignedOutStatus();
    if (user == null) return const UnverifiedStatus();
    if (user.banned) {
      return BannedStatus(reason: user.banReason, until: user.banUntil);
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
  const BannedStatus({this.reason, this.until});

  final String? reason;

  /// 封禁截止时间. null 表示永久封禁.
  ///
  /// 只用于展示. 是否已解封以服务端为准, 到期后客户端不自行放行.
  final DateTime? until;
}
