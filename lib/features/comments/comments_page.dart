import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/comment_card.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 一道菜的全部评论. 顶部切换 "最有用" 和 "最新", 滚动到底部时加载下一页.
///
/// 底部常驻输入栏, 点击后进入写评论页. 右侧相机按钮进入写评论页并打开照片选择.
class CommentsPage extends ConsumerStatefulWidget {
  const new({super.key, required this.dishId});

  final int dishId;

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  var _sort = CommentSort.mostUseful;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final provider = dishCommentsProvider(widget.dishId, _sort);
    final comments = ref.watch(provider);
    final dish = ref.watch(commentedDishProvider(widget.dishId)).value;
    final list = comments.value;
    final total = list?.data.total;
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: PlainScaffold(
              title: '吃过的人说',
              onRefresh: () => pullToRefresh(
                context,
                ref,
                invalidate: [provider],
                wait: () => ref.read(provider.future),
              ),
              titleNote: dish == null
                  ? null
                  : [dish.name, ?dish.shopName].join('  '),
              slivers: [
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: EatTabs(
                          tabs: const [EatTabItem('最有用'), EatTabItem('最新')],
                          selected: _sort.index,
                          onSelected: (i) =>
                              setState(() => _sort = CommentSort.values[i]),
                        ),
                      ),
                      if (total != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '$total', style: eat.text.count),
                              const TextSpan(text: ' 条'),
                            ],
                          ),
                          style: eat.text.meta.copyWith(
                            color: eat.colors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
                if (list == null)
                  SliverToBoxAdapter(
                    child: comments.hasError && !comments.isLoading
                        ? FailureState(
                            message: (comments.error as AppFailure?)?.message,
                            onRetry: () => ref.invalidate(provider),
                          )
                        : const RowListPlaceholder(count: 4, thumbSize: 36),
                  )
                else if (list.items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: EatIcons.comment,
                        title: '还没有人说过',
                        message: '吃过的话，写一条帮同学们做参考。',
                      ),
                    ),
                  )
                else ...[
                  SliverList.separated(
                    itemCount: list.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 22),
                    itemBuilder: (_, i) => CommentCard(comment: list.items[i]),
                  ),
                  if (list.data.page.hasNext)
                    SliverToBoxAdapter(
                      child: LoadMoreTrigger(
                        generation: list.items.length,
                        failed: list.moreError != null,
                        onVisible: () => ref.read(provider.notifier).loadMore(),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        _ComposerBar(dishId: widget.dishId),
      ],
    );
  }
}

/// 底部常驻的输入栏. 外观为输入框, 点击后进入写评论页.
class _ComposerBar extends ConsumerWidget {
  const new({required this.dishId});

  final int dishId;

  Future<void> _write(
    BuildContext context,
    WidgetRef ref, {
    bool photo = false,
  }) async {
    if (!await guardAction(context, ref, Capability.comment) ||
        !context.mounted) {
      return;
    }
    await context.push(Paths.writeComment(dishId, photo: photo));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final media = MediaQuery.of(context);
    final padding = EatLayout.of(context).plainHorizontalPadding;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding,
          EatSpace.s10,
          padding,
          media.padding.bottom + EatSpace.s10,
        ),
        child: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatTappable(
                onTap: () => _write(context, ref),
                label: '写一条',
                builder: (context, _) => Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: c.mist,
                    borderRadius: const BorderRadius.all(EatRadius.pill),
                  ),
                  child: Text(
                    '吃过的话，说两句',
                    style: eat.text.body.copyWith(color: c.inkMuted),
                  ),
                ),
              ),
            ),
            EatTappable(
              onTap: () => _write(context, ref, photo: true),
              label: '带照片写一条',
              focusShape: const CircleBorder(),
              builder: (context, _) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.mist,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: EatIcon(EatIcons.camera, size: 22, color: c.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
