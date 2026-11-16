import 'dart:async';
import 'dart:math' as math;

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_haptics.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/fact_list.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/shop/rating_panel.dart';
import 'package:eat/features/shop/shop_error_panel.dart';
import 'package:eat/features/shop/shop_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/dish_interactions.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 餐厅详情页, 分为顶部舞台与下方抽屉两部分.
///
/// - 舞台展示主图 (优先取首道招牌菜, 其次取门头照), 店名, 商圈地址, 距离, 菜品数和推荐率.
/// - 抽屉依次包含操作按钮, 招牌菜, 品类与口味, 评价入口, 全部菜品及底部资料维护链接.
///
/// 店铺详情接口不返回招牌菜与菜品总数, 因此招牌菜需单独请求, 菜品数取自全部菜品分页的总数.
/// 舞台背景色根据店铺的类型与品类自动映射.
class ShopPage extends ConsumerWidget {
  const new({super.key, required this.shopId});

  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProvider(shopId));
    final failure = shop.hasError && !shop.isLoading ? shop.error : null;
    if (failure is AppFailure && failure.code == BizCodes.restaurantNotFound) {
      return const _Deleted();
    }

    return StageScaffold(
      stage: switch (shop.value) {
        final shop? => ShopRules.stageOf(shop),
        null => StageColor.broth,
      },
      topBar: _TopBar(shop: shop.value),
      onRefresh: () => _refresh(context, ref),
      stageContent: switch (shop.value) {
        final shop? => _StageContent(shop: shop),
        null when failure != null => const SizedBox(),
        null => const StagePlaceholder(),
      },
      sheetSlivers: [
        if (failure != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(EatSpace.s24),
              child: FailureState(
                message: (failure as AppFailure?)?.message,
                onRetry: () => ref.invalidate(shopProvider(shopId)),
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
            sliver: SliverToBoxAdapter(child: _Actions(shop: shop.value)),
          ),
          if (shop.value case final shop?) ...[
            _Summary(shop: shop),
            _Menu(shopId: shop.id),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EatSpace.s20,
                  28,
                  EatSpace.s20,
                  0,
                ),
                child: _Links(shop: shop),
              ),
            ),
          ] else
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(EatSpace.s20, 28, EatSpace.s20, 0),
              sliver: SliverToBoxAdapter(child: TileGridPlaceholder(count: 4)),
            ),
        ],
      ],
    );
  }

  /// 下拉刷新店铺详情, 招牌菜及菜单列表. 若刷新失败则保留页面现有内容并提示原因.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    ref
      ..invalidate(shopMenuProvider(shopId))
      ..invalidate(shopSignaturesProvider(shopId))
      ..invalidate(shopProvider(shopId));
    try {
      await ref.read(shopProvider(shopId).future);
    } on AppFailure catch (e) {
      if (context.mounted) showToast(context, e.message);
    }
  }
}

/// 店铺已被删除时的兜底页面. 由于重试无法恢复数据, 页面仅提供返回操作.
class _Deleted extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const StageScaffold(
    stage: StageColor.broth,
    topBar: _TopBar(shop: null),
    stageContent: SizedBox(),
    sheetSlivers: [
      SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: EatSpace.s20,
          vertical: EatSpace.s24,
        ),
        sliver: SliverToBoxAdapter(
          child: EmptyState(
            icon: EatIcons.store,
            title: '这家店已删除',
            message: '去附近看看别的店。',
          ),
        ),
      ),
    ],
  );
}

/// 抽屉内的分组标题, 可通过 [trailing] 在标题右侧附加计数等信息.
class _Title extends StatelessWidget {
  const new(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: EatSpace.s10),
    child: Row(
      spacing: EatSpace.s8,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: context.eat.text.heading),
        ),
        ?trailing,
      ],
    ),
  );
}

