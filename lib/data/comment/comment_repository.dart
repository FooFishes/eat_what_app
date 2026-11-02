import 'package:dio/dio.dart';
import 'package:eat/data/comment/comment_api.dart';
import 'package:eat/data/comment/comment_dto.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_repository.g.dart';

/// 评论数据. 把接口 DTO 转换为 [Comment] 等领域模型. 评论不做本地缓存.
///
/// 写操作的 `Idempotency-Key` 由调用方生成并在重试时沿用, 因为只有调用方知道两次请求是否为同一份内容.
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

  /// 菜的大图里来自评论的照片, 最多 [limit] 张. 地址缺失的照片不返回.
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
        if ((dto.commentId, imageUrl(dto.image?.url)) case (
          final id?,
          final url?,
        ))
          GalleryPhoto(commentId: id, url: url),
    ];
  }

  Future<CommentPosted> create(
    int dishId, {
    required String text,
    List<String> pictureKeys = const [],
    required String idempotencyKey,
  }) async => _posted(
    await _api.create(
      dishId,
      text: text.trim(),
      pictureKeys: pictureKeys,
      idempotencyKey: idempotencyKey,
    ),
  );

  Future<CommentPosted> reply(
    int dishId,
    int commentId, {
    required String text,
    int? replyToId,
    required String idempotencyKey,
  }) async => _posted(
    await _api.reply(
      dishId,
      commentId,
      text: text.trim(),
      replyToId: replyToId,
      idempotencyKey: idempotencyKey,
    ),
  );

  Future<void> delete(int commentId, {required String idempotencyKey}) =>
      _api.delete(commentId, idempotencyKey: idempotencyKey);

  /// 赞或取消赞, 返回服务端的最新状态.
  Future<CommentLike> setLiked(
    int commentId, {
    required bool liked,
    required String idempotencyKey,
  }) async => _like(
    liked
        ? await _api.like(commentId, idempotencyKey: idempotencyKey)
        : await _api.unlike(commentId, idempotencyKey: idempotencyKey),
  );

  Future<CommentLike> likeOf(int commentId, {CancelToken? cancelToken}) async =>
      _like(await _api.likeOf(commentId, cancelToken: cancelToken));

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
              isReply: dto.kind == 'REPLY',
              dishId: dishId,
              status: CommentStatus.fromApi(dto.moderationStatus),
              reason: dto.reasonMessage,
              text: dto.text ?? '',
              imageCount: dto.imageCount ?? 0,
              createdAt: _time(dto.createdAt),
            ),
      ],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  static CommentPage _page(CountedPage<CommentDto> result) => CommentPage(
    page: Paged(
      items: [for (final dto in result.page.items) ?_comment(dto)],
      page: result.page.page,
      hasNext: result.page.hasNext,
    ),
    total: result.total,
  );

  /// 缺少 id 或全局 id 的条目无法点赞, 回复和删除, 因此不显示.
  static Comment? _comment(CommentDto dto) {
    final (id, gid) = (dto.id, dto.gid);
    if (id == null || gid == null) return null;
    final images = [...?dto.images]
      ..sort((a, b) => (a.slot ?? 0).compareTo(b.slot ?? 0));
    return Comment(
      id: id,
      gid: gid,
      dishId: dto.foodId ?? 0,
      isReply: dto.kind == 'REPLY',
      rootGid: dto.rootCommentGid ?? gid,
      replyToGid: dto.replyToGid,
      authorName: dto.authorName ?? '同学',
      text: dto.text ?? '',
      likes: dto.likesCount ?? 0,
      createdAt: _time(dto.createdAt),
      images: [for (final image in images) ?imageUrl(image.url)],
    );
  }

  static CommentPosted _posted(CommentAcceptedDto dto) => CommentPosted(
    id: dto.id ?? 0,
    pending: dto.moderationStatus != 'APPROVED',
  );

  static CommentLike _like(CommentLikeDto dto) =>
      CommentLike(liked: dto.liked ?? false, likes: dto.likesCount ?? 0);

  static DateTime _time(int? millis) =>
      dateFromMillis(millis) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

@Riverpod(keepAlive: true)
CommentRepository commentRepository(Ref ref) =>
    CommentRepository(ref.watch(commentApiProvider));
