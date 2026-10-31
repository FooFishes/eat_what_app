import 'package:eat/domain/models/notice.dart';

/// 点一条消息去哪（产品 10.2）。
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

/// 不跳转，只算读过。
final class NoTarget extends NoticeTarget {
  const NoTarget();
}

/// 消息怎么显示、点了去哪。
///
/// 接口只举了 `follow`、`like` 两种 `type`，`targetType` 写了 `user`、`post`、`food`
/// （现状差距 2.1）；认不出的按「全部」里的一条普通消息显示，点了不跳转。
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

  /// 一句话，不带对方的名字（名字单独加粗显示在前面）。
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
