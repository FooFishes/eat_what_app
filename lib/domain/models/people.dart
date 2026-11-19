/// 用户的公开资料和统计, 来自 `/user/userInfo`. 他人主页和 "我的" 共用.
///
/// - [fans] 和 [followings] 在对方未公开对应列表时为 null, 查看自己时总有值.
/// - [fansVisible] 和 [followingsVisible] 是对方的隐私设置. 查看自己时即为自己的设置.
/// - [followsMe] 和 [followedByMe] 是对方与当前用户之间的关注关系.
/// - [blocked] 表示当前用户屏蔽了对方.
class const UserProfile({
  required final int id,
  required final String nickname,
  final String? avatarUrl,
  final String? signature,

  /// 用户等级, 取值 1 到 10, 服务端未返回时为 null.
  final int? level,

  /// 等级称号, 目前只有满级有, 其余为 null.
  final String? title,

  /// 累计获赞数, 包括上传菜品, 评论及回复收到的点赞.
  final int? earnedLikes,
  final int? fans,
  final int? followings,
  final bool fansVisible = true,
  final bool followingsVisible = true,
  final bool followsMe = false,
  final bool followedByMe = false,
  final bool blocked = false,
});

/// 用户列表中的精简条目, 用于粉丝, 关注及屏蔽列表.
///
/// [since] 为关注或屏蔽时间. 若被屏蔽账号已注销, 则 [nickname] 为 null.
class const UserBrief({
  required final int id,
  final String? nickname,
  final String? avatarUrl,

  /// 等级称号, 目前只有满级有, 其余为 null. 屏蔽列表不带.
  final String? title,
  final DateTime? since,

  /// 对方与当前登录用户之间的关注关系. 只有粉丝和关注列表带, 屏蔽列表恒为 false.
  final bool followsMe = false,
  final bool followedByMe = false,
});

/// 当前用户与另一个用户的关注关系. [label] 是关注按钮上的文字.
enum FollowState {
  none('关注'),

  /// 对方已关注当前用户, 但当前用户尚未关注对方.
  followsMe('回关'),
  following('已关注'),
  mutual('已互关');

  const new(this.label);

  final String label;

  static FollowState of({
    required bool followedByMe,
    required bool followsMe,
  }) => switch ((followedByMe, followsMe)) {
    (true, true) => mutual,
    (true, false) => following,
    (false, true) => FollowState.followsMe,
    (false, false) => none,
  };

  /// 当前用户是否已关注对方. 为 true 时按钮采用次要样式, 点击可取消关注.
  bool get followedByMe => this == following || this == mutual;
}

/// 足迹的两个分栏.
enum FootprintKind {
  dish('food'),
  shop('restaurant');

  const new(this.api);

  final String api;
}

/// 单条浏览足迹, 记录最近查看的菜品或店铺, 同一对象仅保留最近一次记录.
///
/// [likes] 仅菜品有值.
class const Footprint({
  required final FootprintKind kind,
  required final int id,
  required final String name,
  final String? image,
  final int? likes,
  required final DateTime viewedAt,
});

/// 用户隐私设置, 控制他人的可见范围, 两项默认均为公开.
class const PrivacySettings({
  final bool followingsPublic = true,
  final bool fansPublic = true,
});
