import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 打开菜品评分面板. 先校验评分权限, 没有权限时弹拦截对话框, 不打开面板.
Future<void> showDishRatingPanel(
  BuildContext context,
  WidgetRef ref,
  Dish dish,
) async {
  if (!await guardAction(context, ref, Capability.rateDish) ||
      !context.mounted) {
    return;
  }
  await showPanel<void>(context, builder: (_) => DishRatingPanel(dish: dish));
}

/// 菜品评分面板, 从 1 分到 5 分选一个.
///
/// - 点击分数后立即提交, 再点已选的分数则撤销; 提交后面板保持打开, 下方的统计随之更新.
/// - 请求失败时恢复原来的分数并提示原因.
class DishRatingPanel extends ConsumerWidget {
  const new({super.key, required this.dish});

  final Dish dish;

  Future<void> _rate(BuildContext context, WidgetRef ref, int? score) async {
    final failure = await ref
        .read(dishInteractionsProvider.notifier)
        .rate(dish, score);
    if (failure != null && context.mounted) {
      await reportActionFailure(
        context,
        ref,
        failure,
        capability: Capability.rateDish,
        fallback: score == null ? '撤销失败，请重试' : '评分失败，请重试',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final muted = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    final interaction =
        ref.watch(dishInteractionsProvider.select((m) => m[dish.id])) ??
        DishInteraction.of(dish);
    final mine = interaction.myRating;
    return EatPanel(
      title: '给这道菜打分',
      subtitle: dish.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1 分最低，5 分最高', style: muted),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final score in DishRules.scores)
                EatChip.choice(
                  '$score 分',
                  selected: score == mine,
                  onTap: () =>
                      _rate(context, ref, score == mine ? null : score),
                ),
            ],
          ),
          Text(
            mine == null ? '点选即提交，之后可修改' : '已选「$mine 分」，再点一次取消',
            style: muted,
          ),
          const SizedBox(height: EatSpace.s14),
          Semantics(
            liveRegion: true,
            child: Text(
              DishRules.ratingSummary(interaction.rating),
              style: eat.text.body.copyWith(color: eat.colors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
