import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_api.g.dart';

/// 列表接口的排序方式.
enum FoodSort {
  newest('NEWEST'),
  popular('POPULAR'),

  /// 店铺与请求坐标的距离升序, 需要坐标.
  distance('DISTANCE');

  const new(this.api);

  final String api;
}

/// 接口分组 Food: 推荐, 详情, 列表, 发布, 赞和收藏, 标签, 他人的上传.
class FoodApi {
  FoodApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /foods/recommend',
    'GET /foods/detail/{id}',
    'GET /foods/list',
    'GET /foods/favorites',
    'GET /foods/my',
    'POST /foods/upload',
    'POST /foods/{id}/like',
    'POST /foods/{id}/unlike',
    'POST /foods/{id}/favorite',
    'POST /foods/{id}/unfavorite',
    'GET /foods/tags/system',
    'GET /foods/{id}/tags',
    'POST /foods/{id}/tags/system',
    'POST /foods/{id}/tags/custom',
    'DELETE /foods/{id}/tags/{tagId}',
    'GET /foods/tags/my',
    'PUT /foods/tags/my/{tagId}',
    'DELETE /foods/tags/my/{tagId}',
    'GET /foods/by-user/{userId}',
    'GET /foods/tags/my/{tagId}/foods',
  ];

  /// 推荐一批菜品. 游客按 [deviceId] 在当天内去重.
  ///
  /// 后端返回 `FoodVO` 数组. 接口文档写成 `PageResult` 是文档错误, 后端已确认.
  Future<List<FoodDto>> recommend({
    int? campusId,
    String? mealTime,
    String? category,
    int size = 8,
    String? deviceId,
    CancelToken? cancelToken,
  }) async => decodeList(
    await _client.get(
      '/foods/recommend',
      query: {
        'campusId': ?campusId,
        'mealTime': ?mealTime,
        'category': ?category,
        'size': size,
        'deviceId': ?deviceId,
      },
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  Future<FoodDto> detail(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get('/foods/detail/$id', cancelToken: cancelToken),
        FoodDto.fromJson,
      );

  /// 按条件查询菜品. 多个条件之间为 "与" 关系.
  ///
  /// 用于店铺菜单, 跨店按菜名搜索, 按我的标签筛选.
  /// 坐标必须成对传入. 带坐标时每道菜带 `distanceMeters`.
  Future<Paged<FoodDto>> list({
    int? restaurantId,
    int? hubId,
    String? keyword,
    List<int>? myCustomTagIds,
    List<int>? systemTagIds,
    double? gcjLat,
    double? gcjLng,
    FoodSort? sort,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/foods/list',
      query: {
        'restaurantId': ?restaurantId,
        'hubId': ?hubId,
        'keyword': ?keyword,
        'myCustomTagIds': ?myCustomTagIds,
        'systemTagIds': ?systemTagIds,
        'gcjLat': ?gcjLat,
        'gcjLng': ?gcjLng,
        'sort': ?sort?.api,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  Future<Paged<FoodDto>> favorites({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/foods/favorites',
      query: {'page': page, 'pageSize': pageSize, 'sort': 'FAVORITED_AT'},
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  Future<Paged<FoodDto>> mine({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/foods/my',
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  /// 发布菜品, 返回新菜品的 id 和审核状态.
  ///
  /// - 同一店铺已有同名菜品时失败, 业务码为 `BizCodes.duplicateDish`, `data.id` 为已有菜品的 id.
  /// - [idempotencyKey] 是 UUID. 服务端对同一个键只受理一次, 并拒绝同一个键对应不同正文的请求.
  /// - 服务端未启用内容审核时不返回 `moderationStatus`, 此时为 null, 菜品直接公开.
  Future<({int id, String? moderationStatus})> create(
    CreateFoodDto body, {
    String? idempotencyKey,
  }) async {
    final data = await _client.post(
      '/foods/upload',
      body: body.toJson(),
      headers: {'Idempotency-Key': ?idempotencyKey},
    );
    final status = data is Map ? data['moderationStatus'] : null;
    return (
      id: decodeCreatedId(data),
      moderationStatus: status is String ? status : null,
    );
  }

  Future<void> like(int id) => _client.post('/foods/$id/like');

  Future<void> unlike(int id) => _client.post('/foods/$id/unlike');

  Future<void> favorite(int id) => _client.post('/foods/$id/favorite');

  Future<void> unfavorite(int id) => _client.post('/foods/$id/unfavorite');

  /// 口味词表, 由运营维护.
  Future<List<FoodTagDto>> systemTags({CancelToken? cancelToken}) async =>
      decodeList(
        await _client.get('/foods/tags/system', cancelToken: cancelToken),
        FoodTagDto.fromJson,
      );

  Future<FoodTagsDto> tagsOf(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get('/foods/$id/tags', cancelToken: cancelToken),
        FoodTagsDto.fromJson,
      );

  Future<void> addSystemTags(int id, List<int> tagIds) =>
      _client.post('/foods/$id/tags/system', body: {'tagIds': tagIds});

  Future<void> addCustomTags(int id, List<String> names) =>
      _client.post('/foods/$id/tags/custom', body: {'names': names});

  /// 撤回口味标签或移除我的标签. 两种标签共用此接口.
  Future<void> removeTag(int id, int tagId) =>
      _client.delete('/foods/$id/tags/$tagId');

  /// 我写过的标签和各自用于几道菜.
  Future<Paged<FoodTagDto>> myTags({
    int page = 1,
    int pageSize = 50,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/foods/tags/my',
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodTagDto.fromJson,
  );

  Future<void> renameMyTag(int tagId, String name) =>
      _client.put('/foods/tags/my/$tagId', body: {'name': name});

  /// 删除我的标签. 只去掉标签, 菜不受影响.
  Future<void> deleteMyTag(int tagId) =>
      _client.delete('/foods/tags/my/$tagId');

  /// 我用个人标签 [tagId] 标过的菜, 跨店列出. 标签不存在或不是我的时失败, 业务码 40001.
  Future<Paged<FoodDto>> taggedWith(
    int tagId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/foods/tags/my/$tagId/foods',
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  /// [userId] 上传的菜, 按发布时间倒序. 用于他人主页的 "上传" 分栏.
  Future<Paged<FoodDto>> byUser(
    int userId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      '/foods/by-user/$userId',
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );
}

@Riverpod(keepAlive: true)
FoodApi foodApi(Ref ref) => FoodApi(ref.watch(apiClientProvider));
