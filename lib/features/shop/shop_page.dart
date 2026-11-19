import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
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
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/foot_links.dart';
import 'package:eat/design/widgets/fact_list.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/joined_group.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_bar_action.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/stat_strip.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/shop/rating_card.dart';
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

/// 餐厅详情页, 分为顶部舞台与下方抽屉两部分. 菜品页看的是一道菜, 这里看的是一份菜单.
///
/// - 舞台: 招牌菜的盘子扇形排开 (最多 3 只, 没有招牌时是一只装门头照的盘子), 左下是店名和地址.
/// - 抽屉: 数字条 (推荐率, 菜数, 距离) 和品类口味卡片连成一组 ([JoinedGroup]), 导航和加菜, 按分类分组的全部菜品, 页底的资料维护链接.
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
                error: failure,
                onRetry: () => ref.invalidate(shopProvider(shopId)),
              ),
            ),
          )
        else if (shop.value case final shop?) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              EatSpace.s20,
              EatSpace.s8,
              EatSpace.s20,
              0,
            ),
            sliver: SliverList.list(
              children: [
                JoinedGroup([
                  _Stats(shop: shop),
                  if (shop.categories.isNotEmpty || shop.tastes.isNotEmpty)
                    _Tags(shop: shop),
                ]),
                const SizedBox(height: EatSpace.s16),
                _Actions(shop: shop),
              ],
            ),
          ),
          _Menu(shopId: shop.id),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              EatSpace.s20,
              EatSpace.s24,
              EatSpace.s20,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _Links(shop: shop)),
          ),
        ] else
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              EatSpace.s20,
              EatSpace.s8,
              EatSpace.s20,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _Actions(shop: null),
                SizedBox(height: _groupGap),
                TileGridPlaceholder(count: 4),
              ]),
            ),
          ),
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

/// 抽屉里大分组之间的留白: 操作和菜单之间.
const _groupGap = 32.0;

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

/// 抽屉顶部的数字条: 推荐率, 菜数, 距离.
///
/// - 推荐率: 规则见 [ShopRules.rateOf], 堂食不满门槛而外卖满时写外卖的. 下面写评价人数; 自己评过时写自己的评价. 点了从这一格展开评价卡.
/// - 菜单: 全部菜品的总数, 写成 "3 道菜".
/// - 距离: 离我多远, 下面写商圈.
class _Stats extends ConsumerStatefulWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  ConsumerState<_Stats> createState() => _StatsState();
}

class _StatsState extends ConsumerState<_Stats> {
  /// 推荐率格, 评价卡从这里展开.
  final _rateCell = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final rate = ShopRules.rateOf(shop);
    final count = shop.dineIn.count + shop.delivery.count;
    final mine = myRatingsText(
      ref.watch(shopMineStateProvider(shop.id).select((m) => m.ratings)),
    );
    final total = ref.watch(
      shopMenuProvider(shop.id).select((m) => m.value?.pages.total),
    );
    final distance = ref.watch(distanceToProvider(shop.point));
    final summary = switch (rate) {
      final rate? => '${rate.count} 人评过',
      null when count == 0 => '还没人评价',
      null => '$count 条评价',
    };
    late final StatCell rateCell;
    rateCell = StatCell(
      key: _rateCell,
      label: rate?.scene == RatingScene.delivery ? '外卖推荐率' : '推荐率',
      value: rate == null ? '—' : '${rate.percent}%',
      note: mine == null ? summary : '你：$mine',
      semanticsLabel: [
        '评价',
        if (rate != null) ShopRules.rateText(rate),
        summary,
        if (mine != null) '你的评价：$mine',
      ].join('，'),
      onTap: () => showShopRatingCard(
        context,
        ref,
        shop,
        origin: _rateCell,
        face: (_) => StatStrip.face(rateCell),
      ),
    );
    return StatStrip([
      rateCell,
      StatCell(
        label: '菜单',
        value: total == null ? '—' : '$total',
        unit: total == null ? null : '道菜',
        semanticsLabel: total == null ? null : '$total 道菜',
      ),
      StatCell(
        label: '距离',
        value: distance ?? '—',
        note: shop.hubName,
        semanticsLabel: distance == null ? null : '距你 $distance',
      ),
    ]);
  }
}

/// 品类和口味, 接在数字条下面, 和数字条连成一组. 左边小字写 "品类" "口味", 右边用顿号连起来.
class _Tags extends StatelessWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) => JoinedSurface(
    child: Padding(
      padding: const EdgeInsets.all(EatSpace.s16),
      child: FactList([
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
      ]),
    ),
  );
}

