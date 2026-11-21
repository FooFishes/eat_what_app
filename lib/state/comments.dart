/// 评论与回复的跨页面共享状态.
///
/// 菜品详情, 全部评论, 写评论及 "我的" 共用同一份评论数据, 发表, 删除或点赞后需在各页面间同步生效,
/// 因此集中维护在 `state` 中.
library;

import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/rules/comment_rules.dart';
import 'package:eat/state/analytics.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments.g.dart';

/// 分页加载的评论列表. 加载下一页失败时记录在 [moreError] 中, 列表底部显示 "重试".
class const CommentList({
  required final CommentPage data,
  final AppFailure? moreError,

  /// 只取了预览用的前几条回复, 见 [CommentReplies].
  final bool preview = false,
}) {
  List<Comment> get items => data.page.items;
}

int? _myId(Ref ref) =>
    ref.watch(sessionProvider.select((s) => s is SignedIn ? s.user?.id : null));

/// 指定菜品的评论列表状态. 菜品详情与全部评论页共用 "最有用" 排序的数据, 详情页仅展示前几条.
///
/// 离开页面后保留 5 分钟.
@riverpod
class DishComments extends _$DishComments {
  @override
  Future<CommentList> build(int dishId, CommentSort sort) async {
    ref.cacheFor(const Duration(minutes: 5));
    _myId(ref);
    return CommentList(
      data: await ref
          .watch(commentRepositoryProvider)
          .comments(dishId, sort: sort, cancelToken: ref.cancelToken()),
    );
  }

  var _loading = false;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.data.page.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await ref
          .read(commentRepositoryProvider)
          .comments(dishId, sort: sort, page: current.data.page.page + 1);
      if (ref.mounted) {
        state = AsyncData(CommentList(data: current.data.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(CommentList(data: current.data, moreError: e));
      }
    } finally {
      _loading = false;
    }
  }

  /// 从列表中移除 [commentId], 不发起请求. 删除成功后由 [CommentWriter] 调用.
  void removeLocal(int commentId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(CommentList(data: current.data.without(commentId)));
  }

  /// 把评论 [rootId] 的回复条数加上 [delta], 不发起请求. 回复发表或删除后由 [CommentWriter] 调用.
  ///
  /// 回复条数为 0 的评论不请求回复列表, 因此发表第一条回复后需要更新条数, 回复才会显示.
  void adjustReplies(int rootId, int delta) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      CommentList(
        data: current.data.withReplies(rootId, delta),
        moreError: current.moreError,
      ),
    );
  }
}

/// 单条评论下的回复列表状态, 按时间正序排列.
///
/// 先只取 [CommentRules.replyPreview] 条作为预览, 展开后每页 20 条.
/// 接口按页码分页, 预览之后无法接着第 3 条取下一页, 所以第一次 [loadMore] 重新取第 1 页并替换预览.
@riverpod
class CommentReplies extends _$CommentReplies {
  static const _pageSize = 20;

  @override
  Future<CommentList> build(int commentId) async {
    ref.cacheFor(const Duration(minutes: 5));
    _myId(ref);
    return CommentList(
      data: await ref
          .watch(commentRepositoryProvider)
          .replies(
            commentId,
            pageSize: CommentRules.replyPreview,
            cancelToken: ref.cancelToken(),
          ),
      preview: true,
    );
  }

  var _loading = false;

