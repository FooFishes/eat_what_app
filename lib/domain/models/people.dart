/// 用户的公开资料和统计, 来自 `/user/userInfo`. 他人主页和 "我的" 共用.
///
/// - [fansVisible] 和 [followingsVisible] 是对方的隐私设置. 查看自己时即为自己的设置.
/// - [followsMe] 和 [followedByMe] 是对方与当前用户之间的关注关系.
class const UserProfile({
  required final int id,
  required final String nickname,
  final String? avatarUrl,
  final int earnedLikes = 0,
  final int fans = 0,
  final int followings = 0,
  final int uploadedDishes = 0,
  final bool fansVisible = true,
  final bool followingsVisible = true,
  final bool followsMe = false,
  final bool followedByMe = false,
});

/// 列表中的一个用户: 粉丝和关注列表, 屏蔽的人.
///
/// [since] 是关注或屏蔽的时间. 屏蔽的账号已注销时 [nickname] 为 null.
class const UserBrief({
  required final int id,
  final String? nickname,
  final String? avatarUrl,
  final DateTime? since,
});

/// 当前用户与另一个用户的关注关系. [label] 是关注按钮上的文字.
enum FollowState {
  none('关注'),

  /// 对方关注了我, 我没有关注对方.
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

  /// 我是否关注了对方. 为 true 时按钮是次要样式, 点击取消关注.
  bool get followedByMe => this == following || this == mutual;
}

/// 足迹的两个分栏.
enum FootprintKind {
  dish('food'),
  shop('restaurant');

  const new(this.api);

  final String api;
}

/// 足迹中的一条: 最近看过的一道菜或一家店. 同一对象只保留最近一次.
///
/// [likes] 只有菜有.
class const Footprint({
  required final FootprintKind kind,
  required final int id,
  required final String name,
  final String? image,
  final int? likes,
  required final DateTime viewedAt,
});

/// 隐私设置中别人能看到什么. 两项默认都公开.
class const PrivacySettings({
  final bool followingsPublic = true,
  final bool fansPublic = true,
});

/// 一次换绑手机. [oldProofRequired] 为 true 时提交前要用旧手机验证码或密码确认身份.
class const MobileChange({
  required final String commandId,
  required final String mobile,
  required final bool oldProofRequired,
});
