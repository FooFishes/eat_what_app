import 'package:eat/domain/models/current_user.dart';

/// 账号状态, 决定账号能执行哪些操作. 由登录态和当前用户计算得出.
sealed class AccountStatus {
  const AccountStatus();

  /// 未登录时为 [SignedOutStatus]. 已登录但尚未获取用户信息时按 [UnverifiedStatus] 处理.
  ///
  /// 封禁的账号仍可登录并获取仅能浏览的受限会话, 是否封禁以 [user] 的 `banned` 字段为准.
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

/// 已注册但未完成学生认证的状态, 仅支持浏览, 不可发布或互动.
final class UnverifiedStatus extends AccountStatus {
  const UnverifiedStatus();
}

final class VerifiedStatus extends AccountStatus {
  const VerifiedStatus();
}

/// 账号封禁中的状态, 仅支持浏览, 不可发布或互动.
final class BannedStatus extends AccountStatus {
  const BannedStatus({this.reason, this.until});

  final String? reason;

  /// 封禁截止时间, 为 null 时表示永久封禁.
  ///
  /// 仅用于界面展示. 是否已解封以服务端判断为准, 到期后客户端不自行放行.
  final DateTime? until;
}
