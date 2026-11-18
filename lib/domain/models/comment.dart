import 'package:eat/domain/models/paged.dart';

/// 评论列表的排序方式.
enum CommentSort {
  /// 点赞数多者优先, 相同时较新的在前.
  mostUseful('HOT'),
  newest('NEWEST');

  const new(this.api);

  final String api;
}

/// 评论的表情回应. [api] 是接口取值, [label] 是读屏和面板里的名字.
enum CommentReaction {
  thumbsUp('THUMBS_UP', '大拇指'),
  heart('HEART', '爱心'),
  laugh('LAUGH', '笑哭'),
  surprised('SURPRISED', '惊讶'),
  sad('SAD', '难过'),
  yummy('YUMMY', '好吃');

  const new(this.api, this.label);

  final String api;
  final String label;

  static CommentReaction? fromApi(String? value) {
    for (final reaction in values) {
      if (reaction.api == value) return reaction;
    }
    return null;
  }
}

/// 一种表情回应的人数. [selected] 表示当前用户选的是这一种, 游客总为 false.
class const ReactionCount({
  required final CommentReaction reaction,
  required final int count,
  final bool selected = false,
});

/// 一条公开的评论或回复.
///
/// 回复只有一层: [rootId] 为所属根评论 id, 根评论自身为 null.
/// [replyToName] 为被回复者昵称, 直接回复根评论时为 null, 界面显示形如 "回复 小林".
class const Comment({
  required final int id,
  required final int dishId,
  final int? rootId,
  required final int authorId,
  required final String authorName,
  final String? authorAvatar,

  /// 作者的等级称号, 目前只有满级有, 其余为 null.
  final String? authorTitle,
  final String? replyToName,
  final String text = '',
  final int likes = 0,

  /// 当前用户是否已点赞, 游客为 null.
  final bool? liked,

  /// 回复条数, 仅对根评论有效.
  final int replyCount = 0,
  required final DateTime createdAt,

  /// 照片地址列表, 最多 3 张. 回复不包含照片.
  final List<String> images = const [],

  /// 有人选过的表情回应, 按 [CommentReaction] 的顺序排列.
  final List<ReactionCount> reactions = const [],
}) {
  bool get isReply => rootId != null;

  Comment withReplyCount(int count) => Comment(
    id: id,
    dishId: dishId,
    rootId: rootId,
    authorId: authorId,
    authorName: authorName,
    authorAvatar: authorAvatar,
    authorTitle: authorTitle,
    replyToName: replyToName,
    text: text,
    likes: likes,
    liked: liked,
    replyCount: count,
    createdAt: createdAt,
    images: images,
    reactions: reactions,
  );
}

/// 一页评论或回复数据, 附带的 [total] 用于展示 "看全部 23 条" 和 "展开 5 条回复".
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

  /// 将根评论 [rootId] 的回复条数增减 [delta], 结果不小于 0.
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

/// 菜品大图画廊中来自评论的照片. [authorName] 为拍摄者, 即该评论作者.
class const GalleryPhoto({
  required final int commentId,
  required final String url,
  final String? authorName,
});

/// 当前用户对单条评论的点赞状态, 用作本地乐观更新的覆盖值.
class const CommentLike({required final bool liked, required final int likes});

/// "我的评论" 列表中的条目, 表示当前用户发表过的评论或回复, 已删除条目不会返回.
///
/// [rootId] 为回复所属的根评论 id, 评论自身为 null.
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
