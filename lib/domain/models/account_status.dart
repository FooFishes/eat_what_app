import 'package:eat/domain/models/current_user.dart';

/// 账号状态, 决定账号能执行哪些操作. 由登录态和当前用户计算得出.
sealed class AccountStatus {
  const AccountStatus();

  /// 未登录时为 [SignedOutStatus]. 已登录但尚未获取用户信息时按 [UnverifiedStatus] 处理.
  ///
  /// 没有封禁状态: 服务端不让封禁的账号登录, 已登录的会话在封禁时被下线.
  factory AccountStatus.of({required bool signedIn, CurrentUser? user}) {
    if (!signedIn) return const SignedOutStatus();
    return user?.verified ?? false
        ? const VerifiedStatus()
        : const UnverifiedStatus();
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
