import 'package:eat/domain/models/notice.dart';

/// 点击消息后的跳转目标.
sealed class NoticeTarget {
  const NoticeTarget();
}

final class DishTarget extends NoticeTarget {
  const DishTarget(this.dishId, {this.commentId});

  final int dishId;

  /// 菜品详情打开后滚动到的评论. 只有评论和回复消息带有.
  final int? commentId;
}

final class UserTarget extends NoticeTarget {
  const UserTarget(this.userId);

  final int userId;
}

final class ShopTarget extends NoticeTarget {
  const ShopTarget(this.shopId);

  final int shopId;
}

final class TopicTarget extends NoticeTarget {
  const TopicTarget(this.topicId);

  final int topicId;
}

/// 我的粉丝列表. 多人合并的关注消息跳到这里.
final class MyFansTarget extends NoticeTarget {
  const MyFansTarget();
}

/// 不跳转. 点击只标为已读.
final class NoTarget extends NoticeTarget {
  const NoTarget();
}

// TODO: 消息卡片不含菜名和封面, 赞, 收藏和标签消息只能写 "你上传的菜", 右侧不显示缩略图. 卡片返回菜名和封面后补上.
// TODO: 处理结果消息不含相关的店或菜, 反馈结果不能跳到相关的店或菜. 卡片返回相关对象后按对象跳转.
/// 消息的分组, 显示文字和跳转目标.
///
/// 无法识别的消息按普通消息显示, 点击后不跳转.
abstract final class NoticeRules {
  /// 消息所属的分组: "今天", "本周" 或 "更早". 本周从周一开始.
  static String groupOf(DateTime time, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (!time.isBefore(today)) return '今天';
    final week = today.subtract(Duration(days: today.weekday - 1));
    return time.isBefore(week) ? '更早' : '本周';
  }

  /// 点击后的跳转目标. 对象已删除或撤下时不跳转.
  ///
  /// 旧版活动内容 (`activity_*`) 在产品上没有页面, 也不跳转.
  static NoticeTarget targetOf(Notice notice) {
    switch (notice.kind) {
      case NoticeKind.like || NoticeKind.favorite || NoticeKind.tag:
        return _dishOrNone(notice);
      case NoticeKind.follow:
        final user = followBackUserOf(notice);
        return user == null ? const MyFansTarget() : UserTarget(user);
      case NoticeKind.comment || NoticeKind.reply:
        if (notice.detail case CommentDetail(
          :final dishId?,
          :final commentId,
          :final unavailable,
        )) {
          return unavailable
              ? const NoTarget()
              : DishTarget(dishId, commentId: commentId);
        }
        return _dishOrNone(notice);
      case NoticeKind.topicIncluded:
        if (notice.detail case TopicIncludedDetail(:final topicId?)) {
          return TopicTarget(topicId);
        }
        return const NoTarget();
      case NoticeKind.moderationResult:
        if (notice.targetUnavailable) return const NoTarget();
        return switch (notice.detail) {
          ModerationDetail(approved: true, shop: true) => ShopTarget(
            notice.targetId,
          ),
          ModerationDetail(approved: true) => DishTarget(notice.targetId),
          _ => const NoTarget(),
        };
      case NoticeKind.caseResult || NoticeKind.other:
        return const NoTarget();
    }
  }

  /// 只有一个人的关注消息可以回关, 返回对方的 id. 其余返回 null.
  static int? followBackUserOf(Notice notice) =>
      notice.kind == NoticeKind.follow &&
          notice.memberCount == 1 &&
          notice.actors.length == 1
      ? notice.actors.single.id
      : null;

  /// 正文前加粗的互动者, 如 "小林", "Momo 等 12 人". 系统消息没有互动者, 返回 null.
  static String? actorsOf(Notice notice) {
    final first = notice.actors.firstOrNull;
    if (first == null) return null;
    return notice.memberCount > 1
        ? '${first.name} 等 ${notice.memberCount} 人'
        : first.name;
  }

  /// 消息正文. 有互动者时不含互动者的名字, 名字在正文前单独加粗显示.
  static String sentenceOf(Notice notice) => switch (notice.kind) {
    NoticeKind.like => notice.targetDomain == 'foods' ? '赞了你上传的菜' : '赞了你的内容',
    NoticeKind.favorite => '收藏了你上传的菜',
    NoticeKind.tag => '给你上传的菜加了标签',
    NoticeKind.follow => '关注了你',
    NoticeKind.comment => '评论了你上传的菜',
    NoticeKind.reply => '回复了你',
    NoticeKind.topicIncluded => _topicSentence(notice.detail),
    NoticeKind.moderationResult => _moderationSentence(notice.detail),
    NoticeKind.caseResult => _caseSentence(notice.detail),
    NoticeKind.other => '你有一条新消息',
  };

  /// 处理结果中运营的公开回复. 没有回复时返回 null.
  static String? replyOf(Notice notice) => switch (notice.detail) {
    CaseResultDetail(:final reply) when reply.trim().isNotEmpty => reply.trim(),
    _ => null,
  };

  static NoticeTarget _dishOrNone(Notice notice) =>
      notice.targetDomain == 'foods' && !notice.targetUnavailable
      ? DishTarget(notice.targetId)
      : const NoTarget();

  static String _topicSentence(NoticeDetail? detail) {
    if (detail is! TopicIncludedDetail) return '你上传的菜被收进了专题';
    final dish = detail.dishId == null ? '菜' : detail.dishName;
    return detail.topicId == null
        ? '你上传的$dish被收进了专题，该专题已撤下'
        : '你上传的$dish被收进了专题「${detail.topicName}」';
  }

  static String _moderationSentence(NoticeDetail? detail) => switch (detail) {
    ModerationDetail(shop: true, approved: true) => '你新建的店已通过审核',
    ModerationDetail(shop: true) => '你新建的店未通过审核',
    ModerationDetail(approved: true) => '你上传的菜已通过审核',
    ModerationDetail() => '你上传的菜未通过审核',
    _ => '你的投稿有了审核结果',
  };

  static String _caseSentence(NoticeDetail? detail) {
    if (detail is! CaseResultDetail) return '你提交的内容有了处理结果';
    final outcome = detail.outcome;
    switch (detail.kind) {
      case CaseKind.feedback:
        return switch (outcome) {
          'ACCEPTED' => '你的反馈已被采纳',
          'RESOLVED' => '你的反馈已处理',
          'REJECTED' => '你的反馈未被采纳',
          _ => '你的反馈有了处理结果',
        };
      case CaseKind.catalogError:
        final problem = '你反馈的店铺${_catalogErrorOf(detail.reasonCode)}问题';
        return switch (outcome) {
          'ACCEPTED' => '$problem已修正',
          'REJECTED' => '$problem经核实无误',
          _ => '$problem有了处理结果',
        };
      case CaseKind.report:
        return switch (outcome) {
          'ACCEPTED' => '你举报的内容已处理',
          'REJECTED' => '你举报的内容经核实未违规',
          _ => '你的举报有了处理结果',
        };
    }
  }

  static String _catalogErrorOf(String? reasonCode) => switch (reasonCode) {
    'WRONG_NAME' => '店名',
    'WRONG_LOCATION' => '位置',
    'CLOSED' => '营业状态',
    'DUPLICATE' => '重复',
    _ => '信息',
  };
}
