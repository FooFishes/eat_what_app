import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/shop/shop_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 打开店铺评价面板. 先校验评价权限, 若无权限则弹出拦截对话框而不再打开面板.
Future<void> showRatingPanel(
  BuildContext context,
  WidgetRef ref,
  Shop shop,
) async {
  if (!await guardAction(context, ref, Capability.rateShop) ||
      !context.mounted) {
    return;
  }
  await showPanel<void>(
    context,
    builder: (_) => RatingPanel(shopId: shop.id, shopName: shop.name),
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

/// 店铺评价面板, 依次选择就餐场景与是否推荐.
///
/// - 点击选项后立即提交, 再次点击已选选项则撤回, 提交后面板保持打开以便继续评价另一场景.
/// - 请求失败时恢复原有选择并提示失败原因.
class RatingPanel extends ConsumerStatefulWidget {
  const new({super.key, required this.shopId, required this.shopName});

  final int shopId;
  final String shopName;

  @override
  ConsumerState<RatingPanel> createState() => _RatingPanelState();
}

class _RatingPanelState extends ConsumerState<RatingPanel> {
  RatingScene? _scene;

  Future<void> _rate(RatingScene scene, ShopRating? rating) async {
    final failure = await ref
        .read(shopMineStateProvider(widget.shopId).notifier)
        .rate(scene, rating);
    if (failure != null && mounted) {
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
  Widget build(BuildContext context) {
    final eat = context.eat;
    final muted = eat.text.meta.copyWith(color: eat.colors.inkMuted);
    final mine = ref.watch(
      shopMineStateProvider(widget.shopId).select((m) => m.ratings),
    );
    final scene = _scene;
    final current = scene == null ? null : mine.of(scene);
    final summary = myRatingsText(mine);
    return EatPanel(
      title: '评价这家店',
      subtitle: widget.shopName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('在哪吃的', style: muted),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final s in RatingScene.values)
                EatChip.choice(
                  s.label,
                  selected: s == scene,
                  onTap: () => setState(() => _scene = s),
                ),
            ],
          ),
          const SizedBox(height: EatSpace.s14),
          if (scene == null)
            Text('先选在店里吃的还是点的外卖', style: muted)
          else ...[
            Text('${scene.label}推荐吗', style: muted),
            Wrap(
              spacing: EatSpace.s8,
              children: [
                for (final rating in ShopRating.values)
                  EatChip.choice(
                    rating.label,
                    selected: rating == current,
                    onTap: () =>
                        _rate(scene, rating == current ? null : rating),
                  ),
              ],
            ),
            Text(
              current == null ? '点选即提交，之后可修改' : '已选「${current.label}」，再点一次取消',
              style: muted,
            ),
          ],
          const SizedBox(height: EatSpace.s14),
          Semantics(
            liveRegion: true,
            child: Text(
              summary == null ? '你还没评价过这家店' : '你的评价：$summary',
              style: eat.text.body.copyWith(color: eat.colors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
