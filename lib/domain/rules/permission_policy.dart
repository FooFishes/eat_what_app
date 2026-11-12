import 'package:eat/domain/models/account_status.dart';

/// 需要按账号状态拦截的操作.
///
/// 未登录 (含游客) 时所有操作都要先登录. 浏览, 屏蔽和退出对所有已登录账号开放, 不在本枚举中.
///
/// [Capability.openToUnverified] 中的操作对所有已登录账号开放. 列入本枚举是为了让游客点入口时弹出登录拦截.
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

  /// 编辑菜品和恢复到某个修改记录. 认证用户都能编辑任何一道菜, 不限上传者.
  editDish,

  /// 编辑店铺和恢复到某个修改记录. 认证用户都能编辑任何一家店, 包括标记已关门.
  editShop,

  /// 删除自己的评论和回复. 后端只要求本人, 不要求认证.
  deleteComment,
  editProfile,
  viewHistory,

  /// 查看粉丝和关注列表.
  viewFollows,

  /// 查看等级和经验明细.
  viewGrowth,
  unfollow,

  /// 修改隐私和推荐设置.
  changePrivacy,

  /// 设置或修改密码.
  changePassword,
  setUsername,

  /// 学生认证.
  verify,

  /// 举报菜, 评论和用户. 所有已登录账号都能执行.
  ///
  /// 列入本枚举是为了复用拦截和失败反馈: 服务端拒绝时按刷新后的账号状态处理.
  report,

  /// 店铺 "信息有误". 所有已登录账号都能执行, 列入本枚举的原因同 [report].
  reportShopError,

  /// 看消息. 所有已登录账号都能执行.
  ///
  /// 游客能点到入口, 列入本枚举是为了让游客看到 "登录后才能看消息" 的面板, 而不是被守卫直接带去登录页.
  viewInbox,

  /// 看他人主页 (含他上传的菜). 所有已登录账号都能执行, 列入本枚举的原因同 [viewInbox].
  viewProfile,

  /// 附近页 "只看我收藏的店". 所有已登录账号都能执行, 列入本枚举的原因同 [viewInbox].
  viewFavorites,

  /// 发现页 "不想去这家": 30 天内不再推荐. 所有已登录账号都能执行, 列入本枚举的原因同 [viewInbox].
  dismissShop,

  /// 意见反馈. 所有已登录账号都能执行, 列入本枚举的原因同 [viewInbox].
  feedback;

  /// 未认证账号也能执行的操作. 其余操作要求已认证.
  bool get openToUnverified => switch (this) {
    editProfile ||
    deleteComment ||
    viewHistory ||
    viewFollows ||
    viewGrowth ||
    unfollow ||
    changePrivacy ||
    changePassword ||
    setUsername ||
    verify ||
    report ||
    reportShopError ||
    viewInbox ||
    viewProfile ||
    viewFavorites ||
    dismissShop ||
    feedback => true,
    _ => false,
  };

  /// 拦截对话框中的动作词, 如 "认证后才能点赞" 和 "登录后才能点赞" 中的 "点赞".
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
    editDish => '编辑',
    editShop => '编辑店铺',
    deleteComment => '删除评论',
    editProfile => '编辑资料',
    viewHistory => '查看足迹',
    viewFollows => '查看粉丝和关注',
    viewGrowth => '查看等级',
    unfollow => '取消关注',
    changePrivacy => '修改隐私设置',
    changePassword => '修改密码',
    setUsername => '设置用户名',
    verify => '进行学生认证',
    report => '举报',
    reportShopError => '反馈信息有误',
    viewInbox => '看消息',
    viewProfile => '看主页',
    viewFavorites => '看收藏',
    dismissShop => '标记不想去',
    feedback => '反馈',
  };
}

/// 权限判断的结果.
sealed class PermissionResult {
  const PermissionResult();
}

final class Allowed extends PermissionResult {
  const Allowed();
}

/// 未登录, 只出现在游客身上. 拦截对话框显示 "登录后才能...", 主按钮为 "去登录".
///
/// 没点 "先逛逛" 的未登录状态会被守卫带去登录页, 正常流程不会得到该结果.
final class NeedsSignIn extends PermissionResult {
  const NeedsSignIn();
}

/// 需要先认证. 拦截对话框显示 "认证后才能...", 主按钮为 "去认证".
final class NeedsVerification extends PermissionResult {
  const NeedsVerification();
}

/// [status] 的账号能否执行 [capability].
PermissionResult checkPermission(AccountStatus status, Capability capability) =>
    switch (status) {
      SignedOutStatus() => const NeedsSignIn(),
      VerifiedStatus() => const Allowed(),
      UnverifiedStatus() when capability.openToUnverified => const Allowed(),
      UnverifiedStatus() => const NeedsVerification(),
    };
