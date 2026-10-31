/// 消息页的一条消息，来自 `/notification/list`。
///
/// [type]、[targetType] 的取值接口还没写全（现状差距 2.1），原样保留，由 `noticeTargetOf`
/// 和页面按已知的几种处理。
class const Notice({
  required final int id,
  required final int actorId,
  required final String actorName,
  final String? actorAvatar,
  required final String type,
  required final String targetType,
  required final int targetId,
  final Map<String, Object?> data = const {},
  final bool read = false,
  required final DateTime createdAt,
});

/// 一个用户对外的资料和统计，来自 `/user/userInfo`。
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
