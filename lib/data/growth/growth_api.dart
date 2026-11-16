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

/// 封装 User 分组中的等级与经验接口, 仅限本人查看.
///
/// 每日经验由服务端在当天首个携带会话的请求中自动发放, 客户端无需上报;
/// 账号封禁期间仍可查看当前等级, 但无法查看经验明细.
class GrowthApi {
  GrowthApi(this._client);

  final ApiClient _client;

  Future<GrowthProgressDto> progress({CancelToken? cancelToken}) async =>
      decodeJson(
        await _client.get(GrowthEndpoints.progress, cancelToken: cancelToken),
        GrowthProgressDto.fromJson,
      );

  /// 获取经验变更明细, 按时间倒序排列.
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

/// `/user/level` 的 `data` (`UserDtos.Level`), 其中的升级门槛均以累计经验计算.
///
/// 达到满级时, [nextLevel], [nextLevelExperience] 与 [toNextLevel] 均为 null.
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

  /// 等级称号, 目前只有满级有 ("老吃家"), 其余为 null.
  final String? title,

  /// 各经验来源的规则, 按服务端给定的顺序展示.
  final List<ExperienceRuleDto>? rules,
}) {
  factory GrowthProgressDto.fromJson(Map<String, dynamic> json) =>
      _$GrowthProgressDtoFromJson(json);
}

/// 一个经验来源的规则 (`UserDtos.ExperienceRule`).
///
/// [source] 是来源代码, [name] 是显示名 ("发布菜品"), [amount] 是每次得到的经验, [dailyCap] 是每天最多几次.
@JsonSerializable(createToJson: false)
class const ExperienceRuleDto({
  final String? source,
  final String? name,
  final int? amount,
  final int? dailyCap,
}) {
  factory ExperienceRuleDto.fromJson(Map<String, dynamic> json) =>
      _$ExperienceRuleDtoFromJson(json);
}

/// 经验明细的一笔 (`UserDtos.ExperienceLog`).
///
/// [day] 是所属日期 (北京时间), 格式 `yyyy-MM-dd`. [source] 是来源代码, [sourceName] 是显示名.
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
