import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/morph_card.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/shop/shop_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 从数字条的推荐率格 [origin] 展开评价卡. 先校验评价权限, 没有权限时弹拦截对话框, 不展开.
///
/// [face] 是推荐率格原来的样子, 展开和收回时画在卡片开头.
Future<void> showShopRatingCard(
  BuildContext context,
  WidgetRef ref,
  Shop shop, {
  required GlobalKey origin,
  required WidgetBuilder face,
}) async {
  if (!await guardAction(context, ref, Capability.rateShop) ||
      !context.mounted) {
    return;
  }
  final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
  await showMorphCard<void>(
    context,
    origin: origin,
    from: context.eat.colors.mist,
    height: 236 * textScale,
    face: face,
    barrierLabel: '评价这家店',
    builder: (_) => ShopRatingCard(shopId: shop.id, shopName: shop.name),
  );
}

/// 格式化当前用户在两个就餐场景的评价摘要 (如 "堂食推荐, 外卖不推荐"), 若均未评价则返回 null.
String? myRatingsText(MyShopRatings mine) {
  final parts = [
    for (final scene in RatingScene.values)
      if (mine.of(scene) case final rating?) '${scene.label}${rating.label}',
  ];
  return parts.isEmpty ? null : parts.join('，');
}

/// 评价卡: 标题和店名, 堂食和外卖各一行 "推荐" "不推荐", 最下面一行提示和自己现在的评价.
///
/// - 点选项立即提交, 再点已选的那个撤回; 提交后卡片不关, 可以接着评另一个场景.
/// - 请求失败时恢复原来的选择并提示原因.
class ShopRatingCard extends ConsumerWidget {
  const new({super.key, required this.shopId, required this.shopName});

  final int shopId;
  final String shopName;

  Future<void> _rate(
    BuildContext context,
    WidgetRef ref,
    RatingScene scene,
    ShopRating? rating,
  ) async {
    final failure = await ref
        .read(shopMineStateProvider(shopId).notifier)
        .rate(scene, rating);
    if (failure != null && context.mounted) {
      await reportActionFailure(
        context,
        ref,
        failure,
        capability: Capability.rateShop,
        fallback: rating == null ? '撤回失败，请重试' : '评价失败，请重试',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final muted = eat.text.meta.copyWith(color: c.inkMuted);
    final mine = ref.watch(
      shopMineStateProvider(shopId).select((m) => m.ratings),
    );
    final summary = myRatingsText(mine);
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
                        '评价这家店',
                        style: eat.text.heading.copyWith(color: c.ink),
                      ),
                    ),
                    Text(
                      shopName,
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
          for (final scene in RatingScene.values)
            Row(
              spacing: EatSpace.s8,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    scene.label,
                    style: eat.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                for (final rating in ShopRating.values)
                  Semantics(
                    label: scene.label,
                    child: EatChip.choice(
                      rating.label,
                      selected: mine.of(scene) == rating,
                      onTap: () => _rate(
                        context,
                        ref,
                        scene,
                        mine.of(scene) == rating ? null : rating,
                      ),
                    ),
                  ),
              ],
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: EatSpace.s14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: EatSpace.s8,
              children: [
                Expanded(child: Text('点选即提交，再点一次取消', style: muted)),
                Flexible(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      summary == null ? '还没评价过' : '你：$summary',
                      textAlign: TextAlign.end,
                      style: eat.text.meta.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.inkSoft,
                      ),
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
