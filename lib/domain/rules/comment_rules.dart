/// 评论与回复的业务规则, 包含字数限制, 照片上限与发送条件校验.
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
}
