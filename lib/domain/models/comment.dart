import 'package:eat/domain/models/paged.dart';

/// 评论列表的排序方式.
enum CommentSort {
  /// 赞多的在前, 赞数相同时新的在前.
  mostUseful('HOT'),
  newest('NEWEST');

  const new(this.api);

  final String api;
}

/// 一条公开的评论或回复.
///
/// 回复只有一层: [rootId] 是所属评论, 根评论为 null.
/// [replyToName] 是被回复的人, 直接回复评论时为 null, 显示为 "回复 小林".
class const Comment({
  required final int id,
  required final int dishId,
  final int? rootId,
  required final int authorId,
  required final String authorName,
  final String? authorAvatar,
  final String? replyToName,
  final String text = '',
  final int likes = 0,

  /// 当前用户是否赞过. 游客为 null.
  final bool? liked,

  /// 回复条数. 只对根评论有意义.
  final int replyCount = 0,
  required final DateTime createdAt,

  /// 照片地址, 最多 3 张. 回复没有照片.
  final List<String> images = const [],
}) {
  bool get isReply => rootId != null;

  Comment withReplyCount(int count) => Comment(
    id: id,
    dishId: dishId,
    rootId: rootId,
    authorId: authorId,
    authorName: authorName,
    authorAvatar: authorAvatar,
    replyToName: replyToName,
    text: text,
    likes: likes,
    liked: liked,
    replyCount: count,
    createdAt: createdAt,
    images: images,
  );
}

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

  /// 把根评论 [rootId] 的回复条数加上 [delta], 不小于 0.
  CommentPage withReplies(int rootId, int delta) => CommentPage(
    page: Paged(
      items: [
        for (final c in page.items)
          c.id == rootId
              ? c.withReplyCount((c.replyCount + delta).clamp(0, 1 << 31))
              : c,
      ],
      page: page.page,
      hasNext: page.hasNext,
      total: page.total,
    ),
    total: total,
  );
}

/// 菜的大图里来自评论的一张照片. [authorName] 是拍摄者, 即评论的作者.
class const GalleryPhoto({
  required final int commentId,
  required final String url,
  final String? authorName,
});

/// 当前用户对一条评论的赞. 用作赞的本地覆盖值.
class const CommentLike({required final bool liked, required final int likes});

/// "我的评论" 中的一条: 我写过的评论或回复. 已删除的不出现.
///
/// [rootId] 是回复所属的评论, 评论本身为 null.
class const MyComment({
  required final int id,
  final int? rootId,
  required final int dishId,
  final String text = '',
  final int imageCount = 0,
  required final DateTime createdAt,
}) {
  bool get isReply => rootId != null;
}

/// 发表评论或回复的结果. 评论不经审核, 发表后立即公开.
class const CommentPosted({required final int id});
