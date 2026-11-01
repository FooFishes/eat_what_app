import 'package:eat/domain/models/current_user.dart';

/// 账号状态, 决定账号能执行哪些操作. 由登录态和当前用户计算得出.
sealed class AccountStatus {
  const AccountStatus();

  /// 未登录时为 [SignedOutStatus]. 已登录但尚未获取用户信息时按 [UnverifiedStatus] 处理.
  ///
  /// 宁可多拦截一次, 也不让未认证的账号发起会被服务端拒绝的操作.
  factory AccountStatus.of({required bool signedIn, CurrentUser? user}) {
    if (!signedIn) return const SignedOutStatus();
    if (user == null) return const UnverifiedStatus();
    if (user.banned) {
      return BannedStatus(reason: user.banReason, since: user.bannedAt);
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

// TODO: `/user/info` 只返回封禁时间, 没有解封时间, 拦截面板无法显示恢复时间. 接口提供解封时间后加入本类并在面板中显示.
/// 封禁中. 可以浏览, 不能发布和互动.
final class BannedStatus extends AccountStatus {
  const BannedStatus({this.reason, this.since});

  final String? reason;
  final DateTime? since;
}