/// 全部菜品, 按菜单顺序分页, 标题右侧附带菜品总数.
///
/// 菜单本身按 "招牌在前, 然后按分类" 排, 这里把相邻的同类菜收成一组, 每组一个小标题加数量.
/// 方块上的平均分优先取本地打分后的结果, 从菜品详情打分回来不用刷新菜单.
class _Menu extends ConsumerWidget {
  const new({required this.shopId});

  final int shopId;

  /// 一道菜归到哪一组: 招牌单独一组, 其余按分类, 没有分类的归 "其他".
  static String _groupOf(Dish dish) =>
      dish.signature ? '招牌' : dish.category?.label ?? '其他';

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
    final groups = <({String title, List<Dish> dishes})>[];
    for (final dish in dishes) {
      final title = _groupOf(dish);
      if (groups.isEmpty || groups.last.title != title) {
        groups.add((title: title, dishes: [dish]));
      } else {
        groups.last.dishes.add(dish);
      }
    }
    Widget tile(Dish dish) => DishTile(
      image: networkImage(dish.cover, width: tileWidth),
      name: dish.name,
      price: DishRules.priceText(dish.price),
      likes: dish.likes,
      score: DishRules.scoreText(interactions[dish.id]?.rating ?? dish.rating),
      onTap: () => context.push(Paths.dish(dish.id), extra: dish),
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        _groupGap,
        EatSpace.s20,
        0,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: EatSpace.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: EatSpace.s8,
                children: [
                  Semantics(
                    header: true,
                    child: Text('全部菜品', style: eat.text.heading),
                  ),
                  if (total != null)
                    Text(
                      '$total',
                      style: eat.text.count.copyWith(
                        color: eat.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          switch (data) {
            null when menu.hasError && !menu.isLoading => SliverToBoxAdapter(
              child: FailureState(
                error: menu.error,
                onRetry: () => ref.invalidate(provider),
              ),
            ),
            null => const SliverPadding(
              padding: EdgeInsets.only(top: EatSpace.s14),
              sliver: SliverToBoxAdapter(child: TileGridPlaceholder(count: 4)),
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
                for (final group in groups) ...[
                  SliverToBoxAdapter(
                    child: _GroupTitle(group.title, count: group.dishes.length),
                  ),
                  SliverTileGrid(
                    count: group.dishes.length,
                    builder: (context, i) => tile(group.dishes[i]),
                  ),
                ],
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

/// 菜单里一组的小标题: 组名加这一组的数量, 后面一道细线引到右边.
class _GroupTitle extends StatelessWidget {
  const new(this.title, {required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s20, bottom: EatSpace.s14),
      child: Semantics(
        header: true,
        label: '$title $count 道',
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: EatSpace.s8,
            children: [
              Text(
                title,
                style: eat.text.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              Text('$count', style: eat.text.count.copyWith(color: c.inkMuted)),
              Expanded(
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(color: c.hairline),
                ),
              ),
            ],
          ),
        ),
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
        if (shop != null)
          StageBarActions(
            children: [
              StageBarAction(
                icon: EatIcons.edit,
                text: '编辑',
                label: '编辑店铺',
                onTap: () async {
                  if (await guardAction(context, ref, Capability.editShop) &&
                      context.mounted) {
                    await context.push(Paths.shopEdit(shop.id));
                  }
                },
              ),
              _favoriteAction(context, ref, shop.id),
              StageBarAction(
                icon: EatIcons.share,
                text: '分享',
                onTap: () => showSharePanel(
                  context,
                  ref,
                  path: Paths.shop(shop.id),
                  title: shop.name,
                  target: (type: AnalyticsTarget.restaurant, id: shop.id),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 店铺收藏按钮, 已收藏时展示实心图标.
StageBarAction _favoriteAction(
  BuildContext context,
  WidgetRef ref,
  int shopId,
) {
  final favorite = ref.watch(
    shopMineStateProvider(shopId).select((m) => m.favorite),
  );
  return StageBarAction(
    icon: favorite ? EatIcons.bookmarkOn : EatIcons.bookmark,
    text: favorite ? '已收藏' : '收藏',
    label: favorite ? '取消收藏店铺' : '收藏店铺',
    onTap: () async {
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

/// 餐厅详情页的舞台内容.
///
/// - 上方: 招牌菜的盘子扇形排开, 第一道在中间最大, 第二道在右, 第三道在左, 点了进那道菜. 没有招牌时是一只装门头照的盘子.
///   门头照也没有时放菜单的第一道菜. 招牌菜请求完成前是一只空盘, 避免先出门头照再跳变.
/// - 左下: 品类和口味, 店名 (占满一行宽, 最多两行, 放不下时缩小字号), 地址; 店已关门时另起一行写 "这家店已关门".
///
/// 招牌菜摘要接口不含封面取景框信息, 因此盘子以图片居中短边内切圆展示.
class _StageContent extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  /// 店名字号从大到小试, 取第一个两行放得下的.
  static const _nameSizes = [40.0, 36.0, 32.0, 28.0];

  double _nameSize(TextStyle style, double width, double scale) {
    for (final size in _nameSizes) {
      final painter = TextPainter(
        text: TextSpan(
          text: shop.name,
          style: style.copyWith(
            fontSize: size * scale,
            height: (size + 4) / size,
          ),
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      final fits = !painter.didExceedMaxLines;
      painter.dispose();
      if (fits) return size * scale;
    }
    return _nameSizes.last * scale;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final layout = EatLayout.of(context);
    final scale = layout.stageScale;
    final signatures = ref.watch(shopSignaturesProvider(shop.id));
    final loading = signatures.isLoading && !signatures.hasValue;
    final dishes = (signatures.value ?? const <Dish>[]).take(3).toList();
    // 没有招牌也没有门头照时, 盘子里放菜单的第一道菜, 不留空盘.
    final firstOnMenu = dishes.isEmpty && shop.photo == null
        ? ref.watch(
            shopMenuProvider(shop.id)
                .select((m) => m.value?.pages.items.firstOrNull),
          )
        : null;
    final address = shop.address;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final nameWidth = layout.isWide ? 300.0 : width - EatSpace.s20 * 2;
        final nameStyle = eat.text.stage.copyWith(color: palette.foreground);
        final nameSize = _nameSize(nameStyle, nameWidth, layout.stageTextScale);

        // 中间那只盘子的大小和圆心, 两边的小一号, 往外错开并略微下沉.
        final big = layout.isWide
            ? (height * 0.42).clamp(220.0, 420.0)
            : 196 * scale;
        final small = big * 0.65;
        final center = layout.isWide
            ? Offset(width - big * 0.75, height * 0.42)
            : Offset(width * 0.56, 205 * scale);
        final spread = big * 0.68;
        final sink = big * 0.14;

        Widget plate(
          Offset at,
          double size,
          String? image, {
          Dish? dish,
          String? label,
        }) {
          final child = DishPlate(
            image: networkImage(image, width: size),
            size: size,
          );
          return Positioned(
            left: at.dx - size / 2,
            top: at.dy - size / 2,
            child: dish == null
                ? child
                : EatTappable(
                    onTap: () => context.push(Paths.dish(dish.id), extra: dish),
                    label: label,
                    focusShape: const CircleBorder(),
                    builder: (context, _) => child,
                  ),
          );
        }

        return Stack(
          children: [
            if (dishes.length > 2)
              plate(
                center + Offset(-spread, sink),
                small,
                dishes[2].cover,
                dish: dishes[2],
                label: '招牌菜 ${dishes[2].name}',
              ),
            if (dishes.length > 1)
              plate(
                center + Offset(spread, sink),
                small,
                dishes[1].cover,
                dish: dishes[1],
                label: '招牌菜 ${dishes[1].name}',
              ),
            plate(
              center,
              big,
              loading
                  ? null
                  : dishes.firstOrNull?.cover ??
                        shop.photo ??
                        firstOnMenu?.cover,
              dish: dishes.firstOrNull ?? firstOnMenu,
              label: switch (dishes.firstOrNull) {
                final hero? => '招牌菜 ${hero.name}',
                null => firstOnMenu?.name,
              },
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
                          shop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: nameStyle.copyWith(
                            fontSize: nameSize,
                            height: (nameSize + 4) / nameSize,
                          ),
                        ),
                      ),
                    ),
                    if (address != null && address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: eat.text.meta.copyWith(
                            color: palette.secondaryForeground,
                          ),
                        ),
                      ),
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
                    shopId: shop.id,
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

/// 页面底部的资料维护链接: "修改记录" 和 "信息有误". 编辑在右上角.
class _Links extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FootLinks([
    (label: '修改记录', onTap: () => context.push(Paths.shopHistory(shop.id))),
    (label: '信息有误', onTap: () => showShopErrorPanel(context, ref, shop)),
  ]);
}
