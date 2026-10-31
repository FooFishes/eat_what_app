import 'dart:async';

import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/location.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/dish_tile.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_tabs.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/design/widgets/turntable.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/discover/discover_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/unread_count.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 发现页（`G-HomePhoto`）：舞台上是转盘，拖动或「换一个」挑菜，「就它了」进菜品详情；
/// 抽屉里是分类栏和两列推荐流。左上角是地点和饭点，右上角是搜索和消息。
///
/// 专题还没有接口（现状差距 2.1），分类栏里不出现专题。
class DiscoverPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  DishCategory? _category;
  late final AppLifecycleListener _lifecycle;
  var _staleNoticed = false;
  var _explaining = false;
  Timer? _mealTimer;

  @override
  void initState() {
    super.initState();
    // 回到前台时刷新铃铛上的未读点（产品 10.3）。
    // 回到前台时饭点可能已经换了，也重算一次。
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(unreadCountProvider.notifier).refresh();
        ref.invalidate(currentPlaceProvider);
      },
    );
    _scheduleMealChange();
    ref.listenManual(placeAndMealProvider, (_, _) => _scheduleMealChange());
    // 说明展示过没有要从本地读出来，读到了、又还没问过系统才弹说明。
    ref.listenManual(currentLocationProvider, (_, location) {
      if (location.explained == false &&
          location.access == LocationAccess.notAsked &&
          !_explaining) {
        _explaining = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _explainLocation());
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _mealTimer?.cancel();
    super.dispose();
  }

  /// 到饭点的时间段结束时换成下一顿，转盘和列表跟着刷新（产品 4.5）。
  void _scheduleMealChange() {
    _mealTimer?.cancel();
    final now = clock.now();
    final end = mealPeriodEnd(ref.read(placeAndMealProvider), now);
    _mealTimer = Timer(end.difference(now), () {
      if (!mounted) return;
      ref.invalidate(currentPlaceProvider);
      _scheduleMealChange();
    });
  }

  /// 第一次进发现页：先说明为什么要定位，用户点了「允许定位」再弹系统的权限框（产品 6.13）。
  Future<void> _explainLocation() async {
    if (!mounted) return;
    final allow = await showPanel<bool>(
      context,
      builder: (panel) => EatPanel(
        icon: EatIcons.locate,
        title: '允许定位后，能看到离你多远',
        subtitle: '只在打开发现和附近时定位一次，不记录你去过哪里。',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '先不用',
                onPressed: () => Navigator.of(panel).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '允许定位',
                onPressed: () => Navigator.of(panel).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    final notifier = ref.read(currentLocationProvider.notifier);
    if (allow == true) {
      await notifier.request();
    } else {
      await notifier.dismissExplanation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(turntableQueueProvider);
    final feed = queue.value;
    final current = feed?.current;
    final colors = feed == null
        ? const <StageColor>[]
        : DishRules.turntableColors(feed.dishes);
    final stage = current == null ? StageColor.broth : colors[feed!.index];
    ref.listen(turntableQueueProvider, (_, next) {
      if (next.value?.stale == true && !_staleNoticed) {
        _staleNoticed = true;
        showToast(context, '网络连接失败，显示的是上次的推荐');
      }
    });

    final Widget stageContent;
    if (feed != null && current != null) {
      stageContent = _TurntableStage(feed: feed);
    } else if (feed != null) {
      stageContent = const _EmptyStage();
    } else if (queue.hasError && !queue.isLoading) {
      stageContent = _StageFailure(
        onRetry: () => ref.invalidate(turntableQueueProvider),
      );
    } else {
      stageContent = const StagePlaceholder();
    }

    return StageScaffold(
      stage: stage,
      topBar: const _TopBar(),
      stageContent: stageContent,
      sheetSlivers: [
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: [
              const EatTabItem('今日推荐'),
              for (final category in DishCategory.shelf)
                EatTabItem(category.label),
            ],
            selected: _category == null
                ? 0
                : DishCategory.shelf.indexOf(_category!) + 1,
            onSelected: (i) => setState(
              () => _category = i == 0 ? null : DishCategory.shelf[i - 1],
            ),
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: _DishList(category: _category),
        ),
      ],
    );
  }
}

/// 舞台顶部：左边当前地点和饭点，点开是面板；右边搜索和消息，有未读时铃铛加一个小圆点。
class _TopBar extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final place = ref.watch(currentPlaceProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final label = '${place.campus?.name ?? '软件园'} ${place.meal.label}';
    final dotBorder =
        StageTheme.maybeOf(context)?.background ?? eat.colors.paper;
    return Row(
      children: [
        EatTappable(
          onTap: () => _showPlacePanel(context, ref),
          label: '当前是$label，点击切换地点和饭点',
          focusShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          builder: (context, _) => SizedBox(
            height: EatSize.touch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: EatSpace.s4,
                children: [
                  Text(label, style: eat.text.rowTitle.copyWith(fontSize: 17)),
                  const EatIcon(EatIcons.chevronDown, size: 18),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        EatIconButton(
          EatIcons.search,
          label: '搜索',
          onPressed: () => context.push(Paths.search),
        ),
        Stack(
          children: [
            EatIconButton(
              EatIcons.bell,
              label: unread > 0 ? '消息，$unread 条未读' : '消息',
              onPressed: () => context.push(Paths.inbox),
            ),
            if (unread > 0)
              Positioned(
                top: 10,
                right: 10,
                child: IgnorePointer(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: DefaultTextStyle.of(context).style.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: dotBorder, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 「地点和饭点」面板（`G-PanelPlace`）：两组单选，另有「按现在的时间」；选完立即生效。
Future<void> _showPlacePanel(BuildContext context, WidgetRef ref) =>
    showPanel<void>(
      context,
      builder: (panel) => Consumer(
        builder: (context, ref, _) {
          final eat = context.eat;
          final place = ref.watch(currentPlaceProvider);
          final campuses = ref.watch(campusesProvider).value ?? const [];
          final notifier = ref.read(placeAndMealProvider.notifier);
          Widget group(String title) => Padding(
            padding: const EdgeInsets.only(top: EatSpace.s8, bottom: 4),
            child: Text(
              title,
              style: eat.text.meta.copyWith(
                fontWeight: FontWeight.w600,
                color: eat.colors.inkMuted,
              ),
            ),
          );
          return EatPanel(
            title: '在哪吃，吃哪顿',
            actions: EatButton.mist(
              '按现在的时间',
              icon: EatIcons.time,
              onPressed: place.autoMeal ? null : notifier.autoMeal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                group('地点'),
                for (final campus in campuses)
                  EatRadioRow(
                    title: campus.name,
                    selected: campus.id == place.campus?.id,
                    onSelected: () => notifier.selectCampus(campus.id),
                  ),
                const SizedBox(height: EatSpace.s8),
                group('饭点'),
                for (final meal in MealTime.values)
                  EatRadioRow(
                    title: meal.label,
                    selected: meal == place.meal,
                    onSelected: () => notifier.selectMeal(meal),
                  ),
              ],
            ),
          );
        },
      ),
    );

/// 舞台：转盘、菜名、店名和距离、价格、批次圆点，「换一个」和「就它了」。
class _TurntableStage extends ConsumerWidget {
  const new({required this.feed});

  final TurntableFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = EatLayout.of(context);
    final palette = StageTheme.of(context);
    final eat = context.eat;
    final dish = feed.current!;
    final place = ref.watch(currentPlaceProvider);
    final me = ref.watch(currentLocationProvider.select((s) => s.point));
    final distance = GeoRules.distanceLabel(
      me: me,
      target: dish.shopPoint,
      campusCenter: place.campus?.center,
    );
    final scale = layout.stageScale;
    final textScale = layout.stageTextScale;
    final batch = feed.batch;
    final queue = ref.read(turntableQueueProvider.notifier);
    final price = DishRules.priceText(dish.price);
    final lines = DishRules.stageLines(dish.name);
    final nameSize = (lines.length >= 3 ? 38.0 : 46.0) * textScale;
    final where = [?dish.shopName, distance ?? dish.hubName].join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final plate = layout.isWide
            ? (height * 440 / 800).clamp(260.0, 520.0)
            : 296 * scale;
        final plateCenter = layout.isWide
            ? Offset(width - plate * 0.3, height / 2)
            : Offset(width - 72 * scale, 300 * scale);
        final textWidth = layout.isWide ? 260.0 : 200.0 * textScale;
        return Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: '转盘，左右拖动换一道菜',
                child: Turntable(
                  items: [
                    for (final d in feed.dishes)
                      TurntableItem(
                        image: networkImage(d.cover, width: plate),
                        centerX: d.crop.centerX,
                        centerY: d.crop.centerY,
                        diameter: d.crop.diameter,
                      ),
                  ],
                  index: feed.index,
                  onIndexChanged: queue.select,
                  plateSize: plate,
                  plateCenter: plateCenter,
                  wide: layout.isWide,
                  spinning: feed.dishes.length >= 5,
                ),
              ),
            ),
            Positioned(
              left: EatSpace.s20,
              right: EatSpace.s20,
              bottom: EatSize.sheetOverlap + (layout.isWide ? 40 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IgnorePointer(
                    child: SizedBox(
                      width: textWidth,
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lines.join('\n'),
                              semanticsLabel: dish.name,
                              textScaler: TextScaler.noScaling,
                              style: eat.text.stageDish.copyWith(
                                fontSize: nameSize,
                                height: (nameSize + 4) / nameSize,
                                color: palette.foreground,
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
                            if (price != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  price,
                                  textScaler: TextScaler.noScaling,
                                  style: eat.text.priceHero.copyWith(
                                    fontSize: 52 * textScale,
                                    color: palette.foreground,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: EatSpace.s16),
                  DefaultTextStyle.merge(
                    style: TextStyle(color: palette.foreground),
                    child: TurntableDots(
                      count: batch.length,
                      current: feed.index - batch.start,
                    ),
                  ),
                  const SizedBox(height: 17),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.isWide ? 360 : double.infinity,
                    ),
                    child: Row(
                      spacing: EatSpace.s10,
                      children: [
                        Expanded(
                          child: EatButton.stageGhost(
                            '换一个',
                            icon: EatIcons.shuffle,
                            onPressed: queue.next,
                          ),
                        ),
                        Expanded(
                          child: EatButton.stageSolid(
                            '就它了',
                            onPressed: () =>
                                context.push(Paths.dish(dish.id), extra: dish),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 当前地点和饭点下一道菜都没有：插画加一句话和「发布一道菜」（产品 6.4）。
class _EmptyStage extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final scale = EatLayout.of(context).stageScale;
    return Stack(
      children: [
        Positioned(
          right: -40 * scale,
          top: 110 * scale,
          child: DishPlate.illustration(
            IllustrationImage(Illustration.jiaozi, size: 280 * scale),
            size: 280 * scale,
          ),
        ),
        Positioned(
          left: EatSpace.s20,
          right: EatSpace.s20,
          bottom: EatSize.sheetOverlap + 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EatSpace.s16,
            children: [
              SizedBox(
                width: 210,
                child: Text(
                  '这附近还没人发过菜，发第一道',
                  style: eat.text.sectionTitle.copyWith(
                    fontSize: 26,
                    height: 34 / 26,
                    color: palette.foreground,
                  ),
                ),
              ),
              EatButton.stageSolid(
                '发布一道菜',
                icon: EatIcons.add,
                onPressed: () async {
                  if (await guardAction(context, ref, Capability.publishDish) &&
                      context.mounted) {
                    unawaited(context.push(Paths.publish));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 推荐拿不到、也没有上一批：舞台上就地「加载失败」和「重试」。
class _StageFailure extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        0,
        EatSpace.s20,
        EatSize.sheetOverlap + 22,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: EatSpace.s16,
        children: [
          Text(
            '加载失败',
            style: eat.text.sectionTitle.copyWith(
              fontSize: 26,
              color: palette.foreground,
            ),
          ),
          EatButton.stageGhost(
            '重试',
            icon: EatIcons.shuffle,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// 抽屉里的两列推荐流，滑到底接着加载。
class _DishList extends ConsumerWidget {
  const new({required this.category});

  final DishCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(discoverListProvider(category));
    final feed = list.value;
    if (feed == null) {
      if (list.hasError && !list.isLoading) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
            child: FailureState(
              message: (list.error as AppFailure?)?.message,
              onRetry: () => ref.invalidate(discoverListProvider(category)),
            ),
          ),
        );
      }
      return const SliverToBoxAdapter(child: TileGridPlaceholder(count: 6));
    }
    if (feed.dishes.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.bowl,
            title: category == null ? '还没有推荐' : '这一类还没有菜',
            message: '换个饭点或分类看看，也可以发布第一道。',
          ),
        ),
      );
    }
    final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 2;
    return SliverMainAxisGroup(
      slivers: [
        SliverTileGrid(
          count: feed.dishes.length,
          builder: (context, i) {
            final dish = feed.dishes[i];
            return DishTile(
              image: networkImage(dish.cover, width: tileWidth),
              name: dish.name,
              shop: dish.shopName,
              onTap: () => context.push(Paths.dish(dish.id), extra: dish),
            );
          },
        ),
        if (feed.hasMore || feed.moreError != null)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: feed.dishes.length,
              failed: feed.moreError != null,
              onVisible: () =>
                  ref.read(discoverListProvider(category).notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}
