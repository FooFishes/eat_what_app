import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/comment/comment_dto.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_api.g.dart';

/// 一页接口数据和 `PageResult.totalItems`.
typedef CountedPage<T> = ({Paged<T> page, int total});

/// CommentApi 调用的接口路径, 相对于业务接口地址.
abstract final class CommentEndpoints {
  static String replyToComment(int foodId, int commentId) =>
      '/foods/$foodId/comments/$commentId/replies';
  static String foodComments(int foodId) => '/foods/$foodId/comments';
  static String replies(int commentId) => '/comments/$commentId/replies';
  static String foodGallery(int foodId) => '/foods/$foodId/gallery';
  static String like(int commentId) => '/comments/$commentId/like';
  static String comment(int commentId) => '/comments/$commentId';
  static const mySubmissions = '/comments/submissions/my';
}

/// 接口分组 Comment: 评论和回复的列表, 发表, 删除, 赞, 我的评论, 菜的图库.
///
/// 写操作都要求 `Idempotency-Key` 请求头, 值为 UUID.
/// 服务端对同一个键只受理一次, 并拒绝同一个键对应不同正文的请求.
/// 因此网络失败后的重试沿用原键, 内容变化后换用新键.
class CommentApi {
  CommentApi(this._client);

  final ApiClient _client;

  /// 一道菜的评论, 不含回复. [sort] 为 `MOST_USEFUL` 或 `NEWEST`.
  Future<CountedPage<CommentDto>> comments(
    int foodId, {
    required String sort,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => _counted(
    await _client.get(
      CommentEndpoints.foodComments(foodId),
      query: {'sort': sort, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    CommentDto.fromJson,
  );

  /// 一条评论下的回复, 按时间倒序.
  Future<CountedPage<CommentDto>> replies(
    int commentId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => _counted(
    await _client.get(
      CommentEndpoints.replies(commentId),
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    CommentDto.fromJson,
  );

  /// 菜的图库中来自评论的照片, 按评论时间倒序. 上传者的照片不在其中.
  Future<Paged<GalleryImageDto>> gallery(
    int foodId, {
    int page = 1,
    int pageSize = 50,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      CommentEndpoints.foodGallery(foodId),
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    GalleryImageDto.fromJson,
  );

  /// 发表评论. [pictureKeys] 是 `biz=comments` 上传完成的存储 key, 最多 3 个.
  ///
  /// 不传 `campusId`: 服务端按菜所属的校区推导, 传错会被拒绝.
  Future<CommentAcceptedDto> create(
    int foodId, {
    required String text,
    List<String> pictureKeys = const [],
    required String idempotencyKey,
  }) async => decodeJson(
    await _client.post(
      CommentEndpoints.foodComments(foodId),
      body: {'text': text, 'pictureKeys': pictureKeys},
      headers: {'Idempotency-Key': idempotencyKey},
    ),
    CommentAcceptedDto.fromJson,
  );

  /// 回复评论 [commentId]. [replyToId] 是被回复的那条回复, 直接回复评论时为 null.
  Future<CommentAcceptedDto> reply(
    int foodId,
    int commentId, {
    required String text,
    int? replyToId,
    required String idempotencyKey,
  }) async => decodeJson(
    await _client.post(
      CommentEndpoints.replyToComment(foodId, commentId),
      body: {'text': text, 'replyToId': ?replyToId},
      headers: {'Idempotency-Key': idempotencyKey},
    ),
    CommentAcceptedDto.fromJson,
  );

  /// 删除自己的评论或回复. 删除评论时下面的回复一起删除.
  Future<void> delete(int commentId, {required String idempotencyKey}) =>
      _client.delete(
        CommentEndpoints.comment(commentId),
        headers: {'Idempotency-Key': idempotencyKey},
      );

  Future<CommentLikeDto> like(
    int commentId, {
    required String idempotencyKey,
  }) async => decodeJson(
    await _client.put(
      CommentEndpoints.like(commentId),
      headers: {'Idempotency-Key': idempotencyKey},
    ),
    CommentLikeDto.fromJson,
  );

  Future<CommentLikeDto> unlike(
    int commentId, {
    required String idempotencyKey,
  }) async => decodeJson(
    await _client.delete(
      CommentEndpoints.like(commentId),
      headers: {'Idempotency-Key': idempotencyKey},
    ),
    CommentLikeDto.fromJson,
  );

  /// 当前用户是否赞过评论 [commentId], 以及该评论的赞数. 受限会话不能调用.
  Future<CommentLikeDto> likeOf(
    int commentId, {
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      CommentEndpoints.like(commentId),
      cancelToken: cancelToken,
    ),
    CommentLikeDto.fromJson,
  );

  /// 我写过的评论和回复, 含审核中, 未通过和已删除的, 按时间倒序. 受限会话可以调用.
  Future<Paged<CommentSubmissionDto>> mine({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      CommentEndpoints.mySubmissions,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    CommentSubmissionDto.fromJson,
  );

  static CountedPage<T> _counted<T>(
    Object? data,
    T Function(Map<String, dynamic> json) item,
  ) {
    final total = data is Map ? data['totalItems'] : null;
    return (
      page: decodePage(data, item),
      total: total is num ? total.toInt() : 0,
    );
  }
}

@Riverpod(keepAlive: true)
CommentApi commentApi(Ref ref) => CommentApi(ref.watch(apiClientProvider));
