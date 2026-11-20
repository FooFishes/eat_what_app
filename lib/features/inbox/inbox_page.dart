import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/comment/comment_repository.dart';
import 'package:eat/data/notification/notification_api.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/models/notice.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/domain/rules/notice_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/social.dart';
import 'package:eat/state/unread_count.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inbox_page.g.dart';

/// 消息页的数据: 已获取的分页, 以及下一页是否加载失败.
///
/// 下一页加载失败时, 列表底部显示 "重试".
typedef InboxPages = ({Paged<Notice> pages, bool moreFailed});

/// 一个分栏的消息列表, 滚动到底部时加载下一页. 切换分栏时重新请求.
///
/// 点击一行和全部已读时, 先修改本地状态, 再通知服务端.
@riverpod
class Inbox extends _$Inbox {
  var _loadingMore = false;

  @override
  Future<InboxPages> build(NoticeColumn column) async {
    final pages = await ref
        .watch(notificationRepositoryProvider)
        .list(column, cancelToken: ref.cancelToken());
    return (pages: pages, moreFailed: false);
  }

  Future<void> loadMore() async {
    final current = state.value?.pages;
    if (current == null || !current.hasNext || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(notificationRepositoryProvider)
          .list(column, page: current.page + 1);
      if (ref.mounted) {
        state = AsyncData((pages: current.append(next), moreFailed: false));
      }
    } on AppFailure {
      if (ref.mounted) state = AsyncData((pages: current, moreFailed: true));
    } finally {
      _loadingMore = false;
    }
  }

  /// 将单条消息标为已读. 请求失败时不回滚本地状态, 下次进入消息页时以服务端数据为准.
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

