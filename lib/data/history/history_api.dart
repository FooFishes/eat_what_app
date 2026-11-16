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

/// 封装 History 接口分组的浏览足迹接口. 浏览记录由服务端在请求详情接口时自动写入, 客户端仅负责读取与清空.
class HistoryApi {
  HistoryApi(this._client);

  final ApiClient _client;

  /// 获取浏览足迹列表, 按最近浏览时间倒序排列. [targetType] 取值为 `food` 或 `restaurant`.
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

  /// 清空指定 [targetType] 分栏的浏览足迹; 为 null 时清空全部两个分栏.
  Future<void> clear({String? targetType}) => _client.delete(
    HistoryEndpoints.browse,
    query: {'targetType': ?targetType},
  );
}

/// 单条浏览足迹 (`HistoryDtos.Item`). 根据 [targetType] 仅填充 [food] 或 [restaurant] 其一, 若目标对象已删除则两者均为 null.
@JsonSerializable(createToJson: false)
class const BrowseItemDto({
  final String? targetType,
  final int? targetId,
  final int? viewedAt,
  final BrowseFoodDto? food,
  final BrowseShopDto? restaurant,
}) {
  factory BrowseItemDto.fromJson(Map<String, dynamic> json) =>
      _$BrowseItemDtoFromJson(json);
}

/// 足迹中菜品的摘要信息 (`HistoryDtos.Food`).
@JsonSerializable(createToJson: false)
class const BrowseFoodDto({
  final int? id,
  final int? restaurantId,
  final String? name,
  final List<String>? pictureUrls,
  final int? likeCount,
}) {
  factory BrowseFoodDto.fromJson(Map<String, dynamic> json) =>
      _$BrowseFoodDtoFromJson(json);
}

/// 足迹中店铺的摘要信息 (`HistoryDtos.Restaurant`), [pictureUrl] 为门头照地址.
@JsonSerializable(createToJson: false)
class const BrowseShopDto({
  final int? id,
  final String? name,
  final String? pictureUrl,
}) {
  factory BrowseShopDto.fromJson(Map<String, dynamic> json) =>
      _$BrowseShopDtoFromJson(json);
}

@Riverpod(keepAlive: true)
HistoryApi historyApi(Ref ref) => HistoryApi(ref.watch(apiClientProvider));
