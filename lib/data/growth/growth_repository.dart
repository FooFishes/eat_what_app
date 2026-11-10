import 'package:dio/dio.dart';
import 'package:eat/data/growth/growth_api.dart';
import 'package:eat/domain/models/growth.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'growth_repository.g.dart';

/// 本人的等级和经验. 他人的等级在公开资料中, 见 `UserRepository.profile`.
class GrowthRepository {
  GrowthRepository(this._api);

  final GrowthApi _api;

  Future<GrowthProgress> progress({CancelToken? cancelToken}) async {
    final dto = await _api.progress(cancelToken: cancelToken);
    final total = dto.totalExperience ?? 0;
    final next = dto.maxLevel == true ? null : dto.nextLevelExperience;
    return GrowthProgress(
      level: dto.level ?? 1,
      totalExperience: total,
      levelStartAt: dto.levelStartExperience ?? 0,
      nextLevelAt: next,
      toNextLevel:
          dto.experienceToNextLevel ?? (next == null ? 0 : next - total),
      dailyExperience: dto.dailyExperience ?? 0,
    );
  }

  /// 缺少 id 或日期的条目不显示.
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
    final id = dto.entryId;
    final date = DateTime.tryParse(dto.businessDate ?? '');
    if (id == null || date == null) return null;
    return ExperienceEntry(
      id: id,
      source: ExperienceSource.fromApi(dto.sourceType),
      amount: dto.experience ?? 0,
      date: DateTime(date.year, date.month, date.day),
    );
  }
}

@Riverpod(keepAlive: true)
GrowthRepository growthRepository(Ref ref) =>
    GrowthRepository(ref.watch(growthApiProvider));
