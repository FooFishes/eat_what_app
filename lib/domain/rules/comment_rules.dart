import 'package:eat/domain/models/comment.dart';

/// 评论和回复的规则: 字数, 照片数, 能否发送, 回复的显示顺序.
abstract final class CommentRules {
  /// 文字上限, 按 Unicode 码点计. 服务端先去掉首尾空白再计数.
  static const textMax = 200;

  /// 一条评论最多的照片数. 回复不能带照片.
  static const photoMax = 3;

  /// 菜品详情里露出的评论条数.
  static const dishPreview = 3;

  /// 评论下面默认露出的回复条数, 其余收起在 "展开 N 条回复" 里.
  static const replyPreview = 2;

  /// 去掉首尾空白后的字数.
  static int length(String text) => text.trim().runes.length;

  /// 能否发送. 评论至少包含文字或照片. 回复只能包含文字, 且文字不能为空.
  static bool canSend(String text, {int photos = 0, bool reply = false}) {
    final length = CommentRules.length(text);
    if (length > textMax) return false;
    if (reply) return length > 0 && photos == 0;
    return photos <= photoMax && (length > 0 || photos > 0);
  }

  /// 按发表时间从早到晚排列的回复.
  ///
  /// 回复接口按时间倒序返回. 产品要求先露出最早的回复, 因此在客户端重新排序.
  static List<Comment> chronological(List<Comment> replies) =>
      [...replies]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// [reply] 回复的那条回复的作者. 直接回复评论, 或被回复的那条不在 [siblings] 中时为 null.
  static String? replyToName(Comment reply, List<Comment> siblings) {
    final target = reply.replyToGid;
    if (target == null || target == reply.rootGid) return null;
    for (final c in siblings) {
      if (c.gid == target) return c.authorName;
    }
    return null;
  }
}
