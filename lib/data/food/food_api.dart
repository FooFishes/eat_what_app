import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/food/food_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_api.g.dart';

/// 列表接口的排序方式. 不传时, 指定店铺按 [menu] 排, 否则按 [newest] 排.
enum FoodSort {
  /// 菜单顺序: 招牌菜在前, 然后按分类顺序, 同一分类按赞数降序.
  menu('MENU'),
  newest('NEWEST');

  const new(this.api);

  final String api;
}

/// FoodApi 调用的接口路径, 相对于业务接口地址.
abstract final class FoodEndpoints {
  static String detail(int id) => '/foods/detail/$id';
  static const list = '/foods/list';
  static const favorites = '/foods/favorites';
  static const my = '/foods/my';
  static const upload = '/foods/upload';
  static String edit(int id) => '/foods/edit/$id';
  static String history(int id) => '/foods/$id/history';
  static String restore(int id, int revisionId) =>
      '/foods/$id/history/$revisionId/restore';
  static const suggestTags = '/foods/suggest-tags';
  static String like(int id) => '/foods/$id/like';
  static String unlike(int id) => '/foods/$id/unlike';
  static String favorite(int id) => '/foods/$id/favorite';
  static String unfavorite(int id) => '/foods/$id/unfavorite';
  static const systemTags = '/foods/tags/system';
  static String addSystemTags(int id) => '/foods/$id/tags/system';
  static String addCustomTags(int id) => '/foods/$id/tags/custom';
  static String foodTag(int id, int tagId) => '/foods/$id/tags/$tagId';
  static String tagsOf(int id) => '/foods/$id/tags';
  static String myTagFoods(int tagId) => '/foods/tags/my/$tagId/foods';
  static String myTag(int tagId) => '/foods/tags/my/$tagId';
  static const myTags = '/foods/tags/my';
  static String byUser(int userId) => '/foods/by-user/$userId';
}

/// 接口分组 Food: 详情, 列表, 发布, 编辑和修改记录, 赞和收藏, 他人的上传.
///
/// 标签的方法对应的接口在后端 v2 中已删除, 只有保留的待接入页面引用.
class FoodApi {
  FoodApi(this._client);

  final ApiClient _client;

  Future<FoodDto> detail(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(FoodEndpoints.detail(id), cancelToken: cancelToken),
        FoodDto.fromJson,
      );

  /// 按条件查询菜品. 多个条件之间为 "与" 关系. 不按校区过滤.
  ///
  /// - [keyword] 只匹配菜名, 最多 64 字.
  /// - [category] 是分类的中文原值.
  /// - [pageSize] 后端上限为 100.
  Future<Paged<FoodDto>> list({
    int? restaurantId,
    String? keyword,
    String? category,
    bool? signatureOnly,
    FoodSort? sort,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      FoodEndpoints.list,
      query: {
        'restaurantId': ?restaurantId,
        'keyword': ?keyword,
        'category': ?category,
        'signatureOnly': ?signatureOnly,
        'sort': ?sort?.api,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  /// 我收藏的菜, 按收藏时间倒序.
  Future<Paged<FoodDto>> favorites({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      FoodEndpoints.favorites,
      query: {'page': page, 'pageSize': pageSize},
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
      FoodEndpoints.my,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );

  /// 发布菜品, 返回新菜品的 id. 发布后即公开, 不经审核.
  ///
  /// - 同一店铺已有同名菜品时失败, 业务码为 `BizCodes.duplicateDish`, `data.id` 为已有菜品的 id.
  /// - 店铺已有 3 道招牌菜时, 标为招牌菜的请求失败, 业务码为 `BizCodes.stateNotAllowed`.
  Future<int> create(CreateFoodDto body) async => decodeCreatedId(
    await _client.post(FoodEndpoints.upload, body: body.toJson()),
  );

  /// 编辑菜品, 返回本次修改的记录 id. 内容没有变化时返回 null.
  ///
  /// 改名后与同一店铺的菜品重名, 或招牌菜已满时, 业务码与 [create] 相同.
  Future<int?> edit(int id, EditFoodDto body) async {
    final data = await _client.put(FoodEndpoints.edit(id), body: body.toJson());
    final revision = data is Map ? data['revisionId'] : null;
    return revision is num ? revision.toInt() : null;
  }

  /// 菜品的修改记录, 最新的在前. 不需要登录.
  Future<Paged<FoodRevisionDto>> history(
    int id, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      FoodEndpoints.history(id),
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodRevisionDto.fromJson,
  );

  /// 把菜品恢复到 [revisionId] 之后的内容, 记为一次新的修改.
  ///
  /// 当前内容已经是该版本时失败, 业务码为 `BizCodes.stateNotAllowed`.
  Future<void> restore(int id, int revisionId) =>
      _client.post(FoodEndpoints.restore(id, revisionId));

  /// 按菜名, 说明和照片识别分类和口味.
  ///
  /// 后端未启用识别或识别失败时返回业务码 40001.
  Future<FoodSuggestionDto> suggestTags(
    SuggestFoodDto body, {
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.post(
      FoodEndpoints.suggestTags,
      body: body.toJson(),
      cancelToken: cancelToken,
    ),
    FoodSuggestionDto.fromJson,
  );

  Future<void> like(int id) => _client.post(FoodEndpoints.like(id));

  Future<void> unlike(int id) => _client.post(FoodEndpoints.unlike(id));

  Future<void> favorite(int id) => _client.post(FoodEndpoints.favorite(id));

  Future<void> unfavorite(int id) => _client.post(FoodEndpoints.unfavorite(id));

  /// 口味词表, 由运营维护.
  Future<List<FoodTagDto>> systemTags({CancelToken? cancelToken}) async =>
      decodeList(
        await _client.get(FoodEndpoints.systemTags, cancelToken: cancelToken),
        FoodTagDto.fromJson,
      );

  Future<FoodTagsDto> tagsOf(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(FoodEndpoints.tagsOf(id), cancelToken: cancelToken),
        FoodTagsDto.fromJson,
      );

  Future<void> addSystemTags(int id, List<int> tagIds) =>
      _client.post(FoodEndpoints.addSystemTags(id), body: {'tagIds': tagIds});

  Future<void> addCustomTags(int id, List<String> names) =>
      _client.post(FoodEndpoints.addCustomTags(id), body: {'names': names});

  /// 撤回口味标签或移除我的标签. 两种标签共用此接口.
  Future<void> removeTag(int id, int tagId) =>
      _client.delete(FoodEndpoints.foodTag(id, tagId));

  /// 我写过的标签和各自用于几道菜.
  Future<Paged<FoodTagDto>> myTags({
    int page = 1,
    int pageSize = 50,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      FoodEndpoints.myTags,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodTagDto.fromJson,
  );

  Future<void> renameMyTag(int tagId, String name) =>
      _client.put(FoodEndpoints.myTag(tagId), body: {'name': name});

  /// 删除我的标签. 只去掉标签, 菜不受影响.
  Future<void> deleteMyTag(int tagId) =>
      _client.delete(FoodEndpoints.myTag(tagId));

  /// 我用个人标签 [tagId] 标过的菜, 跨店列出. 标签不存在或不是我的时失败, 业务码 40001.
  Future<Paged<FoodDto>> taggedWith(
    int tagId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      FoodEndpoints.myTagFoods(tagId),
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
      FoodEndpoints.byUser(userId),
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    FoodDto.fromJson,
  );
}

@Riverpod(keepAlive: true)
FoodApi foodApi(Ref ref) => FoodApi(ref.watch(apiClientProvider));