/// 抽屉上半部分概览区, 依次展示招牌菜, 品类与口味及用户评价入口.
///
/// 若招牌菜为空或请求失败则隐藏招牌栏, 未填写品类与口味时隐藏对应栏位.
class _Summary extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 3;
    final signatures =
        ref.watch(shopSignaturesProvider(shop.id)).value ?? const <Dish>[];
    final traits = [
      if (shop.categories.isNotEmpty)
        (
          label: '品类',
          value: [for (final c in shop.categories) c.label].join('、'),
          strong: false,
        ),
      if (shop.tastes.isNotEmpty)
        (
          label: '口味',
          value: [for (final t in shop.tastes) t.label].join('、'),
          strong: false,
        ),
    ];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
      sliver: SliverList.list(
        children: [
          if (signatures.isNotEmpty) ...[
            const _Title('招牌'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: EatSpace.s14,
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: i < signatures.length
                        ? DishTile(
                            image: networkImage(
                              signatures[i].cover,
                              width: tileWidth,
                            ),
                            name: signatures[i].name,
                            price: DishRules.priceText(signatures[i].price),
                            likes: signatures[i].likes,
                            compact: true,
                            onTap: () => context.push(
                              Paths.dish(signatures[i].id),
                              extra: signatures[i],
                            ),
                          )
                        : const SizedBox(),
                  ),
              ],
            ),
          ],
          if (traits.isNotEmpty) ...[const _Title('品类和口味'), FactList(traits)],
          const _Title('你觉得这家怎么样'),
          _Rating(shop: shop),
        ],
      ),
    );
  }
}

/// 店铺评价入口行, 展示当前用户的评价摘要并提供打开评价面板的按钮.
class _Rating extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final mine = ref.watch(
      shopMineStateProvider(shop.id).select((m) => m.ratings),
    );
    final summary = myRatingsText(mine);
    return Row(
      spacing: EatSpace.s14,
      children: [
        Expanded(
          child: Text(
            summary == null ? '吃过的话，说说推不推荐' : '你的评价：$summary',
            style: eat.text.body.copyWith(color: eat.colors.inkSoft),
          ),
        ),
        EatButton.outline(
          summary == null ? '评价' : '改评价',
          icon: EatIcons.edit,
          height: 36,
          onPressed: () => showRatingPanel(context, ref, shop),
        ),
      ],
    );
  }
}

/// 全部菜品列表区, 按菜单顺序分页展示, 标题右侧附带菜品总数.
///
/// 方块上的平均分优先取本地打分后的结果, 从菜品详情打分回来不用刷新菜单.
class _Menu extends ConsumerWidget {
  const new({required this.shopId});

  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final provider = shopMenuProvider(shopId);
    final menu = ref.watch(provider);
    final data = menu.value;
    final dishes = data?.pages.items ?? const <Dish>[];
    final total = data?.pages.total;
    final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 2;
    final interactions = ref.watch(dishInteractionsProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _Title(
              '全部菜品',
              trailing: total == null
                  ? null
                  : Text(
                      '$total',
                      style: eat.text.count.copyWith(
                        color: eat.colors.inkMuted,
                      ),
                    ),
            ),
          ),
          switch (data) {
            null when menu.hasError && !menu.isLoading => SliverToBoxAdapter(
              child: FailureState(
                message: (menu.error as AppFailure?)?.message,
                onRetry: () => ref.invalidate(provider),
              ),
            ),
            null => const SliverToBoxAdapter(
              child: TileGridPlaceholder(count: 4),
            ),
            _ when dishes.isEmpty => const SliverToBoxAdapter(
              child: EmptyState(
                icon: EatIcons.bowl,
                title: '这家店还没有菜',
                message: '吃过的话，加一道菜让大家知道。',
              ),
            ),
            final data => SliverMainAxisGroup(
              slivers: [
                SliverTileGrid(
                  count: dishes.length,
                  builder: (context, i) => DishTile(
                    image: networkImage(dishes[i].cover, width: tileWidth),
                    name: dishes[i].name,
                    price: DishRules.priceText(dishes[i].price),
                    likes: dishes[i].likes,
                    score: DishRules.scoreText(
                      interactions[dishes[i].id]?.rating ?? dishes[i].rating,
                    ),
                    onTap: () => context.push(
                      Paths.dish(dishes[i].id),
                      extra: dishes[i],
                    ),
                  ),
                ),
                if (data.pages.hasNext)
                  SliverToBoxAdapter(
                    child: LoadMoreTrigger(
                      generation: dishes.length,
                      failed: data.moreError != null,
                      onVisible: () => ref.read(provider.notifier).loadMore(),
                    ),
                  ),
              ],
            ),
          },
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const new({required this.shop});

