import 'package:eat/domain/models/account_status.dart';

/// 需要按账号状态拦截的操作.
///
/// 浏览, 消息, 屏蔽和退出对所有已登录账号开放, 不在本枚举中.
///
/// 封禁账号的会话只能调用后端登记过的接口, 登记范围比产品允许封禁中账号执行的操作窄.
/// 两者不一致时以后端为准, 否则入口放行后请求仍会被拒绝.
/// 因此 [viewHistory] 起的几项也在本枚举中, 只拦截封禁中的账号.
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

  /// 删除自己的评论和回复. 后端只要求普通会话和本人, 不要求认证, 因此只拦截封禁中的账号.
  deleteComment,

  /// 编辑资料. 未认证账号可以执行, 封禁中的账号不能.
  editProfile,

  /// 查看足迹. 产品允许封禁中查看, 后端未登记 `/history/browse`.
  viewHistory,

  /// 查看粉丝和关注列表. 后端未登记 `/user/followers`, `/user/followings`.
  viewFollows,

  /// 取消关注. 后端未登记 `/user/unfollow`.
  unfollow,

  /// 修改隐私和推荐设置. 后端未登记 `/user/changePrivacy`, `/user/recommendation-settings`.
  changePrivacy,

  /// 设置或修改密码. 后端未登记改密和发送改密验证码的接口.
  changePassword,

  /// 设置用户名. 后端未登记 `/auth/username/set`.
  setUsername,

  /// 学生认证. 后端未登记 `/auth/sdu`, `/auth/sendEmail`.
  verify,

  /// 举报菜, 评论和用户. 所有已登录账号都能执行.
  ///
  /// 列入本枚举是为了复用拦截和失败反馈: 服务端拒绝时按刷新后的账号状态处理.
  report,

  /// 店铺 "信息有误". 所有已登录账号都能执行, 列入本枚举的原因同 [report].
  reportShopError;

  /// 未认证账号也能执行的操作. 其余操作要求已认证.
  bool get openToUnverified => switch (this) {
    editProfile ||
    deleteComment ||
    viewHistory ||
    viewFollows ||
    unfollow ||
    changePrivacy ||
    changePassword ||
    setUsername ||
    verify ||
    report ||
    reportShopError => true,
    _ => false,
  };

  /// 封禁中的账号也能执行的操作. 后端的受限会话放行反馈, 信息有误和举报.
  bool get openToBanned => switch (this) {
    report || reportShopError => true,
    _ => false,
  };

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
    deleteComment => '删除评论',
    editProfile => '编辑资料',
    viewHistory => '查看足迹',
    viewFollows => '查看粉丝和关注',
    unfollow => '取消关注',
    changePrivacy => '修改隐私设置',
    changePassword => '修改密码',
    setUsername => '设置用户名',
    verify => '进行学生认证',
    report => '举报',
    reportShopError => '反馈信息有误',
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
      UnverifiedStatus() when capability.openToUnverified => const Allowed(),
      UnverifiedStatus() => const NeedsVerification(),
      BannedStatus() when capability.openToBanned => const Allowed(),
      final BannedStatus banned => BlockedByBan(banned),
    };
