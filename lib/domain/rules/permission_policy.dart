import 'package:eat/domain/models/account_status.dart';

/// 要按账号状态拦截的动作（产品 7.2）。浏览、消息、设置、反馈、举报、屏蔽、退出、注销
/// 对所有登录了的账号都开放，不在这里。
enum Capability {
  like,
  favorite,
  tasteTag,
  myTag,
  comment,
  reply,
  rateShop,
  follow,
  publishDish,
  createShop,
  editOwnDish,

  /// 编辑资料。未认证能做，封禁中不能。
  editProfile,
}

/// 一次权限判断的结果。
sealed class PermissionResult {
  const PermissionResult();
}

final class Allowed extends PermissionResult {
  const Allowed();
}

/// 没登录。守卫会先把人带到登录页，正常走不到这里。
final class NeedsSignIn extends PermissionResult {
  const NeedsSignIn();
}

/// 要先认证，面板写「认证后才能……」，主按钮「去认证」。
final class NeedsVerification extends PermissionResult {
  const NeedsVerification();
}

/// 封禁中，面板写原因，没有「去认证」。
final class BlockedByBan extends PermissionResult {
  const BlockedByBan(this.status);

  final BannedStatus status;
}

/// [status] 的账号能不能做 [capability]，规则按产品 7.2 的表。
PermissionResult checkPermission(AccountStatus status, Capability capability) =>
    switch (status) {
      SignedOutStatus() => const NeedsSignIn(),
      VerifiedStatus() => const Allowed(),
      UnverifiedStatus() when capability == Capability.editProfile =>
        const Allowed(),
      UnverifiedStatus() => const NeedsVerification(),
      final BannedStatus banned => BlockedByBan(banned),
    };
