import 'package:eat/core/failure/app_failure.dart';
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

// TODO: 粉丝和关注列表不返回与我的关注关系, 每一行单独请求对方的资料来决定按钮文字. 列表接口返回关注关系后改用列表数据.
/// 粉丝和关注列表. 两个分栏, 每行是头像, 昵称和关注按钮, 点击一行进入他人主页.
///
/// 对方未公开某个列表时, 该分栏显示 "对方没有公开". 自己的列表总是可见.
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
            child: profileValue.hasError && !profileValue.isLoading
                ? FailureState(
                    message: (profileValue.error as AppFailure?)?.message,
                    onRetry: () =>
                        ref.invalidate(userProfileProvider(widget.userId)),
                  )
                : const RowListPlaceholder(count: 6, thumbSize: EatSize.avatar),
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
        return SliverToBoxAdapter(
          child: FailureState(
            message: (value.error as AppFailure?)?.message,
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
              FollowListKind.followings => '在菜品详情点上传者，可以进主页关注。',
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
          itemBuilder: (context, i) => _UserRow(user: users[i], me: me),
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

class _UserRow extends ConsumerWidget {
  const new({required this.user, required this.me});

  final UserBrief user;
  final int? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.nickname ?? '同学';
    final isMe = user.id == me;
    final profile = isMe ? null : ref.watch(userProfileProvider(user.id));
    return EatListRow(
      leading: EatAvatar(
        name: name,
        color: avatarColorOf(user.id),
        image: networkImage(user.avatarUrl, width: EatSize.avatar),
      ),
      title: Text(name),
      onTap: () =>
          isMe ? context.go(Paths.me) : context.push(Paths.user(user.id)),
      action: switch (profile?.value) {
        final profile? => FollowButton(profile: profile),
        null when isMe => null,
        null => const Skeleton(width: 72, height: 36, radius: EatRadius.pill),
      },
    );
  }
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
