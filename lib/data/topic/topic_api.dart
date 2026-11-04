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

/// 接口分组 Topic: 当期专题, 往期专题, 专题详情, 收录过某道菜的专题.
class TopicApi {
  TopicApi(this._client);

  final ApiClient _client;

  /// 校区的当期专题. 没有当期专题时返回 null.
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

  /// 校区已结束的专题, 按结束时间倒序.
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

  /// 专题和其中的菜. 专题未发布或尚未开始时返回业务码 `BizCodes.stateNotAllowed`.
  Future<TopicDetailDto> detail(int id, {CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(TopicEndpoints.detail(id), cancelToken: cancelToken),
        TopicDetailDto.fromJson,
      );

  /// 收录过这道菜且已开始的专题, 按开始时间倒序.
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
