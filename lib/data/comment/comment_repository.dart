import 'package:dio/dio.dart';
import 'package:eat/data/comment/comment_api.dart';
import 'package:eat/data/comment/comment_dto.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_repository.g.dart';

/// 提供评论与回复的数据访问, 负责将接口 DTO 转换为 [Comment] 等领域模型. 评论不做本地缓存.
class CommentRepository {
  CommentRepository(this._api);

  final CommentApi _api;

  Future<CommentPage> comments(
    int dishId, {
    required CommentSort sort,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.comments(
      dishId,
      sort: sort.api,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 获取指定评论下的回复列表, 按时间正序排列.
  Future<CommentPage> replies(
    int commentId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => _page(
    await _api.replies(
      commentId,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    ),
  );

  /// 获取菜品图库中来自评论的照片, 最多 [limit] 张, 并过滤掉地址缺失的条目.
  Future<List<GalleryPhoto>> gallery(
    int dishId, {
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final page = await _api.gallery(
      dishId,
      pageSize: limit,
      cancelToken: cancelToken,
    );
    return [
      for (final dto in page.items)
        if ((dto.commentId, imageUrl(dto.url)) case (final id?, final url?))
          GalleryPhoto(
            commentId: id,
            url: url,
            authorName: dto.author?.displayName,
          ),
    ];
  }

  Future<CommentPosted> create(
    int dishId, {
    required String text,
    List<String> pictureKeys = const [],
  }) async => CommentPosted(
    id: await _api.create(dishId, text: text.trim(), pictureKeys: pictureKeys),
  );

  Future<CommentPosted> reply(
    int dishId,
    int commentId, {
    required String text,
    int? replyToId,
  }) async => CommentPosted(
    id: await _api.reply(
      dishId,
      commentId,
      text: text.trim(),
      replyToId: replyToId,
    ),
  );

  Future<void> delete(int commentId) => _api.delete(commentId);

  /// 点赞或取消点赞. 由于接口不返回最新赞数, 调用方需自行维护计数.
  Future<void> setLiked(int commentId, {required bool liked}) =>
      liked ? _api.like(commentId) : _api.unlike(commentId);

  Future<Paged<MyComment>> mine({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.mine(
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
    return Paged(
      items: [
        for (final dto in result.items)
          if ((dto.id, dto.foodId) case (final id?, final dishId?))
            MyComment(
              id: id,
              rootId: dto.rootId,
              dishId: dishId,
              text: dto.text ?? '',
              imageCount: dto.pictureUrls?.length ?? 0,
              createdAt: _time(dto.createdAt),
            ),
      ],
      page: result.page,
      hasNext: result.hasNext,
      total: result.total,
    );
  }

  static CommentPage _page(CountedPage<CommentDto> result) => CommentPage(
    page: Paged(
      items: [for (final dto in result.page.items) ?_comment(dto)],
      page: result.page.page,
      hasNext: result.page.hasNext,
      total: result.page.total,
    ),
    total: result.total,
  );

  /// 缺少 id, 菜品 id 或作者 id 的条目无法执行点赞, 回复及删除权限判断, 因此予以过滤.
  static Comment? _comment(CommentDto dto) {
    final (id, dishId, authorId) = (dto.id, dto.foodId, dto.author?.id);
    if (id == null || dishId == null || authorId == null) return null;
    return Comment(
      id: id,
      dishId: dishId,
      rootId: dto.rootId,
      authorId: authorId,
      authorName: _name(dto.author?.displayName),
      authorAvatar: imageUrl(dto.author?.avatar),
      authorTitle: switch (dto.author?.title?.trim()) {
        final title? when title.isNotEmpty => title,
        _ => null,
      },
      replyToName: switch (dto.replyTo?.displayName) {
        final name? when name.isNotEmpty => name,
        _ => null,
      },
      text: dto.text ?? '',
      likes: dto.likeCount ?? 0,
      liked: dto.isLiked,
      replyCount: dto.replyCount ?? 0,
      createdAt: _time(dto.createdAt),
      images: [for (final url in dto.pictureUrls ?? const []) ?imageUrl(url)],
    );
  }

  static String _name(String? value) =>
      value == null || value.isEmpty ? '同学' : value;

  static DateTime _time(int? millis) =>
      dateFromMillis(millis) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

@Riverpod(keepAlive: true)
CommentRepository commentRepository(Ref ref) =>
    CommentRepository(ref.watch(commentApiProvider));
