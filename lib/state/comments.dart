/// 评论的共享状态.
///
/// 菜品详情, 全部评论, 写评论和 "我的" 都读写同一组评论数据. 删除, 赞和发表后各页面同步变化,
/// 因此这些状态放在 `state` 而不是某个页面目录里.
library;

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/idempotency.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/domain/models/account_status.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/state/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments.g.dart';

/// 分页加载的评论列表. 加载下一页失败时记录在 [moreError] 中, 列表底部显示 "重试".
class const CommentList({
  required final CommentPage data,
  final AppFailure? moreError,
}) {
  List<Comment> get items => data.page.items;
}

int? _myId(Ref ref) =>
    ref.watch(sessionProvider.select((s) => s is SignedIn ? s.user?.id : null));

/// 一道菜的评论. 菜品详情和全部评论共用 "最有用" 一组, 菜品详情只显示前几条.
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
}

/// 一条评论下的回复, 每页 20 条, 按时间倒序加载. 显示时由 `CommentRules.chronological` 排成正序.
@riverpod
class CommentReplies extends _$CommentReplies {
  @override
  Future<CommentList> build(int commentId) async {
    ref.cacheFor(const Duration(minutes: 5));
    _myId(ref);
    return CommentList(
      data: await ref
          .watch(commentRepositoryProvider)
          .replies(commentId, cancelToken: ref.cancelToken()),
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
          .replies(commentId, page: current.data.page.page + 1);
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

  /// 从列表中移除 [replyId], 不发起请求. 删除成功后由 [CommentWriter] 调用.
  void removeLocal(int replyId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(CommentList(data: current.data.without(replyId)));
  }
}

/// 删除评论和回复. 删除成功后从已加载的各个列表中移除该条目, 并刷新 "我的评论".
@Riverpod(keepAlive: true)
class CommentWriter extends _$CommentWriter {
  @override
  void build() {}

  /// 发表评论, 或在 [rootId] 不为 null 时回复该评论. [replyToId] 是被回复的那条回复.
  ///
  /// 失败时抛出 [AppFailure]. 进入审核的评论不出现在公开列表中, 因此只在评论立即公开时刷新列表.
  Future<CommentPosted> post(
    int dishId, {
    required String text,
    List<String> pictureKeys = const [],
    int? rootId,
    int? replyToId,
    required String idempotencyKey,
  }) async {
    final comments = ref.read(commentRepositoryProvider);
    final posted = rootId == null
        ? await comments.create(
            dishId,
            text: text,
            pictureKeys: pictureKeys,
            idempotencyKey: idempotencyKey,
          )
        : await comments.reply(
            dishId,
            rootId,
            text: text,
            replyToId: replyToId,
            idempotencyKey: idempotencyKey,
          );
    ref.read(myCommentIdsProvider.notifier).remember(posted.id);
    ref.invalidate(myCommentsProvider);
    if (!posted.pending) {
      if (rootId != null) {
        ref.invalidate(commentRepliesProvider(rootId));
      } else {
        for (final sort in CommentSort.values) {
          ref.invalidate(dishCommentsProvider(dishId, sort));
        }
      }
    }
    return posted;
  }

  /// 删除自己的评论或回复. [rootId] 是回复所属评论的 id, 删除评论时为 null.
  ///
  /// 成功返回 null, 失败返回原因.
  Future<AppFailure?> delete(Comment comment, {int? rootId}) async {
    try {
      await ref
          .read(commentRepositoryProvider)
          .delete(comment.id, idempotencyKey: newIdempotencyKey());
    } on AppFailure catch (e) {
      return e;
    }
    if (rootId != null) {
      final replies = commentRepliesProvider(rootId);
      if (ref.exists(replies)) {
        ref.read(replies.notifier).removeLocal(comment.id);
      }
    } else {
      for (final sort in CommentSort.values) {
        final list = dishCommentsProvider(comment.dishId, sort);
        if (ref.exists(list)) {
          ref.read(list.notifier).removeLocal(comment.id);
        }
      }
    }
    ref.read(myCommentIdsProvider.notifier).forget(comment.id);
    ref.invalidate(myCommentsProvider);
    return null;
  }
}

// TODO: 评论列表不包含当前用户是否赞过, 每条评论单独请求一次. 列表接口提供该字段后删除本 Provider.
/// 当前用户对 [commentId] 的赞. 未登录, 封禁中或请求失败时为 null, 界面按未赞过显示列表中的赞数.
///
/// 受限会话不能调用查询赞的接口, 调用会返回无权限并触发账号状态刷新, 因此封禁中不请求.
@riverpod
Future<CommentLike?> commentLikeOf(Ref ref, int commentId) async {
  final status = ref.watch(accountStatusProvider);
  if (status is! VerifiedStatus && status is! UnverifiedStatus) return null;
  ref.cacheFor(const Duration(minutes: 5));
  try {
    return await ref
        .watch(commentRepositoryProvider)
        .likeOf(commentId, cancelToken: ref.cancelToken());
  } on AppFailure {
    return null;
  }
}

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

  /// 切换赞的状态. 先修改覆盖值, 请求成功后改为服务端返回的计数, 失败时恢复原值并返回原因.
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
      final result = await ref
          .read(commentRepositoryProvider)
          .setLiked(
            commentId,
            liked: liked,
            idempotencyKey: newIdempotencyKey(),
          );
      if (ref.mounted) _set(commentId, result);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) _set(commentId, before);
      return e;
    }
  }

  void _set(int id, CommentLike value) => state = {...state, id: value};
}

