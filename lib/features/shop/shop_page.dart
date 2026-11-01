import 'dart:async';

import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/taste_cloud.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_actions.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/published.dart';
import 'package:eat/state/shops.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_page.g.dart';

// TODO: 接口没有招牌菜, 菜数和口味汇总字段, 客户端请求全部菜品自行计算, 菜品数超过请求上限时结果不完整. 接口提供汇总字段后改用接口数据.
/// 一家店的全部菜品, 按赞数降序. 招牌菜, 菜数和口味汇总都由它计算.
@riverpod
Future<List<Dish>> shopMenu(Ref ref, int shopId) {
  ref.cacheFor(const Duration(minutes: 5));
  ref.watch(publishedCountProvider);
  return ref
      .watch(foodRepositoryProvider)
      .menu(shopId, cancelToken: ref.cancelToken());
}

// TODO: 店铺评价, 收藏店铺和 "信息有误" 没有接口, 入口带 "待接入". 接口上线后接入并去掉标记.
/// 餐厅详情页.
///
/// - 舞台: 第一道招牌菜的封面和舞台色, 店名, 商圈, 距离和菜数.
/// - 抽屉: 导航和加菜, 招牌菜, "大家怎么说", 店铺评价和全部菜品.
class ShopPage extends ConsumerStatefulWidget {
  const new({super.key, required this.shopId});

