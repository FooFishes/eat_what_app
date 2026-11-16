import 'package:dio/dio.dart';
import 'package:eat/data/growth/growth_api.dart';
import 'package:eat/domain/models/growth.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'growth_repository.g.dart';

/// 提供本人的等级与经验数据. 他人等级包含在公开资料中, 见 `UserRepository.profile`.
class GrowthRepository {
  GrowthRepository(this._api);

  final GrowthApi _api;

  Future<GrowthProgress> progress({CancelToken? cancelToken}) async {
    final dto = await _api.progress(cancelToken: cancelToken);
    final total = dto.experience ?? 0;
    final next = dto.maxLevel == true ? null : dto.nextLevelExperience;
    return GrowthProgress(
      level: dto.level ?? 1,
      totalExperience: total,
      levelStartAt: dto.levelExperience ?? 0,
      nextLevelAt: next,
      toNextLevel: dto.toNextLevel ?? (next == null ? 0 : next - total),
      dailyExperience: dto.dailyUseExperience ?? 0,
    );
  }

  /// 获取经验明细分页数据, 缺少 id 或日期的条目会被过滤.
  Future<Paged<ExperienceEntry>> ledger({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.ledger(page: page, cancelToken: cancelToken);
    return Paged(
      items: [for (final dto in result.items) ?_entry(dto)],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  static ExperienceEntry? _entry(ExperienceEntryDto dto) {
    final id = dto.id;
    final date = DateTime.tryParse(dto.day ?? '');
    if (id == null || date == null) return null;
    final source = ExperienceSource.fromApi(dto.source);
    final name = dto.sourceName?.trim();
    return ExperienceEntry(
      id: '$id',
      source: source,
      label: name == null || name.isEmpty ? source.label : name,
      amount: dto.amount ?? 0,
      date: DateTime(date.year, date.month, date.day),
    );
  }
}

@Riverpod(keepAlive: true)
GrowthRepository growthRepository(Ref ref) =>
    GrowthRepository(ref.watch(growthApiProvider));
