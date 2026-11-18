import 'package:eat/domain/models/comment.dart';

/// 评论与回复的业务规则, 包含字数限制, 照片上限, 发送条件校验和表情回应的计数.
abstract final class CommentRules {
  /// 文字上限, 按 Unicode 码点计. 服务端先去掉首尾空白再计数.
  static const textMax = 200;

  /// 单条评论允许上传的最大照片数量, 回复不可附带照片.
  static const photoMax = 3;

  /// 菜品详情页默认展示的评论条数.
  static const dishPreview = 3;

  /// 评论下方默认展示的回复条数, 超出部分折叠在 "展开 N 条回复" 中.
  static const replyPreview = 2;

  /// 去除首尾空白字符后的有效字数 (按 Unicode 码点计).
  static int length(String text) => text.trim().runes.length;

  /// 判断是否满足发送条件. 评论需至少包含文字或照片, 回复则仅限非空文字.
  static bool canSend(String text, {int photos = 0, bool reply = false}) {
    final length = CommentRules.length(text);
    if (length > textMax) return false;
    if (reply) return length > 0 && photos == 0;
    return photos <= photoMax && (length > 0 || photos > 0);
  }

  /// 当前用户点了 [reaction] 之后的回应列表.
  ///
  /// 每人对一条评论只留一种回应: 点自己已选的那种是取消, 点别的是换成它, 原来那种少一人.
  /// 人数为 0 的不留, 结果按 [CommentReaction] 的顺序排列.
  static List<ReactionCount> toggleReaction(
    List<ReactionCount> current,
    CommentReaction reaction,
  ) {
    final selecting = !current.any((r) => r.reaction == reaction && r.selected);
    final counts = {
      for (final r in current) r.reaction: r.selected ? r.count - 1 : r.count,
    };
    if (selecting) counts[reaction] = (counts[reaction] ?? 0) + 1;
    return [
      for (final r in CommentReaction.values)
        if ((counts[r] ?? 0) > 0)
          ReactionCount(
            reaction: r,
            count: counts[r]!,
            selected: selecting && r == reaction,
          ),
    ];
  }
}
