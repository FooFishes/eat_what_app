import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/plain_scaffold.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/features/system/comment_card.dart';
import 'package:eat/features/system/comment_composer.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 菜品的全部评论页, 支持切换 "最有用" 与 "最新" 排序并在触底时加载下一页.
///
/// 顶部是写评论的输入框 ([CommentComposer]), 就地展开书写, 不跳新页面.
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
    return PlainScaffold(
      title: '吃过的人说',
      onRefresh: () => pullToRefresh(
        context,
        ref,
        invalidate: [provider],
        wait: () => ref.read(provider.future),
      ),
      titleNote: dish == null ? null : [dish.name, ?dish.shopName].join('  '),
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
                  style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverToBoxAdapter(child: CommentComposer(dishId: widget.dishId)),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s20)),
        if (list == null)
          SliverToBoxAdapter(
            child: comments.hasError && !comments.isLoading
                ? FailureState(
                    error: comments.error,
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
            separatorBuilder: (_, _) => const CommentGap(),
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
    );
  }
}
