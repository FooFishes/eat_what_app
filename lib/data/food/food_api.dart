import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_api.g.dart';

/// 列表接口的排序。
enum FoodSort {
  newest('NEWEST'),
  popular('POPULAR');

  const new(this.api);

  final String api;
}

/// 接口分组 Food：推荐、详情、列表、赞和收藏、标签。发布和编辑在阶段四加。
class FoodApi {
  FoodApi(this._client);

  final ApiClient _client;

  static const endpoints = [
    'GET /foods/recommend',
    'GET /foods/detail/{id}',
    'GET /foods/list',
    'GET /foods/favorites',
    'GET /foods/my',
    'POST /foods/{id}/like',
    'POST /foods/{id}/unlike',
    'POST /foods/{id}/favorite',
    'POST /foods/{id}/unfavorite',
    'GET /foods/tags/system',
    'GET /foods/{id}/tags',
    'POST /foods/{id}/tags/system',
    'POST /foods/{id}/tags/custom',
    'DELETE /foods/{id}/tags/{tagId}',
  ];

  /// 推荐一批菜。游客靠 [deviceId] 当天去重。
  Future<Paged<FoodDto>> recommend({
    int? campusId,
    String? mealTime,
    String? category,
    int size = 8,
    String? deviceId,
    CancelToken? cancelToken,
  }) async => decodePage(
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

  /// 按条件查菜：一家店的菜单、跨店搜菜名、我的标签下的菜。条件之间是「并且」。
  Future<Paged<FoodDto>> list({
    int? restaurantId,
    int? hubId,
    String? keyword,
    List<int>? myCustomTagIds,
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

  Future<void> like(int id) => _client.post('/foods/$id/like');

  Future<void> unlike(int id) => _client.post('/foods/$id/unlike');

  Future<void> favorite(int id) => _client.post('/foods/$id/favorite');

  Future<void> unfavorite(int id) => _client.post('/foods/$id/unfavorite');

  /// 口味词表，由运营维护。
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

  /// 撤回一个口味标签或去掉一个我的标签，两种标签共用这个接口。
  Future<void> removeTag(int id, int tagId) =>
      _client.delete('/foods/$id/tags/$tagId');
}

@Riverpod(keepAlive: true)
FoodApi foodApi(Ref ref) => FoodApi(ref.watch(apiClientProvider));