  final Shop? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = this.shop;
    return Row(
      children: [
        const EatBackButton(),
        Expanded(
          child: shop == null ? const SizedBox() : StageBarTitle(shop.name),
        ),
        if (shop != null) ...[
          _FavoriteButton(shopId: shop.id),
          EatIconButton(
            EatIcons.share,
            label: '分享',
            onPressed: () => showSharePanel(
              context,
              ref,
              path: Paths.shop(shop.id),
              title: shop.name,
            ),
          ),
        ],
      ],
    );
  }
}

/// 店铺收藏按钮, 已收藏时展示实心图标.
class _FavoriteButton extends ConsumerWidget {
  const new({required this.shopId});

  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(
      shopMineStateProvider(shopId).select((m) => m.favorite),
    );
    return EatIconButton(
      favorite ? EatIcons.bookmarkOn : EatIcons.bookmark,
      label: favorite ? '取消收藏店铺' : '收藏店铺',
      onPressed: () async {
        if (!await guardAction(context, ref, Capability.favorite)) return;
        EatHaptics.light();
        final failure = await ref
            .read(shopMineStateProvider(shopId).notifier)
            .toggleFavorite();
        if (!context.mounted) return;
        if (failure == null) {
          showToast(context, favorite ? '已取消收藏' : '已收藏，可在「我的」查看');
        }
        if (failure != null) {
          await reportActionFailure(
            context,
            ref,
            failure,
            capability: Capability.favorite,
            fallback: '收藏失败，请重试',
          );
        }
      },
    );
  }
}

/// 餐厅详情页的舞台内容.
///
/// - 右侧盘子优先展示首道招牌菜照片, 其次回退至门头照片. 招牌菜请求完成前保持空盘, 避免先展示门头照再发生跳变.
/// - 左下区域依次展示店名, 商圈与地址, 距离, 菜品数与推荐率, 若店铺已关门则另起一行标注 "这家店已关门".
///
/// 招牌菜摘要接口不含封面取景框信息, 因此盘子以图片居中短边内切圆展示.
class _StageContent extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final textScale = layout.stageTextScale;
    final distance = ref.watch(distanceToProvider(shop.point));
    final signatures = ref.watch(shopSignaturesProvider(shop.id));
    final total = ref.watch(
      shopMenuProvider(shop.id).select((m) => m.value?.pages.total),
    );
    final lines = ShopRules.stageLines(shop.name);
    final nameWidth = layout.isWide ? 260.0 : 200 * textScale;
    final longest = lines.fold(0, (m, l) => math.max(m, l.runes.length));
    final nameSize = math.min(
      layout.stageNameSize(lines),
      nameWidth / math.max(longest, 1),
    );
    final hero = signatures.value?.firstOrNull;
    final plateImage = switch (signatures) {
      AsyncValue(isLoading: true, hasValue: false) => null,
      _ => hero?.cover ?? shop.photo,
    };
    final numberStyle = eat.text.count.copyWith(
      fontSize: 16,
      color: palette.foreground,
    );
    final where = [?shop.hubName, ?shop.address].join('  ');
    return LayoutBuilder(
      builder: (context, constraints) {
        final plate = layout.isWide
            ? (constraints.maxHeight * 440 / 800).clamp(260.0, 520.0)
            : 260 * scale;
        final center = layout.isWide
            ? Offset(
                constraints.maxWidth - plate * 0.3,
                constraints.maxHeight / 2,
              )
            : Offset(constraints.maxWidth - 60 * scale, 230 * scale);
        return Stack(
          children: [
            Positioned(
              left: center.dx - plate / 2,
              top: center.dy - plate / 2,
              child: hero == null
                  ? DishPlate(
                      image: networkImage(plateImage, width: plate),
                      size: plate,
                    )
                  : EatTappable(
                      onTap: () =>
                          context.push(Paths.dish(hero.id), extra: hero),
                      label: '招牌菜 ${hero.name}',
                      focusShape: const CircleBorder(),
                      builder: (context, _) => DishPlate(
                        image: networkImage(plateImage, width: plate),
                        size: plate,
                      ),
                    ),
            ),
            Positioned(
              left: EatSpace.s20,
              right: EatSpace.s20,
              bottom: EatSize.sheetOverlap + (layout.isWide ? 40 : 28),
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: nameWidth,
                      child: Semantics(
                        header: true,
                        child: Text(
                          lines.join('\n'),
                          semanticsLabel: shop.name,
                          textScaler: TextScaler.noScaling,
                          style: eat.text.stage.copyWith(
                            fontSize: nameSize,
                            height: (nameSize + 4) / nameSize,
                            color: palette.foreground,
                          ),
                        ),
                      ),
                    ),
                    if (where.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          where,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: eat.text.meta.copyWith(
                            color: palette.secondaryForeground,
                          ),
                        ),
                      ),
                    const SizedBox(height: EatSpace.s10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: EatSpace.s16,
                      children: [
                        if (distance != null)
                          Text('距你 $distance', style: numberStyle),
                        if (total != null)
                          Text('$total 道菜', style: numberStyle),
                      ],
                    ),
                    _RatingSummary(shop: shop, numberStyle: numberStyle),
                    if (shop.closed)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '这家店已关门',
                          style: eat.text.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: palette.foreground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 舞台上的推荐率摘要, 依据 [ShopRules.rateOf] 选取展示场景.
///
/// - 达到评价门槛时展示推荐率 (如 "86% 推荐" 或 "外卖 86% 推荐") 及下方评价人数.
/// - 未达门槛时仅展示双场景合计评价条数 (如 "2 条评价"), 暂无评价时展示 "还没人评价".
class _RatingSummary extends StatelessWidget {
  const new({required this.shop, required this.numberStyle});

  final Shop shop;
  final TextStyle numberStyle;

  @override
  Widget build(BuildContext context) {
    final palette = StageTheme.of(context);
    final small = context.eat.text.meta.copyWith(
      color: palette.secondaryForeground,
    );
    final count = shop.dineIn.count + shop.delivery.count;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: switch (ShopRules.rateOf(shop)) {
        final rate? => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ShopRules.rateText(rate), style: numberStyle),
            Text('${rate.count} 人评过', style: small),
          ],
        ),
        null when count == 0 => Text('还没人评价', style: small),
        null => Text('$count 条评价', style: small),
      },
    );
  }
}

