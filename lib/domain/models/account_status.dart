import 'package:eat/domain/models/current_user.dart';

/// 账号现在能做什么的四种状态（产品 4.10），由当前用户算出来。
sealed class AccountStatus {
  const AccountStatus();

  /// 没有用户信息时（还没登录，或者登录了但用户信息还没拉到）当作未登录或未认证处理：
  /// 宁可多拦一次，也不让没认证的账号点出服务端会拒绝的操作。
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

/// 注册了，还没完成学生认证。能浏览，不能发布和互动。
final class UnverifiedStatus extends AccountStatus {
  const UnverifiedStatus();
}

final class VerifiedStatus extends AccountStatus {
  const VerifiedStatus();
}

/// 封禁中。能浏览，不能发布和互动。
///
/// 接口只给了封禁时间，没有解封时间（`/user/info` 没有 `banExpireAt`），面板上先不写恢复时间。
final class BannedStatus extends AccountStatus {
  const BannedStatus({this.reason, this.since});

  final String? reason;
  final DateTime? since;
}