  /// 把当前分栏的全部消息标为已读, 含未加载的页. 成功返回 null, 失败返回原因.
  ///
  /// 成功后重新请求未读数, 因为其他分栏可能仍有未读.
  Future<AppFailure?> readAll() async {
    final current = state.value?.pages;
    if (current == null) return null;
    try {
      await ref.read(notificationRepositoryProvider).readAll(column);
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
    items: [for (final n in page.items) test(n) ? n.markedRead() : n],
    page: page.page,
    hasNext: page.hasNext,
  );
}

/// 消息页.
///
/// - 大标题旁显示未读数, 右上角为 "全部已读".
/// - 分栏: 全部, 评论, 赞和收藏, 关注, 系统.
/// - 消息按 "今天", "本周", "更早" 分组. 同一对象, 同一类互动在同一天的消息合并为一行.
class InboxPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  var _column = NoticeColumn.all;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final provider = inboxProvider(_column);
    final inbox = ref.watch(provider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final page = inbox.value?.pages;
    return PlainScaffold(
      title: '消息',
      titleNote: unread > 0 ? '$unread 条未读' : null,
      onRefresh: () {
        ref.read(unreadCountProvider.notifier).refresh();
        return pullToRefresh(
          context,
          ref,
          invalidate: [provider],
          wait: () => ref.read(provider.future),
        );
      },
      actions: [
        EatTappable(
          onTap: unread == 0
              ? null
              : () async {
                  final failure = await ref.read(provider.notifier).readAll();
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
            tabs: [
              for (final column in NoticeColumn.values)
                EatTabItem(column.label),
            ],
            selected: _column.index,
            onSelected: (i) => setState(() => _column = NoticeColumn.values[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        if (page == null)
          SliverToBoxAdapter(
            child: inbox.hasError && !inbox.isLoading
                ? FailureState(
                    error: inbox.error,
                    onRetry: () => ref.invalidate(provider),
                  )
                : const RowListPlaceholder(count: 6, thumbSize: EatSize.avatar),
          )
        else if (page.items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _Empty(column: _column),
            ),
          )
        else ...[
          _NoticeList(column: _column, notices: page.items),
          if (page.hasNext)
            SliverToBoxAdapter(
              child: LoadMoreTrigger(
                generation: page.items.length,
                failed: inbox.value!.moreFailed,
                onVisible: () => ref.read(provider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

/// 分栏中没有消息时的空状态.
class _Empty extends StatelessWidget {
  const new({required this.column});

  final NoticeColumn column;

  @override
  Widget build(BuildContext context) => switch (column) {
    NoticeColumn.all => const EmptyState(
      icon: EatIcons.bell,
      title: '还没有消息',
      message: '有新的赞、收藏、评论或系统通知时，会在这里告诉你。',
    ),
    NoticeColumn.comments => const EmptyState(
      icon: EatIcons.comment,
      title: '还没有评论',
      message: '有新的评论或回复时，会在这里告诉你。',
    ),
    NoticeColumn.likes => const EmptyState(
      icon: EatIcons.heart,
      title: '还没有赞和收藏',
      message: '有人赞了、收藏了你上传的菜，会在这里告诉你。',
    ),
    NoticeColumn.follows => const EmptyState(
      icon: EatIcons.follow,
      title: '还没有人关注你',
      message: '有同学关注你时，会在这里告诉你。',
    ),
    NoticeColumn.system => const EmptyState(
      icon: EatIcons.bell,
      title: '还没有系统消息',
      message: '反馈和举报的处理结果、公告会在这里通知你。',
    ),
  };
}

class _NoticeList extends StatelessWidget {
  const new({required this.column, required this.notices});

  final NoticeColumn column;
  final List<Notice> notices;

  @override
  Widget build(BuildContext context) {
    final now = clock.now();
    final hairline = context.eat.colors.hairline;
    final rows = <Widget>[];
    String? group;
    for (final notice in notices) {
      final g = NoticeRules.groupOf(notice.latestAt, now);
      final first = g != group;
      if (first) {
        group = g;
        rows.add(
          Padding(
            padding: EdgeInsets.only(
              top: rows.isEmpty ? 0 : EatSpace.s20,
              bottom: EatSpace.s4,
            ),
            child: ListGroupTitle(g),
          ),
        );
      }
      rows.add(
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: first
              ? const BoxDecoration()
              : BoxDecoration(
                  border: Border(top: BorderSide(color: hairline)),
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EatSpace.s14),
            child: _NoticeRow(column: column, notice: notice, now: now),
          ),
        ),
      );
    }
    return SliverList.list(children: rows);
  }
}

/// 单条消息行. 有互动者的消息用 [_InteractionRow], 系统消息用 [_SystemRow].
///
/// 评论赞的卡片只带评论 id, 点击后先读取这条评论再进菜品详情; 读取期间再点不重复请求.
class _NoticeRow extends ConsumerStatefulWidget {
  const new({required this.column, required this.notice, required this.now});

  final NoticeColumn column;
  final Notice notice;
  final DateTime now;

  @override
  ConsumerState<_NoticeRow> createState() => _NoticeRowState();
}

class _NoticeRowState extends ConsumerState<_NoticeRow> {
  var _resolving = false;

  @override
  Widget build(BuildContext context) {
    void open(NoticeTarget target) {
      ref.read(inboxProvider(widget.column).notifier).markRead(widget.notice);
      unawaited(_open(target));
    }

    return widget.notice.actors.isEmpty
        ? _SystemRow(notice: widget.notice, now: widget.now, onOpen: open)
        : _InteractionRow(notice: widget.notice, now: widget.now, onOpen: open);
  }

  Future<void> _open(NoticeTarget target) async {
    switch (target) {
      case DishTarget(:final dishId, :final comment):
        await context.push(Paths.dish(dishId, comment: comment));
      case CommentTarget(:final commentId):
        await _openComment(commentId);
      case UserTarget(:final userId):
        await context.push(Paths.user(userId));
      case ShopTarget(:final shopId):
        await context.push(Paths.shop(shopId));
      case CaseTarget(:final caseId):
        await context.push(Paths.myFeedbackCase(caseId));
      case DevicesTarget():
        await context.push(Paths.settingsDevices);
      case MyFansTarget():
        final me = ref.read(sessionProvider);
        if (me case SignedIn(user: final user?)) {
          await context.push(Paths.follows(user.id, fans: true));
        }
      case NoTarget():
    }
  }

  /// 菜品详情只能滚到根评论, 因此回复取其根评论.
  Future<void> _openComment(int commentId) async {
    if (_resolving) return;
    _resolving = true;
    final Comment comment;
    try {
      comment = await ref.read(commentRepositoryProvider).detail(commentId);
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (isCommentGone(e)) {
        showToast(context, '这条评论已删除或不可见');
      } else if (e.kind != FailureKind.cancelled) {
        showToast(context, e.message);
      }
      return;
    } finally {
      _resolving = false;
    }
    if (!mounted) return;
    await context.push(
      Paths.dish(comment.dishId, comment: comment.rootId ?? comment.id),
    );
  }
}

/// 互动消息行: 未读圆点, 对方头像, 一句话和时间, 关注消息右侧附带 "回关" 按钮.
///
/// 点整行标为已读并跳转到对应目标页 (若有). 不跳转的行在读屏时提示点击结果为 "标为已读", 避免无障碍用户误判是否会离开当前页, 且已读后设为不可点击.
class _InteractionRow extends StatelessWidget {
  const new({required this.notice, required this.now, required this.onOpen});

  final Notice notice;
  final DateTime now;
  final void Function(NoticeTarget) onOpen;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final target = NoticeRules.targetOf(notice);
    final reply = NoticeRules.replyOf(notice);
    final followBack = NoticeRules.followBackUserOf(notice);
    final actor = notice.actors.first;
    return EatListRow(
      unread: !notice.read,
      leading: EatAvatar(
        name: actor.name,
        color: StageColor.values[actor.id % StageColor.values.length],
        image: networkImage(actor.avatar, width: EatSize.avatar),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: NoticeRules.actorsOf(notice)),
            TextSpan(
              text: ' ${NoticeRules.sentenceOf(notice)}',
              style: eat.text.body.copyWith(color: eat.colors.ink),
            ),
          ],
        ),
      ),
      lines: [
        if (reply != null) Text('回复：$reply'),
        Text(TimeFormat.relative(notice.latestAt, now)),
      ],
      action: followBack == null ? null : _FollowBack(userId: followBack),
      onTap: target is NoTarget && notice.read ? null : () => onOpen(target),
      tapHint: target is NoTarget ? '标为已读' : null,
    );
  }
}

/// 系统消息行, 显示全文.
///
/// - 第一行是标题, 时间靠右; 下面是公告正文, 封禁或删除的原因和期限.
/// - 有跳转目标时, 详情 (设备名, 运营回复) 放进标题下方的 [_DetailBlock], 点这一块才跳转; 点标题和正文只标为已读.
/// - 没有详情块时, 标题和正文与图标垂直居中; 有详情块时标题与图标顶端对齐, 详情块紧跟标题, 不留出图标下方的空白.
class _SystemRow extends StatelessWidget {
  const new({required this.notice, required this.now, required this.onOpen});

  final Notice notice;
  final DateTime now;
  final void Function(NoticeTarget) onOpen;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final target = NoticeRules.targetOf(notice);
    final hasDetail = NoticeRules.actionOf(notice) != null;
    final content = NoticeRules.contentOf(notice);
    final reply = NoticeRules.replyOf(notice);
    final body = [
      if (!hasDetail && content != null) content,
      if (!hasDetail && reply != null) '回复：$reply',
      if (notice.detail case BanDetail(:final until)) banTerm(until, now),
    ];
    final muted = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            NoticeRules.sentenceOf(notice),
            style: eat.text.body.copyWith(
              fontWeight: FontWeight.w600,
              color: eat.colors.ink,
            ),
          ),
        ),
        const SizedBox(width: EatSpace.s8),
        Text(TimeFormat.relative(notice.latestAt, now), style: muted),
      ],
    );
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        title,
        for (final line in body) Text(line, style: muted),
      ],
    );
    final text = hasDetail
        ? textBlock
        : EatTappable(
            onTap: notice.read && target is NoTarget
                ? null
                : () => onOpen(target),
            button: false,
            tapHint: target is NoTarget ? '标为已读' : null,
            focusShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(EatRadius.thumb),
            ),
            builder: (context, _) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: EatSize.avatar),
              child: Align(alignment: Alignment.centerLeft, child: textBlock),
            ),
          );
    final row = Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SystemIcon(kind: notice.kind, detail: notice.detail),
            const SizedBox(width: EatSpace.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  if (hasDetail) ...[
                    const SizedBox(height: EatSpace.s8),
                    _DetailBlock(notice: notice, onTap: () => onOpen(target)),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!notice.read)
          const Positioned(
            left: -13,
            top: (EatSize.avatar - 7) / 2,
            child: UnreadDot(),
          ),
      ],
    );
    if (!hasDetail || notice.read) return row;
    // 有详情块时, 点详情块以外的地方只标为已读. 读屏用户可以点详情块或 "全部已读", 因此这里不提供语义动作, 也不和详情块的语义合并.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () => onOpen(const NoTarget()),
      child: row,
    );
  }
}

