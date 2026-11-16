import 'package:eat/domain/models/notice.dart';

/// 点击消息后的跳转目标.
sealed class NoticeTarget {
  const NoticeTarget();
}

final class DishTarget extends NoticeTarget {
  const DishTarget(this.dishId);

  final int dishId;
}

final class UserTarget extends NoticeTarget {
  const UserTarget(this.userId);

  final int userId;
}

final class ShopTarget extends NoticeTarget {
  const ShopTarget(this.shopId);

  final int shopId;
}

/// 处理结果消息的目标: 我的反馈中这条提交记录的详情页.
final class CaseTarget extends NoticeTarget {
  const CaseTarget(this.caseId);

  final int caseId;
}

/// 设置页中的登录设备列表, 新设备登录通知点击后跳转至此.
final class DevicesTarget extends NoticeTarget {
  const DevicesTarget();
}

/// 当前用户的粉丝列表, 多人合并的关注通知点击后跳转至此.
final class MyFansTarget extends NoticeTarget {
  const MyFansTarget();
}

/// 无跳转目标, 点击后仅将该消息标记为已读.
final class NoTarget extends NoticeTarget {
  const NoTarget();
}

// TODO: 消息卡片暂不含菜名和封面, 赞, 收藏和评论消息只能显示为 "你上传的菜" 且右侧无缩略图. 卡片返回菜名和封面后补齐文案与缩略图.
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

  /// 解析点击消息后的跳转目标.
  ///
  /// 即使目标对象已删除仍执行跳转, 由目标页面负责展示已删除提示.
  static NoticeTarget targetOf(Notice notice) {
    switch (notice.kind) {
      case NoticeKind.like || NoticeKind.favorite || NoticeKind.comment:
        return notice.targetDomain == 'foods'
            ? DishTarget(notice.targetId)
            : const NoTarget();
      case NoticeKind.follow:
        final user = followBackUserOf(notice);
        return user == null ? const MyFansTarget() : UserTarget(user);
      case NoticeKind.caseResult:
        if (notice.detail case CaseResultDetail(:final caseId?)) {
          return CaseTarget(caseId);
        }
        return const NoTarget();
      // TODO: 回复和评论赞的卡片只带评论 id, 不带菜 id, 后端也没有按 id 读取评论的接口, 因此无法跳到菜品详情. 卡片带上菜 id 后跳到菜品详情并滚动到该评论.
      case NoticeKind.reply || NoticeKind.commentLike:
        return const NoTarget();
      case NoticeKind.newDeviceLogin:
        return const DevicesTarget();
      case NoticeKind.announcement ||
          NoticeKind.accountBanned ||
          NoticeKind.contentRemoved ||
          NoticeKind.other:
        return const NoTarget();
    }
  }

  /// 仅单人关注消息支持快捷回关并直接返回对方 id, 多人合并或非关注消息返回 null.
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

  /// 生成消息正文. 存在互动者时正文不含其昵称 (昵称在正文前单独加粗显示), 公告类消息的正文即为其标题.
  static String sentenceOf(Notice notice) => switch (notice.kind) {
    NoticeKind.like => '赞了你上传的菜',
    NoticeKind.favorite => '收藏了你上传的菜',
    NoticeKind.follow => '关注了你',
    NoticeKind.comment => '评论了你上传的菜',
    NoticeKind.reply => '回复了你',
    NoticeKind.commentLike => '赞了你的评论',
    NoticeKind.caseResult => _caseSentence(notice.detail),
    NoticeKind.announcement => switch (notice.detail) {
      AnnouncementDetail(:final title) when title.trim().isNotEmpty =>
        title.trim(),
      _ => '系统公告',
    },
    NoticeKind.accountBanned => '你的账号已被封禁',
    NoticeKind.newDeviceLogin => '你的账号已在新设备上登录',
    NoticeKind.contentRemoved => switch (notice.detail) {
      ContentRemovedDetail(comment: true, :final title) when title.isNotEmpty =>
        '你的评论「$title」已被删除',
      ContentRemovedDetail(comment: true) => '你的一条评论已被删除',
      ContentRemovedDetail(:final title) when title.isNotEmpty =>
        '你上传的「$title」已被删除',
      _ => '你上传的一道菜已被删除',
    },
    NoticeKind.other => '你有一条新消息',
  };

  /// 处理结果中运营的公开回复. 没有回复时返回 null.
  static String? replyOf(Notice notice) => switch (notice.detail) {
    CaseResultDetail(:final reply) when reply.trim().isNotEmpty => reply.trim(),
    _ => null,
  };

  /// 生成正文下方的补充说明 (包含公告内容, 封禁或删除原因, 新设备名称), 无补充信息时返回 null.
  ///
  /// 封禁期限需结合当前日期格式化, 由页面另起一行单独展示.
  static String? contentOf(Notice notice) => switch (notice.detail) {
    AnnouncementDetail(:final content) when content.trim().isNotEmpty =>
      content.trim(),
    BanDetail(:final reason?) ||
    ContentRemovedDetail(:final reason?) => '原因：$reason',
    NewDeviceDetail(:final deviceName, :final platform) =>
      '${deviceName ?? _platformOf(platform)}，不是你本人登录时，可以在登录设备里让它下线',
    _ => null,
  };

  static String _platformOf(String? platform) => switch (platform) {
    'IOS' => 'iPhone',
    'ANDROID' => '安卓设备',
    'WEB' => '网页版',
    _ => '其他设备',
  };

  static String _caseSentence(NoticeDetail? detail) {
    if (detail is! CaseResultDetail) return '你提交的内容已处理';
    final outcome = detail.outcome;
    switch (detail.kind) {
      case CaseKind.feedback:
        return switch (outcome) {
          'ACCEPTED' => '你的反馈已被采纳',
          'RESOLVED' => '你的反馈已处理',
          'REJECTED' => '你的反馈未被采纳',
          _ => '你的反馈已处理',
        };
      case CaseKind.catalogError:
        final problem = '你反馈的店铺${_catalogErrorOf(detail.reasonCode)}问题';
        return switch (outcome) {
          'ACCEPTED' => '$problem已修正',
          'REJECTED' => '$problem经核实无误',
          _ => '$problem已处理',
        };
      case CaseKind.report:
        return switch (outcome) {
          'ACCEPTED' => '你举报的内容已处理',
          'REJECTED' => '你举报的内容经核实未违规',
          _ => '你的举报已处理',
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
