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

final class MeTarget extends NoticeTarget {
  const MeTarget();
}

/// 不跳转, 只标记为已读.
final class NoTarget extends NoticeTarget {
  const NoTarget();
}

// TODO: 接口只列出 `follow` 和 `like` 两种 `type`, 以及 `user`, `post`, `food` 三种 `targetType`, 其余取值按推测处理. 后端给出完整取值表后按表补齐, 并删除推测的分支.
/// 消息的显示文字和跳转目标.
///
/// 无法识别的消息按普通消息显示在 "全部" 中, 点击后不跳转.
abstract final class NoticeRules {
  static NoticeTarget targetOf(Notice notice) {
    final type = notice.type.toLowerCase();
    if (type == 'follow') return UserTarget(notice.actorId);
    if (type == 'verify' || type == 'verified') return const MeTarget();
    return switch (notice.targetType.toLowerCase()) {
      'food' || 'dish' => DishTarget(notice.targetId),
      'user' => UserTarget(notice.targetId),
      _ => const NoTarget(),
    };
  }

  /// 消息正文, 不含对方的名字. 名字在正文前单独加粗显示.
  static String sentenceOf(Notice notice) {
    final dish = notice.data['foodName'] ?? notice.data['name'];
    final dishPart = dish is String && dish.isNotEmpty ? '你上传的$dish' : '你上传的菜';
    return switch (notice.type.toLowerCase()) {
      'follow' => '关注了你',
      'like' => '赞了$dishPart',
      'favorite' => '收藏了$dishPart',
      'tag' => '给$dishPart加了标签',
      'comment' => '评论了$dishPart',
      'reply' => '回复了你',
      _ => '和你有了新的互动',
    };
  }
}
