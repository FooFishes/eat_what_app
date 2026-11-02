import 'package:eat/domain/models/paged.dart';

/// 评论列表的排序方式.
enum CommentSort {
  /// 赞多的在前, 赞数相同时新的在前.
  mostUseful('MOST_USEFUL'),
  newest('NEWEST');

  const new(this.api);

  final String api;
}

/// 评论或回复的审核状态. 只出现在 "我的评论" 中, 公开列表里的都已通过.
enum CommentStatus {
  pending,
  approved,
  rejected,

  /// 被同一条评论的新版本取代.
  superseded,

  /// 作者删除了评论, 或删除了回复所属的评论.
  deleted;

  static CommentStatus fromApi(String? value) => switch (value) {
    'APPROVED' => approved,
    'REJECTED' => rejected,
    'SUPERSEDED' => superseded,
    'DELETED' => deleted,
    _ => pending,
  };
}

/// 一条公开的评论或回复.
///
/// 回复只有一层: [rootGid] 是所属评论, [replyToGid] 是被回复的那条回复, 直接回复评论时为 null.
/// 界面按 [replyToGid] 在同一条评论的回复中查找被回复人的昵称, 显示为 "回复 小林".
class const Comment({
  required final int id,
  required final String gid,
  required final int dishId,
  final bool isReply = false,
  required final String rootGid,
  final String? replyToGid,
  required final String authorName,
  final String text = '',
  final int likes = 0,
  required final DateTime createdAt,

  /// 照片地址, 最多 3 张. 回复没有照片.
  final List<String> images = const [],
});

/// 一页评论或回复, 附带总条数. 总条数用于 "看全部 23 条" 和 "展开 5 条回复".
class const CommentPage({
  required final Paged<Comment> page,
  final int total = 0,
}) {
  const CommentPage.empty() : this(page: const Paged.empty());

  CommentPage append(CommentPage next) =>
      CommentPage(page: page.append(next.page), total: next.total);

  /// 移除 [id] 对应的条目, 总条数减一.
  CommentPage without(int id) {
    final items = [
      for (final c in page.items)
        if (c.id != id) c,
    ];
    if (items.length == page.items.length) return this;
    return CommentPage(
      page: Paged(items: items, page: page.page, hasNext: page.hasNext),
      total: total > 0 ? total - 1 : 0,
    );
  }
}

/// 菜的大图里来自评论的一张照片.
class const GalleryPhoto({
  required final int commentId,
  required final String url,
});

/// 当前用户对一条评论的赞.
class const CommentLike({required final bool liked, required final int likes});

/// "我的评论" 中的一条: 我写过的评论或回复.
///
/// [text] 在评论已删除时为空串. [reason] 是未通过审核的原因, 由服务端给出, 写给作者本人.
class const MyComment({
  required final int id,
  final bool isReply = false,
  required final int dishId,
  required final CommentStatus status,
  final String? reason,
  final String text = '',
  final int imageCount = 0,
  required final DateTime createdAt,
});

/// 发表评论或回复的结果. [pending] 为 true 时进入审核, 审核通过前不公开.
class const CommentPosted({required final int id, final bool pending = true});
