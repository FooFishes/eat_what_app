import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/topic/topic_dto.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topic_api.g.dart';

/// TopicApi 调用的接口路径, 相对于业务接口地址.
abstract final class TopicEndpoints {
  static const current = '/topics/current';
  static const history = '/topics/history';
  static String byFood(int foodId) => '/topics/by-food/$foodId';
  static String detail(int id) => '/topics/$id';
}

/// 专题接口 (`Topic` 分组), 提供当期专题, 往期专题, 专题详情及菜品关联专题查询.
class TopicApi {
  TopicApi(this._client);

  final ApiClient _client;

  /// 获取指定校区的当期专题, 若暂无进行中的专题则返回 null.
  Future<TopicSummaryDto?> current(
    int campusId, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get(
      TopicEndpoints.current,
      query: {'campusId': campusId},
      cancelToken: cancelToken,
    );
    return data == null ? null : decodeJson(data, TopicSummaryDto.fromJson);
  }

  /// 分页获取指定校区已结束的专题, 按结束时间倒序排列.
  Future<Paged<TopicSummaryDto>> history(
    int campusId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      TopicEndpoints.history,
      query: {'campusId': campusId, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    TopicSummaryDto.fromJson,
  );

  /// 获取专题详情及其包含的菜品; 若专题未发布或尚未开始, 服务端返回 `BizCodes.stateNotAllowed`.
  Future<TopicDetailDto> detail(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(TopicEndpoints.detail(id), cancelToken: cancelToken),
        TopicDetailDto.fromJson,
      );

  /// 获取收录过指定菜品且已开始的专题列表, 按开始时间倒序排列.
  Future<List<TopicSummaryDto>> byFood(
    int foodId, {
    CancelToken? cancelToken,
  }) async => decodeList(
    await _client.get(TopicEndpoints.byFood(foodId), cancelToken: cancelToken),
    TopicSummaryDto.fromJson,
  );
}

@Riverpod(keepAlive: true)
TopicApi topicApi(Ref ref) => TopicApi(ref.watch(apiClientProvider));
