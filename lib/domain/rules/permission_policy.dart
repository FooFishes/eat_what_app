import 'package:eat/domain/models/account_status.dart';

/// 需要按账号状态拦截的操作.
///
/// 未登录 (含游客) 时所有操作都要先登录. 浏览, 屏蔽和退出对所有已登录账号开放, 不在本枚举中.
///
/// [Capability.openToUnverified] 中的操作对未认证账号开放. 其中部分只读的操作列入本枚举, 是为了让游客点入口时弹出登录拦截.
///
/// 封禁中的账号持有受限会话: 后端默认放行读取并拒绝写入, 少数接口例外 (见 [Capability.openToBanned]).
enum Capability {
  like,

  /// 评论的表情回应, 要求的身份和点赞相同.
  react,
  favorite,
  tasteTag,
  myTag,
  comment,
  reply,
  rateShop,

  /// 给菜品打 1–5 分. 后端撤销评分只要求登录, 但撤销和打分在同一个面板里, 入口统一按评分拦截.
  rateDish,
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

  /// 查看粉丝和关注列表. 封禁状态不可查看, 后端会拒绝这两个列表的请求.
  viewFollows,

  /// 查看等级和经验明细. 封禁状态不可查看, 后端会拒绝经验明细请求.
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

  /// 查看消息列表, 所有已登录账号均可执行.
  ///
  /// 游客可点击该入口, 列入本枚举是为了向游客展示 "登录后才能看消息" 的拦截面板, 避免被路由守卫直接重定向至登录页.
  viewInbox,

  /// 查看他人主页 (含其上传的菜品), 所有已登录账号均可执行, 列入本枚举的原因同 [viewInbox].
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

  /// 封禁账号仍可执行的操作, 后端受限会话放行常规读取以及消息已读, 反馈, 信息有误和举报.
  ///
  /// 足迹, 粉丝和关注列表, 经验明细虽属读取操作但仍会被后端拒绝, 因此未列入其中.
  bool get openToBanned => switch (this) {
    report ||
    reportShopError ||
    viewInbox ||
    viewProfile ||
    viewFavorites ||
    feedback => true,
    _ => false,
  };

  /// 拦截对话框中的动作词, 如 "认证后才能点赞" 和 "登录后才能点赞" 中的 "点赞".
  String get verb => switch (this) {
    like => '点赞',
    react => '回应',
    favorite => '收藏',
    tasteTag || myTag => '加标签',
    comment => '评论',
    reply => '回复',
    rateShop => '评价',
    rateDish => '评分',
    follow => '关注',
    publishDish => '发布',
    createShop => '新建店',
    editDish => '编辑',
    editShop => '编辑店铺',
    deleteComment => '删除评论',
    editProfile => '编辑资料',
    viewHistory => '查看历史',
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

/// 未登录拦截结果, 仅在游客状态下触发, 对话框提示 "登录后才能..." 并提供 "去登录" 主按钮.
///
/// 未选择 "先逛逛" 的用户会被路由守卫直接拦截至登录页, 正常流程不会返回该结果.
final class NeedsSignIn extends PermissionResult {
  const NeedsSignIn();
}

/// 需要先认证. 拦截对话框显示 "认证后才能...", 主按钮为 "去认证".
final class NeedsVerification extends PermissionResult {
  const NeedsVerification();
}

/// 账号封禁中. 拦截对话框显示封禁原因和期限, 不提供 "去认证".
final class BlockedByBan extends PermissionResult {
  const BlockedByBan(this.status);

  final BannedStatus status;
}

/// 检查 [status] 对应的账号是否具备执行 [capability] 的权限.
PermissionResult checkPermission(AccountStatus status, Capability capability) =>
    switch (status) {
      SignedOutStatus() => const NeedsSignIn(),
      VerifiedStatus() => const Allowed(),
      UnverifiedStatus() when capability.openToUnverified => const Allowed(),
      UnverifiedStatus() => const NeedsVerification(),
      BannedStatus() when capability.openToBanned => const Allowed(),
      final BannedStatus banned => BlockedByBan(banned),
    };
