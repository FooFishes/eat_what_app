import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/topic/topic_repository.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/topic.dart';
import 'package:eat/state/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topic_providers.g.dart';

/// 专题详情. 专题不存在或尚未开始时为 null.
///
/// 往期专题的每一行读取专题详情来显示前三道菜, 因此进入专题页时不重新请求.
@riverpod
Future<TopicDetail?> topicDetail(Ref ref, int topicId) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    return await ref
        .watch(topicRepositoryProvider)
        .detail(topicId, cancelToken: ref.cancelToken());
  } on AppFailure catch (e) {
    if (e.code == BizCodes.stateNotAllowed) return null;
    rethrow;
  }
}

/// 往期专题的数据: 已获取的分页, 以及下一页是否加载失败.
typedef TopicArchivePages = ({Paged<Topic> pages, bool moreFailed});

/// 当前校区的往期专题, 滚动到底部时加载下一页. 切换校区后重新请求.
@riverpod
class TopicArchive extends _$TopicArchive {
  var _loadingMore = false;

  @override
  Future<TopicArchivePages> build() async {
    final (:campusId, :ready) = ref.watch(
      currentPlaceProvider.select(
        (p) => (campusId: p.campus?.id, ready: p.ready),
      ),
    );
    if (!ready) return Completer<TopicArchivePages>().future;
    if (campusId == null) {
      return (pages: const Paged<Topic>.empty(), moreFailed: false);
    }
    final pages = await ref
        .watch(topicRepositoryProvider)
        .history(campusId, cancelToken: ref.cancelToken());
    return (pages: pages, moreFailed: false);
  }

  Future<void> loadMore() async {
    final current = state.value?.pages;
    final campusId = ref.read(currentPlaceProvider).campus?.id;
    if (current == null || !current.hasNext || _loadingMore) return;
    if (campusId == null) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(topicRepositoryProvider)
          .history(campusId, page: current.page + 1);
      if (ref.mounted) {
        state = AsyncData((pages: current.append(next), moreFailed: false));
      }
    } on AppFailure {
      if (ref.mounted) state = AsyncData((pages: current, moreFailed: true));
    } finally {
      _loadingMore = false;
    }
  }
}