  /// 预览时取第 1 页替换预览, 否则取下一页追加.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.data.page.hasNext || _loading) return;
    _loading = true;
    try {
      final repo = ref.read(commentRepositoryProvider);
      final next = current.preview
          ? await repo.replies(commentId, pageSize: _pageSize)
          : await repo.replies(
              commentId,
              page: current.data.page.page + 1,
              pageSize: _pageSize,
            );
      // 请求期间列表被 [reload] 或 [removeLocal] 换过时丢弃结果, 否则会盖掉更新的列表.
      if (ref.mounted && identical(state.value, current)) {
        state = AsyncData(
          CommentList(data: current.preview ? next : current.data.append(next)),
        );
      }
    } on AppFailure catch (e) {
      if (ref.mounted && identical(state.value, current)) {
        state = AsyncData(
          CommentList(
            data: current.data,
            moreError: e,
            preview: current.preview,
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  /// 按当前的条数重新取第 1 页: 预览时取预览条数, 展开后取一整页. 发表回复后由 [CommentWriter] 调用.
  ///
  /// 不用失效, 因为失效会退回预览, 展开时发的回复就看不到了. 失败时保留原列表.
  Future<void> reload() async {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    try {
      final first = await ref
          .read(commentRepositoryProvider)
          .replies(
            commentId,
            pageSize: current.preview ? CommentRules.replyPreview : _pageSize,
          );
      if (ref.mounted) {
        state = AsyncData(CommentList(data: first, preview: current.preview));
      }
    } on AppFailure {
      return;
    }
  }

  /// 从列表中移除 [replyId], 不发起请求. 删除成功后由 [CommentWriter] 调用.
  void removeLocal(int replyId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      CommentList(
        data: current.data.without(replyId),
        preview: current.preview,
      ),
    );
  }
}

/// 评论与回复的写操作管理器, 在发表或删除成功后同步更新已加载的列表并刷新 "我的评论".
@Riverpod(keepAlive: true)
class CommentWriter extends _$CommentWriter {
  @override
  void build() {}

  /// 发表评论, 或在 [rootId] 不为 null 时回复该评论. [replyToId] 是被回复的那条回复.
  ///
  /// 失败时抛出 [AppFailure].
  Future<CommentPosted> post(
    int dishId, {
    required String text,
    List<String> pictureKeys = const [],
    int? rootId,
    int? replyToId,
  }) async {
    final comments = ref.read(commentRepositoryProvider);
    final posted = rootId == null
        ? await comments.create(dishId, text: text, pictureKeys: pictureKeys)
        : await comments.reply(
            dishId,
            rootId,
            text: text,
            replyToId: replyToId,
          );
    ref.read(analyticsProvider).track(const CommentSuccessEvent());
    ref.invalidate(myCommentsProvider);
    if (rootId != null) {
      final replies = commentRepliesProvider(rootId);
      if (ref.exists(replies)) unawaited(ref.read(replies.notifier).reload());
      _adjustReplies(dishId, rootId, 1);
    } else {
      for (final sort in CommentSort.values) {
        ref.invalidate(dishCommentsProvider(dishId, sort));
      }
    }
    return posted;
  }

  /// 删除自己的评论或回复.
  ///
  /// 成功返回 null, 失败返回原因. 服务端答复评论不存在时同样从列表中移除.
  Future<AppFailure?> delete(Comment comment) async {
    try {
      await ref.read(commentRepositoryProvider).delete(comment.id);
    } on AppFailure catch (e) {
      if (isCommentGone(e)) removeLocal(comment);
      return e;
    }
    removeLocal(comment);
    return null;
  }

  /// 从已加载的列表中移除 [comment], 不发起请求, 并刷新 "我的评论".
  ///
  /// 删除成功后调用. 赞, 回复或删除时服务端答复评论不存在, 也调用本方法.
  void removeLocal(Comment comment) {
    final rootId = comment.rootId;
    if (rootId != null) {
      final replies = commentRepliesProvider(rootId);
      if (ref.exists(replies)) {
        ref.read(replies.notifier).removeLocal(comment.id);
      }
      _adjustReplies(comment.dishId, rootId, -1);
    } else {
      for (final sort in CommentSort.values) {
        final list = dishCommentsProvider(comment.dishId, sort);
        if (ref.exists(list)) {
          ref.read(list.notifier).removeLocal(comment.id);
        }
      }
    }
    ref.invalidate(myCommentsProvider);
  }

  /// 当回复目标已不存在时刷新对应评论线程. 由于被删除的可能是主评论 [rootId] 或被回复的子回复,
  /// 因此同时失效评论列表与回复列表缓存.
  void refreshThread(int dishId, int rootId) {
    ref.invalidate(commentRepliesProvider(rootId));
    for (final sort in CommentSort.values) {
      ref.invalidate(dishCommentsProvider(dishId, sort));
    }
  }

  void _adjustReplies(int dishId, int rootId, int delta) {
    for (final sort in CommentSort.values) {
      final list = dishCommentsProvider(dishId, sort);
      if (ref.exists(list)) {
        ref.read(list.notifier).adjustReplies(rootId, delta);
      }
    }
  }
}

// TODO: 评论不存在时服务端返回参数错误 10001, 与填写错误共用一个码. 后端提供单独的业务码后改为判断该码.
/// 判断对已有评论的操作 (赞, 回复, 删除, 举报) 失败的原因是否为评论已被删除.
bool isCommentGone(AppFailure failure) => failure.code == BizCodes.paramInvalid;

/// 评论赞的本地覆盖值, 以评论 id 为键, 用于乐观更新. 切换账号时清空.
///
/// 菜品详情和全部评论显示同一条评论时同步变化.
@Riverpod(keepAlive: true)
class CommentLikes extends _$CommentLikes {
  @override
  Map<int, CommentLike> build() {
    _myId(ref);
    return const {};
  }

  /// 切换赞的状态. 先修改覆盖值, 失败时恢复原值并返回原因.
  ///
  /// 接口不返回赞数, 请求成功后保留本地计算的计数.
  Future<AppFailure?> toggle(int commentId, CommentLike before) async {
    final liked = !before.liked;
    _set(
      commentId,
      CommentLike(
        liked: liked,
        likes: (before.likes + (liked ? 1 : -1)).clamp(0, 1 << 31),
      ),
    );
    try {
      await ref
          .read(commentRepositoryProvider)
          .setLiked(commentId, liked: liked);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) _set(commentId, before);
      return e;
    }
  }

  void _set(int id, CommentLike value) => state = {...state, id: value};
}

/// 评论表情回应的本地覆盖值, 以评论 id 为键, 用于乐观更新. 切换账号时清空.
///
/// 菜品详情和全部评论显示同一条评论时同步变化.
@Riverpod(keepAlive: true)
class CommentReactions extends _$CommentReactions {
  @override
  Map<int, List<ReactionCount>> build() {
    _myId(ref);
    return const {};
  }

  /// 点一种回应: 没选过就选上 (换掉原来那种), 选过就取消. 先改覆盖值, 成功后换成服务端返回的计数, 失败时恢复原值并返回原因.
  Future<AppFailure?> toggle(
    int commentId,
    List<ReactionCount> before,
    CommentReaction reaction,
  ) async {
    final selected = !before.any((r) => r.reaction == reaction && r.selected);
    _set(commentId, CommentRules.toggleReaction(before, reaction));
    try {
      final after = await ref
          .read(commentRepositoryProvider)
          .setReaction(commentId, reaction, selected: selected);
      if (ref.mounted) _set(commentId, after);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) _set(commentId, before);
      return e;
    }
  }

  void _set(int id, List<ReactionCount> value) => state = {...state, id: value};
}

/// "我的" 页面中的个人评论与回复列表 (不含已删除记录).
///
/// 由于 "我的" 是常驻主页面, 切换到其他主页面后保留当前结果, 仅在发表或删除后重新请求.
@Riverpod(keepAlive: true)
class MyComments extends _$MyComments {
  @override
  Future<CommentFeed> build() async {
    _myId(ref);
    return CommentFeed(
      pages: await ref
          .watch(commentRepositoryProvider)
          .mine(cancelToken: ref.cancelToken()),
    );
  }

  var _loading = false;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loading) return;
    _loading = true;
    try {
      final next = await ref
          .read(commentRepositoryProvider)
          .mine(page: current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(CommentFeed(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(CommentFeed(pages: current.pages, moreError: e));
      }
    } finally {
      _loading = false;
    }
  }
}

/// "我的评论" 的分页数据.
class const CommentFeed({
  required final Paged<MyComment> pages,
  final AppFailure? moreError,
});

/// 获取 "我的评论" 单条记录关联的菜品信息, 优先读取本地缓存, 缺失时再请求详情接口.
///
/// 由于评论记录仅包含菜品 id, 需额外获取菜名与缩略图; 离开页面后缓存保留 5 分钟.
@riverpod
Future<Dish> commentedDish(Ref ref, int dishId) async {
  ref.cacheFor(const Duration(minutes: 5));
  final foods = ref.watch(foodRepositoryProvider);
  return await foods.cachedDetail(dishId) ??
      await foods.detail(dishId, cancelToken: ref.cancelToken());
}
