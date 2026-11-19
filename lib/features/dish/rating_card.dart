import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/morph_card.dart';
import 'package:eat/design/widgets/star_rating.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 从数字条的评分格 [origin] 展开评分卡. 先校验评分权限, 没有权限时弹拦截对话框, 不展开.
///
/// [face] 是评分格原来的样子, 展开和收回时画在卡片开头.
Future<void> showDishRatingCard(
  BuildContext context,
  WidgetRef ref,
  Dish dish, {
  required GlobalKey origin,
  required WidgetBuilder face,
}) async {
  if (!await guardAction(context, ref, Capability.rateDish) ||
      !context.mounted) {
    return;
  }
  final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
  await showMorphCard<void>(
    context,
    origin: origin,
    from: context.eat.colors.mist,
    height: 244 * textScale,
    face: face,
    barrierLabel: '给这道菜打分',
    builder: (_) => DishRatingCard(dish: dish),
  );
}

/// 评分卡: 标题和菜名, 五颗星和这个分数的说法, 下面一行提示和这道菜现在的平均分.
///
/// - 点一颗星 (或滑过去松手) 立即提交, 再点已选的那颗撤销; 提交后卡片不关, 平均分和人数跟着更新.
/// - 请求失败时恢复原来的分数并提示原因.
class DishRatingCard extends ConsumerWidget {
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
    final c = eat.colors;
    final muted = eat.text.meta.copyWith(color: c.inkMuted);
    final interaction =
        ref.watch(dishInteractionsProvider.select((m) => m[dish.id])) ??
        DishInteraction.of(dish);
    final mine = interaction.myRating;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        EatSpace.s14,
        EatSpace.s8,
        EatSpace.s20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '给这道菜打分',
                        style: eat.text.heading.copyWith(color: c.ink),
                      ),
                    ),
                    Text(
                      dish.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ),
              ),
              EatIconButton(
                EatIcons.close,
                label: '关闭',
                color: c.inkMuted,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: StarRating(
              value: mine,
              labels: DishRules.scoreWords,
              onChanged: (score) =>
                  _rate(context, ref, score == mine ? null : score),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: EatSpace.s14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    mine == null ? '点选即提交，之后可修改' : '已选「$mine 分」，再点一次取消',
                    style: muted,
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    DishRules.ratingSummary(interaction.rating),
                    style: eat.text.meta.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