/// 系统消息的详情块: `mist` 底的方圆角块, 左侧图标, 中间是详情和说明, 右侧箭头. 整块是跳转入口.
///
/// 新设备登录显示设备名和 "可以在登录设备里让它下线"; 处理结果显示运营回复 (有的话) 和 "查看处理详情".
class _DetailBlock extends StatelessWidget {
  const new({required this.notice, required this.onTap});

  final Notice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final action = NoticeRules.actionOf(notice)!;
    final (icon, primary, secondary) = switch (notice.detail) {
      NewDeviceDetail(:final platform) => (
        platform == 'WEB' ? EatIcons.computer : EatIcons.phone,
        NoticeRules.contentOf(notice),
        NoticeRules.noteOf(notice) ?? action,
      ),
      _ => (EatIcons.document, NoticeRules.replyOf(notice), action),
    };
    return EatTappable(
      onTap: onTap,
      label: [?primary, action].join('，'),
      focusShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(EatRadius.thumb),
      ),
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: EatSize.touch),
        padding: const EdgeInsets.symmetric(
          horizontal: EatSpace.s14,
          vertical: EatSpace.s10,
        ),
        decoration: BoxDecoration(
          color: c.mist,
          borderRadius: const BorderRadius.all(EatRadius.thumb),
        ),
        child: Row(
          children: [
            EatIcon(icon, size: 20, color: c.ink),
            const SizedBox(width: EatSpace.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (primary != null)
                    Text(
                      primary,
                      style: eat.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  Text(
                    secondary,
                    style: eat.text.meta.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: EatSpace.s8),
            EatIcon(EatIcons.chevronRight, size: 18, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// 系统消息的头像位置: `mist` 圆底上的图标.
class _SystemIcon extends StatelessWidget {
  const new({required this.kind, required this.detail});

  final NoticeKind kind;
  final NoticeDetail? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    final icon = switch ((kind, detail)) {
      (NoticeKind.announcement, _) => EatIcons.announce,
      (_, CaseResultDetail(kind: CaseKind.report)) => EatIcons.report,
      (NoticeKind.caseResult, _) => EatIcons.feedback,
      (NoticeKind.accountBanned, _) => EatIcons.block,
      (NoticeKind.newDeviceLogin, _) => EatIcons.shield,
      (NoticeKind.contentRemoved, _) => EatIcons.delete,
      _ => EatIcons.bell,
    };
    return Container(
      width: EatSize.avatar,
      height: EatSize.avatar,
      decoration: BoxDecoration(color: c.mist, shape: BoxShape.circle),
      child: Center(child: EatIcon(icon, size: 20, color: c.ink)),
    );
  }
}

// TODO: 关注消息不含与对方的关注关系, 每个可回关的行单独请求对方的资料来决定按钮文字. 卡片返回关注关系后改用卡片数据.
/// 关注消息右侧的按钮: 未关注对方时为实心 "回关", 已关注时为次要样式的 "已互关", 点击取消关注.
///
/// 对方的资料返回前按未关注显示. 发出关注消息的人一定关注了当前用户, 因此不会出现 "关注" 和 "已关注".
class _FollowBack extends ConsumerWidget {
  const new({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(userId)).value;
    final override = ref.watch(followsProvider.select((m) => m[userId]));
    final followed = override ?? profile?.followedByMe ?? false;
    final state = FollowState.of(followedByMe: followed, followsMe: true);
    Future<void> onPressed() async {
      final following = !followed;
      final capability = following ? Capability.follow : Capability.unfollow;
      if (!await guardAction(context, ref, capability)) return;
      final failure = await ref
          .read(followsProvider.notifier)
          .set(userId, following: following);
      if (failure == null || !context.mounted) return;
      if (following && failure.code == BizCodes.stateNotAllowed) {
        showToast(context, '无法关注对方');
      } else {
        await reportActionFailure(
          context,
          ref,
          failure,
          capability: capability,
          fallback: following ? '关注失败，请重试' : '取消关注失败，请重试',
        );
      }
    }

    const height = 36.0;
    return followed
        ? EatButton.mist(state.label, height: height, onPressed: onPressed)
        : EatButton.solid(state.label, height: height, onPressed: onPressed);
  }
}
