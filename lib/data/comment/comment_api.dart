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
  static const my = '/comments/my';
}

/// 接口分组 Comment: 评论和回复的列表, 发表, 删除, 赞, 我的评论, 菜的图库.
///
/// 评论不经审核, 发表后立即公开. 评论不存在时服务端返回 10001.
class CommentApi {
  CommentApi(this._client);

  final ApiClient _client;

  /// 一道菜的根评论, 不含回复. [sort] 为 `HOT` 或 `NEWEST`.
  ///
  /// 当前用户屏蔽的人写的评论不返回.
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

  /// 一条根评论下的回复, 按时间正序.
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

  /// 菜的图库中来自根评论的照片, 新的在前. 上传者的照片不在其中.
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

  /// 发表评论, 返回新评论的 id. [pictureKeys] 是 `biz=comments` 上传完成的存储 key, 最多 3 个.
  Future<int> create(
    int foodId, {
    required String text,
    List<String> pictureKeys = const [],
  }) async => decodeCreatedId(
    await _client.post(
      CommentEndpoints.foodComments(foodId),
      body: {'text': text, 'pictureKeys': pictureKeys},
    ),
  );

  /// 回复根评论 [commentId], 返回新回复的 id.
  ///
  /// [replyToId] 是被回复的那条回复, 直接回复根评论时为 null.
  /// 被根评论的作者或被回复的人屏蔽时返回 40002.
  Future<int> reply(
    int foodId,
    int commentId, {
    required String text,
    int? replyToId,
  }) async => decodeCreatedId(
    await _client.post(
      CommentEndpoints.replyToComment(foodId, commentId),
      body: {'text': text, 'replyToId': ?replyToId},
    ),
  );

  /// 删除自己的评论或回复. 删除评论时下面的回复一起删除.
  Future<void> delete(int commentId) =>
      _client.delete(CommentEndpoints.comment(commentId));

  Future<void> like(int commentId) =>
      _client.put(CommentEndpoints.like(commentId));

  Future<void> unlike(int commentId) =>
      _client.delete(CommentEndpoints.like(commentId));

  /// 我写过的评论和回复, 按时间倒序. 已删除的不返回.
  Future<Paged<CommentDto>> mine({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      CommentEndpoints.my,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    CommentDto.fromJson,
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
