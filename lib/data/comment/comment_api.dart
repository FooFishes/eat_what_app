import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/comment/comment_dto.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_api.g.dart';

/// 封装分页数据及其总数 (`PageResult.totalItems`).
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

/// 封装 Comment 分组接口, 提供评论与回复的列表查询, 发表, 删除, 点赞, 我的评论及菜品图库等能力.
///
/// 评论无需审核, 发表后立即公开; 若目标评论不存在, 服务端返回业务码 10001.
class CommentApi {
  CommentApi(this._client);

  final ApiClient _client;

  /// 获取菜品的根评论列表 (不含回复), [sort] 取值为 `HOT` 或 `NEWEST`.
  ///
  /// 已被当前用户屏蔽的用户所发表的评论不会返回.
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

  /// 获取指定根评论下的回复列表, 按时间正序排列.
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

  /// 获取菜品图库中来自根评论的照片, 按时间倒序排列, 不包含菜品上传者的照片.
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

  /// 发表评论并返回新评论 id. [pictureKeys] 为使用 `biz=comments` 上传后得到的存储 key, 最多 3 个.
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

  /// 回复根评论 [commentId] 并返回新回复 id.
  ///
  /// [replyToId] 为被回复的子评论 id, 若直接回复根评论则为 null.
  /// 若被根评论作者或被回复人屏蔽, 服务端返回业务码 40002.
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

  /// 删除自己的评论或回复. 删除根评论时, 其下的回复会一并删除.
  Future<void> delete(int commentId) =>
      _client.delete(CommentEndpoints.comment(commentId));

  Future<void> like(int commentId) =>
      _client.put(CommentEndpoints.like(commentId));

  Future<void> unlike(int commentId) =>
      _client.delete(CommentEndpoints.like(commentId));

  /// 获取当前用户发表过的评论和回复, 按时间倒序排列, 已删除的条目不返回.
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