/// 抽屉顶部的 "导航去店里" 与 "加一道菜" 操作栏, 点击加菜会跳过选店步骤进入当前店铺的加菜页.
///
/// 已关门店铺会禁用这两个按钮. 由于服务端不拦截已关门店铺的加菜请求, 需由客户端控制拦截.
class _Actions extends ConsumerWidget {
  const new({required this.shop});

  final Shop? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = this.shop;
    return Row(
      spacing: EatSpace.s10,
      children: [
        Expanded(
          flex: 3,
          child: EatButton.solid(
            '导航去店里',
            icon: EatIcons.navigate,
            onPressed: shop == null || shop.closed
                ? null
                : () => navigateToShop(
                    context,
                    ref,
                    name: shop.name,
                    point: shop.point,
                  ),
          ),
        ),
        Expanded(
          flex: 2,
          child: EatButton.outline(
            '加一道菜',
            icon: EatIcons.add,
            onPressed: shop?.closed ?? false
                ? null
                : () async {
                    if (shop != null &&
                        await guardAction(
                          context,
                          ref,
                          Capability.publishDish,
                        ) &&
                        context.mounted) {
                      unawaited(context.push(Paths.publishDish(shop.id)));
                    }
                  },
          ),
        ),
      ],
    );
  }
}

/// 页面底部的资料维护链接组, 包含 "编辑店铺", "修改记录" 和 "信息有误".
///
/// "编辑店铺" 需要已认证权限并在点击时校验, "修改记录" 对所有用户开放.
class _Links extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: EatSpace.s16,
    children: [
      _Link('编辑店铺', () async {
        if (await guardAction(context, ref, Capability.editShop) &&
            context.mounted) {
          unawaited(context.push(Paths.shopEdit(shop.id)));
        }
      }),
      _Link('修改记录', () => context.push(Paths.shopHistory(shop.id))),
      _Link('信息有误', () => showShopErrorPanel(context, ref, shop)),
    ],
  );
}

class _Link extends StatelessWidget {
  const new(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return EatTappable(
      onTap: onTap,
      label: label,
      focusShape: const StadiumBorder(),
      builder: (context, _) => SizedBox(
        height: EatSize.touch,
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: eat.text.meta.copyWith(
              color: eat.colors.inkMuted,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
