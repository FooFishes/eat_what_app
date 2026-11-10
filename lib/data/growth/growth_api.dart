import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'growth_api.g.dart';

/// GrowthApi 调用的接口路径, 相对于业务接口地址.
abstract final class GrowthEndpoints {
  static const progress = '/user/growth';
  static const ledger = '/user/growth/ledger';
}

/// 接口分组 Growth: 本人的等级和经验.
///
/// 每日经验由服务端在当天第一个业务请求中自动发放, 客户端不调用 `POST /user/activity`.
class GrowthApi {
  GrowthApi(this._client);

  final ApiClient _client;

  Future<GrowthProgressDto> progress({CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(GrowthEndpoints.progress, cancelToken: cancelToken),
        GrowthProgressDto.fromJson,
      );

  /// 经验明细, 按入账时间倒序.
  Future<Paged<ExperienceEntryDto>> ledger({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async => decodePage(
    await _client.get(
      GrowthEndpoints.ledger,
      query: {'page': page, 'pageSize': pageSize},
      cancelToken: cancelToken,
    ),
    ExperienceEntryDto.fromJson,
  );
}

/// `/user/growth` 的 `data`. 门槛都是累计经验, [nextLevelExperience] 满级时为 null.
@JsonSerializable(createToJson: false)
class const GrowthProgressDto({
  final int? totalExperience,
  final int? level,
  final int? levelStartExperience,
  final int? nextLevelExperience,
  final int? experienceToNextLevel,
  final bool? maxLevel,
  final int? dailyExperience,
}) {
  factory GrowthProgressDto.fromJson(Map<String, dynamic> json) =>
      _$GrowthProgressDtoFromJson(json);
}

/// 经验明细的一笔.
///
/// [businessDate] 是所属日期 (北京时间), 格式 `yyyy-MM-dd`. [sourceType] 目前只有 `DAILY_USE`.
@JsonSerializable(createToJson: false)
class const ExperienceEntryDto({
  final String? entryId,
  final String? businessDate,
  final String? sourceType,
  final int? experience,
}) {
  factory ExperienceEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ExperienceEntryDtoFromJson(json);
}

@Riverpod(keepAlive: true)
GrowthApi growthApi(Ref ref) => GrowthApi(ref.watch(apiClientProvider));
