import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/recommend/recommend_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recommend_api.g.dart';

/// RecommendApi 调用的接口路径, 相对于业务接口地址.
abstract final class RecommendEndpoints {
  static const feed = '/recommend';
  static String dismiss(int id) => '/recommend/dismiss/$id';
}

/// 推荐店铺 (Recommend 分组). 游客也能看推荐, "不感兴趣" 需要登录.
class RecommendApi {
  RecommendApi(this._client);

  final ApiClient _client;

  /// 一页推荐店铺.
  ///
  /// - [scene] 为 `dine_in` (省略时的默认值) 或 `delivery`, [kind] 为 `food` (省略时的默认值) 或 `drink`.
  /// - 带坐标时, 堂食只找 3000 m 内的店, 外卖只找 5000 m 内的店, 卡片带 `distanceMeters`.
  /// - 省略 [mealTime] 时后端按北京时间判断.
  /// - 登录用户每次返回当天还没推荐过的店, [page] 只回显. 游客按 [page] 翻页.
  /// - [pageSize] 默认 10, 上限 30.
  Future<RecommendFeedDto> feed({
    String? scene,
    double? gcjLat,
    double? gcjLng,
    int? campusId,
    String? mealTime,
    String? kind,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      RecommendEndpoints.feed,
      query: {
        'scene': ?scene,
        'gcjLat': ?gcjLat,
        'gcjLng': ?gcjLng,
        'campusId': ?campusId,
        'mealTime': ?mealTime,
        'kind': ?kind,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    ),
    RecommendFeedDto.fromJson,
  );

  /// 30 天内不再推荐这家店, 重复标记重新计时. 需要登录, 每天最多 50 次.
  Future<void> dismiss(int id) => _client.post(RecommendEndpoints.dismiss(id));
}

@Riverpod(keepAlive: true)
RecommendApi recommendApi(Ref ref) =>
    RecommendApi(ref.watch(apiClientProvider));
