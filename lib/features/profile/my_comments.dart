import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/format/time_format.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_list_row.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/domain/models/comment.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/comments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "我的" 中的评论分栏: 我写过的评论和回复. 每行是菜的缩略图, 菜名, 我说的话和时间.
///
/// 点击进入菜品详情并滚动到该评论. 回复滚动到所属的评论.
class MyCommentsSliver extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myCommentsProvider);
    final data = value.value;
    if (data == null) {
      return SliverToBoxAdapter(
        child: value.hasError && !value.isLoading
            ? FailureState(
                message: (value.error as AppFailure?)?.message,
                onRetry: () => ref.invalidate(myCommentsProvider),
              )
            : const RowListPlaceholder(count: 3, thumbSize: 48),
      );
    }
    final items = data.pages.items;
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.comment,
            title: '还没写过评论',
            message: '点开吃过的菜，就能写评价。',
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (_, i) => _Row(comment: items[i]),
        ),
        if (data.pages.hasNext)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: items.length,
              failed: data.moreError != null,
              onVisible: () => ref.read(myCommentsProvider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}

class _Row extends ConsumerWidget {
  const new({required this.comment});

  final MyComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final dish = ref.watch(commentedDishProvider(comment.dishId));
    final removed =
        dish.error is AppFailure &&
        (dish.error! as AppFailure).code == BizCodes.foodNotFound;
    final name = removed ? '这道菜已删除' : dish.value?.name ?? '这道菜';
    final text = comment.text.isNotEmpty
        ? comment.text
        : comment.imageCount > 0
        ? '[${comment.imageCount} 张照片]'
        : '';
    return EatListRow(
      leading: ClipOval(
        child: SizedBox.square(
          dimension: 48,
          child: ColoredBox(
            color: c.mist,
            child: CoverImage(
              image: networkImage(dish.value?.cover, width: 48),
            ),
          ),
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      lines: [
        if (text.isNotEmpty)
          Text(
            comment.isReply ? '回复：$text' : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: eat.text.body.copyWith(color: c.inkSoft),
          ),
      ],
      trailing: Text(
        TimeFormat.relative(comment.createdAt, clock.now()),
        style: eat.text.caption.copyWith(color: c.inkMuted),
      ),
      onTap: removed
          ? null
          : () => context.push(
              Paths.dish(comment.dishId, comment: comment.rootId ?? comment.id),
            ),
    );
  }
}
