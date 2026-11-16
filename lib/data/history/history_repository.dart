import 'package:dio/dio.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/history/history_api.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_repository.g.dart';

/// 提供浏览足迹的读取与清空能力, 仅限本人查看.
class HistoryRepository {
  HistoryRepository(this._api);

  final HistoryApi _api;

  /// 获取指定分栏的足迹列表, 缺少名称或浏览时间的条目 (如对象已删除) 将被过滤.
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
    final (id, name, image, likes) = switch (kind) {
      FootprintKind.dish => (
        item.food?.id,
        item.food?.name,
        item.food?.pictureUrls?.firstOrNull,
        item.food?.likeCount,
      ),
      FootprintKind.shop => (
        item.restaurant?.id,
        item.restaurant?.name,
        item.restaurant?.pictureUrl,
        null,
      ),
    };
    final title = name?.trim();
    final viewedAt = dateFromMillis(item.viewedAt);
    final targetId = id ?? item.targetId;
    if (targetId == null ||
        title == null ||
        title.isEmpty ||
        viewedAt == null) {
      return null;
    }
    return Footprint(
      kind: kind,
      id: targetId,
      name: title,
      image: imageUrl(image),
      likes: likes,
      viewedAt: viewedAt,
    );
  }
}

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(Ref ref) =>
    HistoryRepository(ref.watch(historyApiProvider));