// TODO: 公开评论不包含作者 id, 客户端用 "我的评论" 第一页的 id 判断自己的评论, 更早的评论不显示 "删除". 列表接口提供作者 id 后改为比较作者 id.
/// 当前用户写过的评论和回复的 id, 用于在 "更多" 中显示 "删除" 还是 "举报".
///
/// 取 "我的评论" 最近 100 条. 本次启动后发表的评论在发表成功时加入.
@Riverpod(keepAlive: true)
class MyCommentIds extends _$MyCommentIds {
  @override
  Future<Set<int>> build() async {
    if (_myId(ref) == null) return const {};
    final page = await ref.watch(commentRepositoryProvider).mine(pageSize: 100);
    return {
      for (final c in page.items)
        if (c.status != CommentStatus.deleted) c.id,
    };
  }

  void remember(int id) {
    final current = state.value;
    if (current != null) state = AsyncData({...current, id});
  }

  void forget(int id) {
    final current = state.value;
    if (current != null) state = AsyncData({...current}..remove(id));
  }
}

/// "我的" 中的评论分栏: 我写过的评论和回复, 不含已删除和被新版本取代的.
///
/// "我的" 是常驻的主页面, 切换到其他主页面后保留结果. 发表和删除后重新请求.
@Riverpod(keepAlive: true)
class MyComments extends _$MyComments {
  @override
  Future<CommentFeed> build() async {
    _myId(ref);
    return CommentFeed(
      pages: _visible(
        await ref
            .watch(commentRepositoryProvider)
            .mine(cancelToken: ref.cancelToken()),
      ),
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
        state = AsyncData(
          CommentFeed(pages: current.pages.append(_visible(next))),
        );
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(CommentFeed(pages: current.pages, moreError: e));
      }
    } finally {
      _loading = false;
    }
  }

  static Paged<MyComment> _visible(Paged<MyComment> page) => Paged(
    items: [
      for (final c in page.items)
        if (c.status != CommentStatus.deleted &&
            c.status != CommentStatus.superseded)
          c,
    ],
    page: page.page,
    hasNext: page.hasNext,
  );
}

/// "我的评论" 的分页数据.
class const CommentFeed({
  required final Paged<MyComment> pages,
  final AppFailure? moreError,
});

/// "我的评论" 一行要显示的菜: 先用本地缓存的详情, 没有缓存时请求.
///
/// 评论记录只带菜的 id, 菜名和缩略图要另外获取. 离开页面后保留 5 分钟.
@riverpod
Future<Dish> commentedDish(Ref ref, int dishId) async {
  ref.cacheFor(const Duration(minutes: 5));
  final foods = ref.watch(foodRepositoryProvider);
  return await foods.cachedDetail(dishId) ??
      await foods.detail(dishId, cancelToken: ref.cancelToken());
}
