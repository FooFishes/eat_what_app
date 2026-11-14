import 'package:dio/dio.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'growth_api.g.dart';

/// GrowthApi 调用的接口路径, 相对于业务接口地址.
abstract final class GrowthEndpoints {
  static const progress = '/user/level';
  static const ledger = '/user/level/logs';
}

/// 接口分组 User 中的等级和经验, 只有本人能看.
///
/// 每日经验由服务端在当天第一个带会话的请求中自动发放, 客户端不用上报.
/// 封禁中能看等级, 不能看经验明细.
class GrowthApi {
  GrowthApi(this._client);

  final ApiClient _client;

  Future<GrowthProgressDto> progress({CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(GrowthEndpoints.progress, cancelToken: cancelToken),
        GrowthProgressDto.fromJson,
      );

  /// 经验明细, 最新的在前.
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

/// `/user/level` 的 `data` (`UserDtos.Level`). 门槛都是累计经验.
///
/// [nextLevel], [nextLevelExperience], [toNextLevel] 满级时为 null.
@JsonSerializable(createToJson: false)
class const GrowthProgressDto({
  final int? level,
  final int? experience,
  final int? levelExperience,
  final int? nextLevel,
  final int? nextLevelExperience,
  final int? toNextLevel,
  final bool? maxLevel,
  final int? dailyUseExperience,
}) {
  factory GrowthProgressDto.fromJson(Map<String, dynamic> json) =>
      _$GrowthProgressDtoFromJson(json);
}

/// 经验明细的一笔 (`UserDtos.ExperienceLog`).
///
/// [day] 是所属日期 (北京时间), 格式 `yyyy-MM-dd`. [source] 目前只有 `daily_use`, [sourceName] 是显示名.
@JsonSerializable(createToJson: false)
class const ExperienceEntryDto({
  final int? id,
  final String? source,
  final String? sourceName,
  final int? amount,
  final String? day,
}) {
  factory ExperienceEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ExperienceEntryDtoFromJson(json);
}

@Riverpod(keepAlive: true)
GrowthApi growthApi(Ref ref) => GrowthApi(ref.watch(apiClientProvider));
