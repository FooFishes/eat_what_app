import 'package:eat/domain/models/account_status.dart';

/// 需要按账号状态拦截的操作.
///
/// 浏览, 消息, 设置, 反馈, 举报, 屏蔽, 退出和注销对所有已登录账号开放, 不在本枚举中.
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

  /// 编辑资料. 未认证账号可以执行, 封禁中的账号不能.
  editProfile;

  /// 拦截面板中的动作词, 如 "认证后才能点赞" 中的 "点赞".
  String get verb => switch (this) {
    like => '点赞',
    favorite => '收藏',
    tasteTag || myTag => '加标签',
    comment => '评论',
    reply => '回复',
    rateShop => '评价',
    follow => '关注',
    publishDish => '发布',
    createShop => '新建店',
    editOwnDish => '编辑',
    editProfile => '编辑资料',
  };
}

/// 权限判断的结果.
sealed class PermissionResult {
  const PermissionResult();
}

final class Allowed extends PermissionResult {
  const Allowed();
}

/// 未登录. 守卫会先把用户重定向到登录页, 正常流程不会得到该结果.
final class NeedsSignIn extends PermissionResult {
  const NeedsSignIn();
}

/// 需要先认证. 拦截面板显示 "认证后才能...", 主按钮为 "去认证".
final class NeedsVerification extends PermissionResult {
  const NeedsVerification();
}

/// 账号封禁中. 拦截面板显示封禁原因, 不提供 "去认证".
final class BlockedByBan extends PermissionResult {
  const BlockedByBan(this.status);

  final BannedStatus status;
}

/// [status] 的账号能否执行 [capability].
PermissionResult checkPermission(AccountStatus status, Capability capability) =>
    switch (status) {
      SignedOutStatus() => const NeedsSignIn(),
      VerifiedStatus() => const Allowed(),
      UnverifiedStatus() when capability == Capability.editProfile =>
        const Allowed(),
      UnverifiedStatus() => const NeedsVerification(),
      final BannedStatus banned => BlockedByBan(banned),
    };
