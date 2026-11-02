import 'dart:async';

import 'package:dio/dio.dart';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/ref_extensions.dart';
import 'package:eat/data/food/food_api.dart';
import 'package:eat/data/food/food_repository.dart';
import 'package:eat/data/place/place_repository.dart';
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
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/shop/shop_error_panel.dart';
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

/// 餐厅详情 "全部菜品" 的分页结果. 加载下一页失败时记录在 [moreError] 中.
class const MenuPages({
  required final Paged<Dish> pages,
  final AppFailure? moreError,
});

/// 一家店的菜品, 按赞数降序分页. [tagId] 不为空时只列出带该口味标签的菜.
///
/// 发布新菜后重新请求. 离开页面后保留 5 分钟.
@riverpod
class ShopMenu extends _$ShopMenu {
  var _loadingMore = false;

  @override
  Future<MenuPages> build(int shopId, int? tagId) async {
    ref.cacheFor(const Duration(minutes: 5));
    ref.watch(publishedCountProvider);
    return MenuPages(pages: await _fetch(1, cancelToken: ref.cancelToken()));
  }

  Future<Paged<Dish>> _fetch(int page, {CancelToken? cancelToken}) => ref
      .read(foodRepositoryProvider)
      .list(
        shopId: shopId,
        tasteTagIds: tagId == null ? null : [tagId!],
        sort: FoodSort.popular,
        page: page,
        cancelToken: cancelToken,
      );

  /// 加载下一页. 同一时刻只加载一页.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.pages.hasNext || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await _fetch(current.pages.page + 1);
      if (ref.mounted) {
        state = AsyncData(MenuPages(pages: current.pages.append(next)));
      }
    } on AppFailure catch (e) {
      if (ref.mounted) {
        state = AsyncData(MenuPages(pages: current.pages, moreError: e));
      }
    } finally {
      _loadingMore = false;
    }
  }
}

/// 当前用户对一家店的评价和收藏.
class const ShopMine({final ShopRating? rating, final bool favorite = false});

/// 当前用户对一家店的评价和收藏, 点击后立即修改本地值, 请求失败时恢复.
///
/// 初值和后续更新来自店铺详情中的个人状态, 只监听其中两个字段.
/// 评价成功后店铺详情会重新请求. 若监听整个详情, 请求期间的旧数据会覆盖乐观值.
@riverpod
class ShopMineState extends _$ShopMineState {
  @override
  ShopMine build(int shopId) {
    final (rating, favorite) = ref.watch(
      shopProvider(shopId)
          .select((s) => (s.value?.myRating, s.value?.favorite ?? false)),
    );
    return ShopMine(rating: rating, favorite: favorite);
  }

  /// 评价, [rating] 为 null 时撤回. 成功时返回 null, 并重新请求店铺详情以更新推荐率.
  ///
  /// 失败时恢复原值并返回失败原因.
  Future<AppFailure?> rate(ShopRating? rating) async {
    final before = state;
    state = ShopMine(rating: rating, favorite: before.favorite);
    try {
      final saved = await ref
          .read(placeRepositoryProvider)
          .rateShop(shopId, rating);
      if (!ref.mounted) return null;
      state = ShopMine(rating: saved, favorite: state.favorite);
      ref.invalidate(shopProvider(shopId));
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = before;
      return e;
    }
  }

  Future<AppFailure?> toggleFavorite() async {
    final before = state;
    final favorite = !before.favorite;
    state = ShopMine(rating: before.rating, favorite: favorite);
    try {
      await ref
          .read(placeRepositoryProvider)
          .setShopFavorite(shopId, favorite: favorite);
      return null;
    } on AppFailure catch (e) {
      if (ref.mounted) state = before;
      return e;
    }
  }
}

