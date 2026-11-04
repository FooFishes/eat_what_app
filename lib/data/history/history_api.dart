import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_api.g.dart';

/// HistoryApi 调用的接口路径, 相对于业务接口地址.
abstract final class HistoryEndpoints {
  static const browse = '/history/browse';
}

/// 接口分组 History: 足迹. 浏览记录由服务端在请求详情时写入, 客户端只读取和清空.
class HistoryApi {
  HistoryApi(this._client);

  final ApiClient _client;

  /// [targetType] 为 `food` 或 `restaurant`, 按最近浏览时间倒序.
  Future<Paged<BrowseItemDto>> list(
    String targetType, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      HistoryEndpoints.browse,
      query: {'targetType': targetType, 'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    BrowseItemDto.fromJson,
  );

  /// 清空 [targetType] 分栏的足迹. 为 null 时两栏都清空.
  Future<void> clear({String? targetType}) => _client.delete(
    HistoryEndpoints.browse,
    query: {'targetType': ?targetType},
  );
}

/// 足迹的一项. 按 [targetType] 只有 [food] 或 [restaurant] 其中之一.
@JsonSerializable(createToJson: false)
class const BrowseItemDto({
  final String? targetType,
  final int? targetId,
  final int? viewedAt,
  final BrowseTargetDto? food,
  final BrowseTargetDto? restaurant,
}) {
  factory BrowseItemDto.fromJson(Map<String, dynamic> json) =>
      _$BrowseItemDtoFromJson(json);
}

/// 足迹中菜或店的摘要. [likesCount] 只有菜有.
@JsonSerializable(createToJson: false)
class const BrowseTargetDto({
  final int? id,
  final String? name,
  final List<String>? pictureUrl,
  final int? likesCount,
}) {
  factory BrowseTargetDto.fromJson(Map<String, dynamic> json) =>
      _$BrowseTargetDtoFromJson(json);
}

@Riverpod(keepAlive: true)
HistoryApi historyApi(Ref ref) => HistoryApi(ref.watch(apiClientProvider));
