import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/people.dart';
import 'package:eat/features/settings/settings_providers.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 屏蔽的人. 每行可以解除屏蔽, 点击一行进入对方主页. 对方已注销时显示 "已注销用户", 不能点.
class BlockedPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final value = ref.watch(blockedUsersProvider);
    final data = value.value;
    return PlainScaffold(
      title: '屏蔽的人',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [blockedUsersProvider],
        wait: () => ref.read(blockedUsersProvider.future),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: EatSpace.s20),
            child: Text(
              '屏蔽后，你将看不到对方的评论、回复与上传的菜，也不会收到对方的互动通知，'
              '对方也无法再关注你。',
              style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
            ),
          ),
        ),
        if (data == null)
          SliverToBoxAdapter(
            child: value.hasError && !value.isLoading
                ? FailureState(
                    message: (value.error as AppFailure?)?.message,
                    onRetry: () => ref.invalidate(blockedUsersProvider),
                  )
                : const RowListPlaceholder(count: 3, thumbSize: EatSize.avatar),
          )
        else if (data.pages.items.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: EmptyState(
                icon: EatIcons.block,
                title: '没有屏蔽任何人',
                message: '在别人主页右上角的「更多」里可以屏蔽',
              ),
            ),
          )
        else ...[
          SliverList.separated(
            itemCount: data.pages.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: EatSpace.s16),
            itemBuilder: (context, i) => _BlockedRow(user: data.pages.items[i]),
          ),
          if (data.pages.hasNext)
            SliverToBoxAdapter(
              child: LoadMoreTrigger(
                generation: data.pages.items.length,
                failed: data.moreError != null,
                onVisible: () =>
                    ref.read(blockedUsersProvider.notifier).loadMore(),
              ),
            ),
        ],
      ],
    );
  }
}

class _BlockedRow extends ConsumerStatefulWidget {
  const new({required this.user});

  final UserBrief user;

  @override
  ConsumerState<_BlockedRow> createState() => _BlockedRowState();
}

class _BlockedRowState extends ConsumerState<_BlockedRow> {
  var _busy = false;

  Future<void> _unblock() async {
    setState(() => _busy = true);
    try {
      await ref.read(blockedUsersProvider.notifier).unblock(widget.user);
      if (mounted) showToast(context, '已解除屏蔽');
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(
        context,
        e.kind == FailureKind.unknown ? '解除屏蔽失败，请重试' : e.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name = user.nickname ?? '已注销用户';
    return EatListRow(
      leading: EatAvatar(
        name: name,
        color: StageColor.values[user.id % StageColor.values.length],
      ),
      title: Text(name),
      onTap: user.nickname == null
          ? null
          : () => context.push(Paths.user(user.id)),
      action: EatButton.mist(
        '解除屏蔽',
        height: 36,
        loading: _busy,
        onPressed: _unblock,
      ),
    );
  }
}
