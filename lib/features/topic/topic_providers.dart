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

/// 获取指定专题详情, 若专题不存在或尚未开始则返回 null.
///
/// 由于往期专题列表每行也会读取该详情以展示前三道菜, 缓存 5 分钟后从列表进入专题页时无需重复请求.
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

/// 往期专题列表的分页状态, 包含已加载的分页数据及下一页是否加载失败.
typedef TopicArchivePages = ({Paged<Topic> pages, bool moreFailed});

/// 当前校区的往期专题分页列表, 支持触底加载下一页, 切换校区时自动重新请求.
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
