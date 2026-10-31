import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/rules/notice_rules.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/unread_count.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inbox_page.g.dart';

/// 消息页的数据：已经拉到的几页，以及下一页是不是加载失败了（失败时列表底部换成「重试」）。
typedef InboxPages = ({Paged<Notice> pages, bool moreFailed});

/// 消息列表，滑到底接着加载；点一条、全部已读时先改本地再告诉服务端。
@riverpod
class Inbox extends _$Inbox {
  var _loadingMore = false;

  @override
  Future<InboxPages> build() async {
    final pages = await ref
        .watch(notificationRepositoryProvider)
        .list(cancelToken: ref.cancelToken());
    return (pages: pages, moreFailed: false);
  }

  Future<void> loadMore() async {
    final current = state.value?.pages;
    if (current == null || !current.hasNext || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(notificationRepositoryProvider)
          .list(page: current.page + 1);
      if (ref.mounted) {
        state = AsyncData((pages: current.append(next), moreFailed: false));
      }
    } on AppFailure {
      if (ref.mounted) state = AsyncData((pages: current, moreFailed: true));
    } finally {
      _loadingMore = false;
    }
  }

  void markRead(Notice notice) {
    final current = state.value?.pages;
    if (current == null || notice.read) return;
    state = AsyncData((
      pages: _replace(current, (n) => n.id == notice.id),
      moreFailed: state.value!.moreFailed,
    ));
    ref.read(unreadCountProvider.notifier).markRead(1);
    unawaited(
      ref
          .read(notificationRepositoryProvider)
          .read(notice.id)
          .catchError((_) {}),
    );
  }

  Future<AppFailure?> readAll() async {
    final current = state.value?.pages;
    if (current == null) return null;
    try {
      await ref.read(notificationRepositoryProvider).readAll();
    } on AppFailure catch (e) {
      return e;
    }
    if (!ref.mounted) return null;
    state = AsyncData((
      pages: _replace(current, (_) => true),
      moreFailed: state.value?.moreFailed ?? false,
    ));
    ref.read(unreadCountProvider.notifier).refresh();
    return null;
  }

  static Paged<Notice> _replace(
    Paged<Notice> page,
    bool Function(Notice) test,
  ) => Paged(
    items: [
      for (final n in page.items)
        test(n)
            ? Notice(
                id: n.id,
                actorId: n.actorId,
                actorName: n.actorName,
                actorAvatar: n.actorAvatar,
                type: n.type,
                targetType: n.targetType,
                targetId: n.targetId,
                data: n.data,
                read: true,
                createdAt: n.createdAt,
              )
            : n,
    ],
    page: page.page,
    hasNext: page.hasNext,
  );
}

/// 消息（`G-Inbox`）：大标题旁边写未读数，右上角「全部已读」；按「今天」「本周」「更早」分组。
///
/// 接口还不能按分栏过滤、也不合并同类消息（现状差距 2.1）：只有「全部」可用，其余分栏带「待接入」，
/// 一条一行。他人主页在阶段六做，关注消息点了只算读过。
class InboxPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final inbox = ref.watch(inboxProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final page = inbox.value?.pages;
    return PlainScaffold(
      title: '消息',
      subtitle: unread > 0 ? '$unread 条未读' : null,
      actions: [
        EatTappable(
          onTap: unread == 0
              ? null
              : () async {
                  final failure = await ref
                      .read(inboxProvider.notifier)
                      .readAll();
                  if (failure != null && context.mounted) {
                    showToast(context, failure.message);
                  }
                },
          label: '全部已读',
          builder: (context, _) => SizedBox(
            height: EatSize.touch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '全部已读',
                  style: eat.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unread == 0 ? eat.colors.disabledFg : eat.colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: const [
              EatTabItem('全部'),
              EatTabItem('评论', pending: true),
              EatTabItem('赞和收藏', pending: true),
              EatTabItem('关注', pending: true),
              EatTabItem('系统', pending: true),
            ],
            selected: 0,
            onSelected: (i) {
              if (i > 0) showPending(context, PendingFeature.comments);
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        if (page == null)
          SliverToBoxAdapter(
            child: inbox.hasError && !inbox.isLoading
                ? FailureState(
                    message: (inbox.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(inboxProvider),
                  )
                : const RowListPlaceholder(count: 6, thumbSize: EatSize.avatar),
          )
        else if (page.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: EatIcons.bell,
                title: '还没有消息',
                message: '有人赞了、收藏了你上传的菜，会在这里告诉你。',
              ),
            ),
          )
        else ...[
          _NoticeList(notices: page.items),
          if (page.hasNext)
            SliverToBoxAdapter(
              child: LoadMoreTrigger(
                generation: page.items.length,
                failed: inbox.value!.moreFailed,
                onVisible: () => ref.read(inboxProvider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

class _NoticeList extends ConsumerWidget {
  const new({required this.notices});

  final List<Notice> notices;

  /// 「今天」「本周」「更早」。
  static String _groupOf(DateTime time, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (!time.isBefore(today)) return '今天';
    final week = today.subtract(Duration(days: today.weekday - 1));
    return time.isBefore(week) ? '更早' : '本周';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = clock.now();
    final rows = <Widget>[];
    String? group;
    for (final notice in notices) {
      final g = _groupOf(notice.createdAt, now);
      if (g != group) {
        group = g;
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 10, bottom: 2),
            child: ListGroupTitle(g),
          ),
        );
      }
      rows.add(_NoticeRow(notice: notice, now: now));
    }
    return SliverList.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => rows[i],
    );
  }
}

class _NoticeRow extends ConsumerWidget {
  const new({required this.notice, required this.now});

  final Notice notice;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final target = NoticeRules.targetOf(notice);
    return EatListRow(
      unread: !notice.read,
      leading: EatAvatar(
        name: notice.actorName,
        color: StageColor.values[notice.actorId % StageColor.values.length],
        image: networkImage(notice.actorAvatar, width: EatSize.avatar),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: notice.actorName),
            TextSpan(
              text: ' ${NoticeRules.sentenceOf(notice)}',
              style: eat.text.body.copyWith(color: eat.colors.ink),
            ),
          ],
        ),
      ),
      lines: [Text(TimeFormat.relative(notice.createdAt, now))],
      onTap: () {
        ref.read(inboxProvider.notifier).markRead(notice);
        switch (target) {
          case DishTarget(:final dishId):
            context.push(Paths.dish(dishId));
          case MeTarget():
            context.go(Paths.me);
          case UserTarget() || NoTarget():
        }
      },
    );
  }
}
