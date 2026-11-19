import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/widgets/follow_button.dart';
import 'package:eat/features/profile/widgets/profile_stage.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:eat/state/social.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 粉丝和关注列表页, 分为两个分栏, 每行展示头像和昵称, 点击行进入他人主页.
///
/// 只有我自己的列表在每行右侧放关注按钮, 关注关系取自列表数据; 他人的列表不显示与我的关系.
///
/// 对方未公开某个列表时, 该分栏展示未公开提示; 自己的列表始终可见.
class FollowsPage extends ConsumerStatefulWidget {
  const new({super.key, required this.userId, required this.initial});

  final int userId;
  final FollowListKind initial;

  @override
  ConsumerState<FollowsPage> createState() => _FollowsPageState();
}

class _FollowsPageState extends ConsumerState<FollowsPage> {
  late var _kind = widget.initial;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.user?.id : null),
    );
    final isMe = me == widget.userId;
    final profileValue = ref.watch(userProfileProvider(widget.userId));
    final profile = profileValue.value;
    // 查看他人时, 获取对方资料并确认列表公开后才请求列表.
    final visible = switch ((isMe, profile)) {
      (true, _) => true,
      (false, null) => null,
      (false, final p?) => switch (_kind) {
        FollowListKind.fans => p.fansVisible,
        FollowListKind.followings => p.followingsVisible,
      },
    };
    final name = isMe ? '我' : profile?.nickname ?? '';
    return PlainScaffold(
      title: isMe ? '粉丝和关注' : '$name的粉丝和关注',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [
          userProfileProvider(widget.userId),
          followListProvider(widget.userId, _kind),
        ],
        wait: () => ref.read(followListProvider(widget.userId, _kind).future),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: [
              EatTabItem('粉丝', count: profile?.fans),
              EatTabItem('关注', count: profile?.followings),
            ],
            selected: _kind.index,
            onSelected: (i) => setState(() => _kind = FollowListKind.values[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        switch (visible) {
          true => _UserList(
            userId: widget.userId,
            kind: _kind,
            me: me,
            name: name,
          ),
          false => SliverToBoxAdapter(
            child: _Hidden(name: name, kind: _kind),
          ),
          null => SliverToBoxAdapter(
            child: switch (profileValue) {
              AsyncValue(:final error?, isLoading: false)
                  when isMissingUser(error) =>
                const _Missing(),
              AsyncValue(:final error?, isLoading: false) => FailureState(
                error: error,
                onRetry: () =>
                    ref.invalidate(userProfileProvider(widget.userId)),
              ),
              _ => const RowListPlaceholder(
                count: 6,
                thumbSize: EatSize.avatar,
              ),
            },
          ),
        },
      ],
    );
  }
}

class _UserList extends ConsumerWidget {
  const new({
    required this.userId,
    required this.kind,
    required this.me,
    required this.name,
  });

  final int userId;
  final FollowListKind kind;
  final int? me;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = followListProvider(userId, kind);
    final value = ref.watch(provider);
    final data = value.value;
    if (data == null) {
      if (value.hasError && !value.isLoading) {
        if (isHiddenList(value.error)) {
          return SliverToBoxAdapter(
            child: _Hidden(name: name, kind: kind),
          );
        }
        if (isMissingUser(value.error)) {
          return const SliverToBoxAdapter(child: _Missing());
        }
        return SliverToBoxAdapter(
          child: FailureState(
            error: value.error,
            onRetry: () => ref.invalidate(provider),
          ),
        );
      }
      return const SliverToBoxAdapter(
        child: RowListPlaceholder(count: 6, thumbSize: EatSize.avatar),
      );
    }
    final users = data.pages.items;
    if (users.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            icon: EatIcons.follow,
            title: switch (kind) {
              FollowListKind.fans => '还没有粉丝',
              FollowListKind.followings => '还没关注任何人',
            },
            message: switch (kind) {
              FollowListKind.fans => '多发几道好菜，让更多同学认识你。',
              FollowListKind.followings => '点击菜品的上传者，即可进入对方主页关注。',
            },
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
          itemBuilder: (context, i) =>
              _UserRow(user: users[i], me: me, showFollow: me == userId),
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: users.length,
              failed: data.moreError != null,
              onVisible: () => ref.read(provider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const new({required this.user, required this.me, required this.showFollow});

  final UserBrief user;
  final int? me;

  /// 是否显示关注按钮. 只有我自己的列表显示, 他人的列表不看与我的关系.
  final bool showFollow;

  @override
  Widget build(BuildContext context) {
    final name = user.nickname ?? '同学';
    final isMe = user.id == me;
    return EatListRow(
      leading: EatAvatar(
        name: name,
        color: avatarColorOf(user.id),
        image: networkImage(user.avatarUrl, width: EatSize.avatar),
      ),
      title: Text(name),
      onTap: () =>
          isMe ? context.go(Paths.me) : context.push(Paths.user(user.id)),
      action: isMe || !showFollow
          ? null
          : FollowButton(
              userId: user.id,
              followedByMe: user.followedByMe,
              followsMe: user.followsMe,
            ),
    );
  }
}

/// 用户不存在.
class _Missing extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 40),
    child: EmptyState(icon: EatIcons.me, title: '该用户不存在'),
  );
}

/// 对方没有公开该列表.
class _Hidden extends StatelessWidget {
  const new({required this.name, required this.kind});

  final String name;
  final FollowListKind kind;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: EmptyState(
      icon: EatIcons.lock,
      title: '对方未公开',
      message: switch (kind) {
        FollowListKind.fans => '「$name」未公开粉丝列表',
        FollowListKind.followings => '「$name」未公开关注列表',
      },
    ),
  );
}
