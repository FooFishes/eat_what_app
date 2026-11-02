import 'package:dio/dio.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/history/history_api.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_repository.g.dart';

/// 足迹. 只有本人可见.
class HistoryRepository {
  HistoryRepository(this._api);

  final HistoryApi _api;

  /// 缺少名称或时间的条目 (如对象已被删除) 不显示.
  Future<Paged<Footprint>> list(
    FootprintKind kind, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.list(
      kind.api,
      page: page,
      cancelToken: cancelToken,
    );
    return Paged(
      items: [for (final item in result.items) ?_toFootprint(kind, item)],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  Future<void> clear(FootprintKind kind) => _api.clear(targetType: kind.api);

  Footprint? _toFootprint(FootprintKind kind, BrowseItemDto item) {
    final target = switch (kind) {
      FootprintKind.dish => item.food,
      FootprintKind.shop => item.restaurant,
    };
    final id = target?.id ?? item.targetId;
    final name = target?.name?.trim();
    final viewedAt = dateFromMillis(item.viewedAt);
    if (id == null || name == null || name.isEmpty || viewedAt == null) {
      return null;
    }
    return Footprint(
      kind: kind,
      id: id,
      name: name,
      image: imageUrl(target?.pictureUrl?.firstOrNull),
      likes: target?.likesCount,
      viewedAt: viewedAt,
    );
  }
}

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(Ref ref) =>
    HistoryRepository(ref.watch(historyApiProvider));
