import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/recommend/recommend_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recommend_api.g.dart';

/// RecommendApi 调用的接口路径, 相对于业务接口地址.
abstract final class RecommendEndpoints {
  static const feed = '/recommend';
  static const pick = '/recommend/pick';
  static String dismiss(int id) => '/recommend/dismiss/$id';
}

/// 店铺推荐接口 (`Recommend` 分组), 游客可浏览推荐流, 但标记 "不感兴趣" 需要登录.
class RecommendApi {
  RecommendApi(this._client);

  final ApiClient _client;

  /// 获取一页推荐店铺.
  ///
  /// - [scene] 取值为 `dine_in` (默认) 或 `delivery`; [kind] 取值为 `food` (默认) 或 `drink`.
  /// - 若传入坐标, 堂食仅推荐 3000 m 内店铺, 外卖仅推荐 5000 m 内店铺, 且返回卡片附带 `distanceMeters`.
  /// - 若省略 [mealTime], 服务端按北京时间自动判定当前饭点.
  /// - 登录用户每次返回当日尚未推荐过的店铺, [page] 仅作回显; 游客则按 [page] 正常翻页.
  /// - [pageSize] 默认为 10, 最大值为 30.
  Future<RecommendFeedDto> feed({
    String? scene,
    double? gcjLat,
    double? gcjLng,
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
        'mealTime': ?mealTime,
        'kind': ?kind,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    ),
    RecommendFeedDto.fromJson,
  );

  // TODO: 后端应返回数组供首页转盘使用, 目前只返回一家店. 后端修正后改为返回一批店铺并接到发现页转盘.
  /// 摇一摇: 从排名最前的几家里随机挑一家店, 参数含义同 [feed]; 没有候选时 `restaurant` 为 null.
  ///
  /// 登录且开启个性化推荐时, 挑中的店计入当日已推荐, 与 [feed] 共用去重池.
  Future<RecommendPickDto> pick({
    String? scene,
    double? gcjLat,
    double? gcjLng,
    String? mealTime,
    String? kind,
    CancelToken? cancelToken,
  }) async => decodeJson(
    await _client.get(
      RecommendEndpoints.pick,
      query: {
        'scene': ?scene,
        'gcjLat': ?gcjLat,
        'gcjLng': ?gcjLng,
        'mealTime': ?mealTime,
        'kind': ?kind,
      },
      cancelToken: cancelToken,
    ),
    RecommendPickDto.fromJson,
  );

  /// 标记指定店铺 30 天内不再推荐, 重复标记会重新计时; 该操作需登录且每日上限为 50 次.
  Future<void> dismiss(int id) => _client.post(RecommendEndpoints.dismiss(id));
}

@Riverpod(keepAlive: true)
RecommendApi recommendApi(Ref ref) =>
    RecommendApi(ref.watch(apiClientProvider));