/// 餐厅详情页.
///
/// - 舞台: 第一道招牌菜的封面和舞台色, 店名, 商圈, 距离, 菜数和推荐率.
/// - 抽屉: 导航和加菜, 招牌菜, "大家怎么说", 店铺评价, 全部菜品和 "信息有误".
///
/// 招牌菜, 菜数和口味汇总取自店铺详情, 全部菜品单独分页请求.
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
    final hero = shop.value?.signatures.firstOrNull;
    final failure = shop.hasError && !shop.isLoading ? shop.error : null;

    return StageScaffold(
      stage: hero?.stage ?? StageColor.bamboo,
      topBar: _TopBar(shop: shop.value),
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
                onRetry: () => ref.invalidate(shopProvider(widget.shopId)),
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
            sliver: SliverToBoxAdapter(child: _Actions(shop: shop.value)),
          ),
          if (shop.value case final shop?) ...[
            ..._summarySlivers(shop),
            ..._menuSlivers(shop),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EatSpace.s20,
                  28,
                  EatSpace.s20,
                  0,
                ),
                child: _WrongInfo(shop: shop),
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

  Widget _title(String text, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: EatSpace.s10),
    child: Row(
      spacing: EatSpace.s8,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: context.eat.text.sectionTitle),
        ),
        ?trailing,
      ],
    ),
  );

  /// 招牌, "大家怎么说" 和 "你觉得这家怎么样".
  List<Widget> _summarySlivers(Shop shop) {
    final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 3;
    final tastes = shop.tastes;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
        sliver: SliverList.list(
          children: [
            if (shop.signatures.isNotEmpty) ...[
              _title('招牌'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: EatSpace.s14,
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: i < shop.signatures.length
                          ? DishTile(
                              image: networkImage(
                                shop.signatures[i].cover,
                                width: tileWidth,
                              ),
                              name: shop.signatures[i].name,
                              likes: shop.signatures[i].likes,
                              onTap: () => context.push(
                                Paths.dish(shop.signatures[i].id),
                              ),
                            )
                          : const SizedBox(),
                    ),
                ],
              ),
            ],
            if (tastes.isNotEmpty) ...[
              _title('大家怎么说'),
              TasteCloud(
                words: [
                  for (final t in tastes)
                    TasteWord(
                      label: t.name,
                      count: t.count,
                      selected: t.id == _tagFilter,
                    ),
                ],
                selectedLabel: '正在筛选',
                onTap: (i) => setState(
                  () => _tagFilter = _tagFilter == tastes[i].id
                      ? null
                      : tastes[i].id,
                ),
              ),
            ],
            _title('你觉得这家怎么样'),
            _Rating(shopId: shop.id),
          ],
        ),
      ),
    ];
  }

  List<Widget> _menuSlivers(Shop shop) {
    final eat = context.eat;
    final tagId = _tagFilter;
    final provider = shopMenuProvider(shop.id, tagId);
    final menu = ref.watch(provider);
    final data = menu.value;
    final dishes = data?.pages.items ?? const <Dish>[];
    final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 2;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
        sliver: SliverToBoxAdapter(
          child: _title(
            '全部菜品',
            trailing: tagId != null
                ? null
                : Text(
                    '${shop.dishCount}',
                    style: eat.text.count.copyWith(color: eat.colors.inkMuted),
                  ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
        sliver: switch (data) {
          null when menu.hasError && !menu.isLoading => SliverToBoxAdapter(
            child: FailureState(
              message: (menu.error as AppFailure?)?.message,
              onRetry: () => ref.invalidate(provider),
            ),
          ),
          null => const SliverToBoxAdapter(
            child: TileGridPlaceholder(count: 4),
          ),
          _ when dishes.isEmpty && tagId == null => const SliverToBoxAdapter(
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
                  likes: dishes[i].likes,
                  onTap: () =>
                      context.push(Paths.dish(dishes[i].id), extra: dishes[i]),
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
      ),
    ];
  }
}

/// "你觉得这家怎么样": 四档单选胶囊. 点击一档提交评价, 点击已选的一档撤回评价.
class _Rating extends ConsumerWidget {
  const new({required this.shopId});

  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final mine = ref.watch(shopMineStateProvider(shopId)).rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s8,
      children: [
        Wrap(
          spacing: EatSpace.s8,
          children: [
            for (final rating in ShopRating.values)
              EatChip.choice(
                rating.label,
                selected: rating == mine,
                onTap: () =>
                    _rate(context, ref, rating == mine ? null : rating),
              ),
          ],
        ),
        Text(
          mine == null ? '点一个就提交，以后可以改' : '你选了「${mine.label}」，再点一次撤回',
          style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
        ),
      ],
    );
  }

  Future<void> _rate(
    BuildContext context,
    WidgetRef ref,
    ShopRating? rating,
  ) async {
    if (!await guardAction(context, ref, Capability.rateShop)) return;
    final failure = await ref
        .read(shopMineStateProvider(shopId).notifier)
        .rate(rating);
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

/// 收藏店铺. 已收藏时为实心图标.
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
        final failure = await ref
            .read(shopMineStateProvider(shopId).notifier)
            .toggleFavorite();
        if (failure != null && context.mounted) {
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

/// 餐厅详情舞台内容.
///
/// - 右侧: 招牌菜的盘子.
/// - 左下: 店名, 商圈和地址, 距离, 菜数, 推荐率. 已关门的店另起一行写 "这家店已关门".
///
/// 招牌菜摘要不含封面取景, 盘子按居中的短边内切圆显示.
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
    final hub = ref.watch(hubNameProvider(shop.hubId));
    final lines = DishRules.stageLines(shop.name);
    final nameSize = (lines.length >= 3 ? 38.0 : 46.0) * textScale;
    final hero = shop.signatures.firstOrNull;
    final numberStyle = eat.text.distance.copyWith(
      fontSize: 16,
      color: palette.foreground,
    );
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
                      onTap: () => context.push(Paths.dish(hero.id)),
                      label: '招牌菜 ${hero.name}',
                      focusShape: const CircleBorder(),
                      builder: (context, _) => DishPlate(
                        image: networkImage(hero.cover, width: plate),
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
                          Text('距你 $distance', style: numberStyle),
                        Text('${shop.dishCount} 道菜', style: numberStyle),
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

/// 舞台上的推荐率.
///
/// - 评价满 5 人: "86% 推荐", 其下小字 "32 人评过".
/// - 不满 5 人: 只显示 "3 人评过". 无人评价时显示 "还没人评价".
/// - 评价汇总未就绪时不显示.
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
    final count = shop.ratingCount;
    if (count == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: switch (shop.recommendRate) {
        _ when count == 0 => Text('还没人评价', style: small),
        final rate? => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$rate% 推荐', style: numberStyle),
            Text('$count 人评过', style: small),
          ],
        ),
        null => Text('$count 人评过', style: small),
      },
    );
  }
}

/// "导航去店里" 和 "加一道菜". 加菜跳过选店, 直接进入这家店的加菜页.
///
/// 已关门的店两个按钮都不可用. 服务端不拒绝给已关门的店加菜, 由客户端拦截.
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

/// 页面底部的小字 "信息有误", 点击打开 "哪里不对" 面板.
class _WrongInfo extends ConsumerWidget {
  const new({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    return Center(
      child: EatTappable(
        onTap: () => showShopErrorPanel(context, ref, shop),
        label: '信息有误',
        focusShape: const StadiumBorder(),
        builder: (context, _) => SizedBox(
          height: EatSize.touch,
          child: Center(
            widthFactor: 1,
            child: Text(
              '信息有误',
              style: eat.text.meta.copyWith(
                color: eat.colors.inkMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
