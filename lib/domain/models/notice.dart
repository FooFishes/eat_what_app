/// 消息页的分栏. [api] 是接口参数 `column` 的取值.
enum NoticeColumn {
  all('ALL', '全部'),
  comments('COMMENTS', '评论'),
  likes('LIKES_AND_FAVORITES', '赞和收藏'),
  follows('FOLLOWS', '关注'),
  system('SYSTEM', '系统');

  const new(this.api, this.label);

  final String api;
  final String label;
}

/// 消息的类型. [api] 是消息卡片 `kind` 的取值.
enum NoticeKind {
  like('like'),
  favorite('favorite'),
  follow('follow'),
  comment('comment'),
  reply('reply'),

  /// 当前用户的评论或回复收到点赞.
  commentLike('comment_like'),
  caseResult('case_result'),
  announcement('announcement'),

  /// 账号被封禁通知, 包含封禁原因与期限.
  accountBanned('account_banned'),

  /// 账号在新设备登录通知, 点击可跳转至登录设备列表执行下线操作.
  newDeviceLogin('new_device_login'),

  /// 管理员删除了当前用户发布的菜品, 评论或回复.
  contentRemoved('content_removed'),

  /// 客户端未识别的消息类型, 按普通消息展示且不可跳转.
  other('');

  const new(this.api);

  final String api;

  static NoticeKind fromApi(String? value) {
    for (final kind in values) {
      if (kind != other && kind.api == value) return kind;
    }
    return other;
  }
}

/// 消息中的互动者信息, 系统消息不包含互动者.
class const NoticeActor({
  required final int id,
  required final String name,
  final String? avatar,
});

/// 消息列表的一行卡片数据, 来自 `/notification/cards`.
///
/// 同一对象, 同一类互动在同一天的消息由服务端合并为一行.
/// - [memberCount] 为合并的消息条数, [actors] 为其中最近的至多 3 位互动者 (按时间倒序).
/// - [targetDomain] 原样保留接口取值, 如 `foods`, `users`, `comments`, 由 `NoticeRules` 识别.
/// - [read] 表示该合并组内的所有消息均已读.
class const Notice({
  required final int id,
  required final NoticeKind kind,
  required final String targetDomain,
  required final int targetId,
  final int memberCount = 1,
  final bool read = false,
  required final DateTime latestAt,
  final List<NoticeActor> actors = const [],
  final NoticeDetail? detail,
}) {
  Notice markedRead() => Notice(
    id: id,
    kind: kind,
    targetDomain: targetDomain,
    targetId: targetId,
    memberCount: memberCount,
    read: true,
    latestAt: latestAt,
    actors: actors,
    detail: detail,
  );
}

/// 系统消息附带的内容. 互动消息没有附带内容.
sealed class NoticeDetail {
  const NoticeDetail();
}

/// 反馈, 信息有误或举报的处理结果详情.
final class CaseResultDetail extends NoticeDetail {
  const CaseResultDetail({
    this.caseId,
    required this.kind,
    this.outcome,
    this.reasonCode,
    this.reply = '',
  });

  /// 提交记录 id, 用于查询该记录关联的菜品或店铺.
  final int? caseId;
  final CaseKind kind;

  /// `ACCEPTED`, `REJECTED` 或 `RESOLVED`. `RESOLVED` 只用于意见反馈.
  final String? outcome;

  /// 信息有误的错误类型或举报原因. 意见反馈为 null.
  final String? reasonCode;

  /// 运营的公开回复. 没有回复时为空串.
  final String reply;
}

/// 处理结果对应的提交类型.
enum CaseKind { feedback, catalogError, report }

/// 封禁消息的原因和期限.
final class BanDetail extends NoticeDetail {
  const BanDetail({this.reason, this.until});

  final String? reason;

  /// 封禁截止时间, 为 null 时表示永久封禁.
  final DateTime? until;
}

/// 新设备登录消息附带的设备信息. [deviceName] 为设备上报名或服务端推断的名称 (如 "Pixel 8"), 可能为 null.
final class NewDeviceDetail extends NoticeDetail {
  const NewDeviceDetail({this.deviceName, this.platform});

  final String? deviceName;

  /// 设备类型: `WEB`, `IOS`, `ANDROID` 或 `UNKNOWN`.
  final String? platform;
}

/// 被删除内容的信息, [title] 为菜名或评论正文的前 20 个字.
final class ContentRemovedDetail extends NoticeDetail {
  const ContentRemovedDetail({
    required this.comment,
    this.title = '',
    this.reason,
  });

  /// 为 true 时表示评论或回复, 否则表示菜品.
  final bool comment;
  final String title;
  final String? reason;
}

/// 运营发布的系统公告, 仅作展示, 不可跳转.
final class AnnouncementDetail extends NoticeDetail {
  const AnnouncementDetail({required this.title, this.content = ''});

  final String title;
  final String content;
}
