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

  /// 赞了我的评论或回复.
  commentLike('comment_like'),
  caseResult('case_result'),
  announcement('announcement'),

  /// 客户端不认识的类型. 显示为普通消息, 不跳转.
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

/// 消息里的一个互动者. 系统消息没有互动者.
class const NoticeActor({
  required final int id,
  required final String name,
  final String? avatar,
});

/// 消息页的一行, 来自 `/notification/cards`.
///
/// 同一对象, 同一类互动在同一天的消息由服务端合并为一行.
/// - [memberCount] 是合并的条数. [actors] 是其中最近的至多 3 人, 最近的在前.
/// - [targetDomain] 原样保留接口取值, 如 `foods`, `users`, `comments`, 由 `NoticeRules` 识别.
/// - [read] 表示合并的各条都已读.
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

/// 反馈, 信息有误和举报的处理结果.
final class CaseResultDetail extends NoticeDetail {
  const CaseResultDetail({
    this.caseId,
    required this.kind,
    this.outcome,
    this.reasonCode,
    this.reply = '',
  });

  /// 提交记录的 id. 用于获取记录关于的菜或店.
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

/// 运营发布的公告. 只显示, 不跳转.
final class AnnouncementDetail extends NoticeDetail {
  const AnnouncementDetail({required this.title, this.content = ''});

  final String title;
  final String content;
}