  final int shopId;

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  /// "大家怎么说" 中选中的口味标签. 有值时全部菜品只列出带该标签的菜.
  int? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopProvider(widget.shopId));
    final menu = ref.watch(shopMenuProvider(widget.shopId));
    final dishes = menu.value ?? const <Dish>[];
    final signatures = DishRules.signatures(dishes);
    final hero = signatures.firstOrNull;
    final failure = shop.hasError && !shop.isLoading
        ? shop.error
        : menu.hasError && !menu.isLoading
        ? menu.error
        : null;

    return StageScaffold(
      stage: hero?.stage ?? StageColor.bamboo,
      topBar: _TopBar(shop: shop.value),
      stageContent: switch (shop.value) {
        final shop? => _StageContent(
          shop: shop,
          hero: hero,
          count: menu.hasValue ? dishes.length : null,
        ),
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
                onRetry: () {
                  ref.invalidate(shopProvider(widget.shopId));
                  ref.invalidate(shopMenuProvider(widget.shopId));
                },
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
            sliver: SliverToBoxAdapter(child: _Actions(shop: shop.value)),
          ),
          if (!menu.hasValue)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(EatSpace.s20, 28, EatSpace.s20, 0),
              sliver: SliverToBoxAdapter(child: TileGridPlaceholder(count: 4)),
            )
          else
            ..._menuSlivers(dishes, signatures),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                EatSpace.s20,
                28,
                EatSpace.s20,
                0,
              ),
              child: _WrongInfo(),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _menuSlivers(List<Dish> dishes, List<Dish> signatures) {
    final eat = context.eat;
    final summary = DishRules.tasteSummary(dishes);
    final filtered = _tagFilter == null
        ? dishes
        : [
            for (final d in dishes)
              if (d.tasteTags.any((t) => t.id == _tagFilter)) d,
          ];
    final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 2;
    Widget title(String text, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: EatSpace.s10),
      child: Row(
        spacing: EatSpace.s8,
        children: [
          Semantics(
            header: true,
            child: Text(text, style: eat.text.sectionTitle),
          ),
          ?trailing,
        ],
      ),
    );
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
        sliver: SliverList.list(
          children: [
            if (signatures.isNotEmpty) ...[
              title('招牌'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: EatSpace.s14,
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: i < signatures.length
                          ? _dishTile(signatures[i], tileWidth / 1.5)
                          : const SizedBox(),
                    ),
                ],
              ),
            ],
            if (summary.isNotEmpty) ...[
              title('大家怎么说'),
              TasteCloud(
                words: [
                  for (final t in summary)
                    TasteWord(
                      label: t.name,
                      count: t.count,
                      selected: t.id == _tagFilter,
                    ),
                ],
                selectedLabel: '正在筛选',
                onTap: (i) => setState(
                  () => _tagFilter = _tagFilter == summary[i].id
                      ? null
                      : summary[i].id,
                ),
              ),
            ],
            title('你觉得这家怎么样', trailing: const PendingTag()),
            Wrap(
              spacing: EatSpace.s8,
              children: [
                for (final rating in const ['推荐', '还不错', '一般', '不推荐'])
                  EatChip.choice(
                    rating,
                    selected: false,
                    onTap: () =>
                        showPending(context, PendingFeature.shopRating),
                  ),
              ],
            ),
            title(
              '全部菜品',
              trailing: Text(
                '${filtered.length}',
                style: eat.text.count.copyWith(color: eat.colors.inkMuted),
              ),
            ),
            if (dishes.isEmpty)
              const EmptyState(
                icon: EatIcons.bowl,
                title: '这家店还没有菜',
                message: '吃过的话，加一道菜让大家知道。',
              ),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
        sliver: SliverTileGrid(
          count: filtered.length,
          builder: (context, i) => _dishTile(filtered[i], tileWidth),
        ),
      ),
    ];
  }

  Widget _dishTile(Dish dish, double width) => DishTile(
    image: networkImage(dish.cover, width: width),
    name: dish.name,
    likes: dish.likes,
    onTap: () => context.push(Paths.dish(dish.id), extra: dish),
  );
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
        const Spacer(),
        if (shop != null) ...[
          EatIconButton(
            EatIcons.bookmark,
            label: '收藏店铺，待接入',
            onPressed: () => showPending(context, PendingFeature.shopFavorite),
          ),
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

// TODO: 推荐率没有接口, 舞台上不显示推荐率. 接口上线后在舞台上补上.
/// 餐厅详情舞台内容.
///
/// - 右侧: 招牌菜的盘子.
/// - 左下: 店名, 商圈和地址, 距离, 菜数.
class _StageContent extends ConsumerWidget {
  const new({required this.shop, required this.hero, required this.count});

  final Shop shop;
  final Dish? hero;
  final int? count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final textScale = layout.stageTextScale;
    final distance = ref.watch(distanceToProvider(shop.point));
    final hub = ref.watch(hubNameProvider(shop.hubId));
    final lines = DishRules.stageLines(shop.name);
    final nameSize = (lines.length >= 3 ? 38.0 : 46.0) * textScale;
    final hero = this.hero;
    final where = [?hub, ?shop.address].join(' · ');
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
                  ? DishPlate(image: null, size: plate)
                  : EatTappable(
                      onTap: () =>
                          context.push(Paths.dish(hero.id), extra: hero),
                      label: '招牌菜 ${hero.name}',
                      focusShape: const CircleBorder(),
                      builder: (context, _) => DishPlate(
                        image: networkImage(hero.cover, width: plate),
                        size: plate,
                        centerX: hero.crop.centerX,
                        centerY: hero.crop.centerY,
                        diameter: hero.crop.diameter,
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
                      width: layout.isWide ? 260 : 200 * textScale,
                      child: Semantics(
                        header: true,
                        child: Text(
                          lines.join('\n'),
                          semanticsLabel: shop.name,
                          textScaler: TextScaler.noScaling,
                          style: eat.text.stageDish.copyWith(
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
                            fontSize: 14,
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
                          Text(
                            '距你 $distance',
                            style: eat.text.distance.copyWith(
                              fontSize: 16,
                              color: palette.foreground,
                            ),
                          ),
                        if (count case final count?)
                          Text(
                            '$count 道菜',
                            style: eat.text.distance.copyWith(
                              fontSize: 16,
                              color: palette.foreground,
                            ),
                          ),
                      ],
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

/// "导航去店里" 和 "加一道菜". 加菜跳过选店, 直接进入这家店的加菜页.
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
            onPressed: shop == null
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
            onPressed: () async {
              if (shop != null &&
                  await guardAction(context, ref, Capability.publishDish) &&
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

class _WrongInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Center(
      child: EatTappable(
        onTap: () => showPending(context, PendingFeature.wrongInfo),
        label: '信息有误，待接入',
        focusShape: const StadiumBorder(),
        builder: (context, _) => SizedBox(
          height: EatSize.touch,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: EatSpace.s8,
            children: [
              Text(
                '信息有误',
                style: eat.text.meta.copyWith(
                  color: eat.colors.inkMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
              const PendingTag(),
            ],
          ),
        ),
      ),
    );
  }
}
