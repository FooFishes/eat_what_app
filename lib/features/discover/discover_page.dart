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
import 'package:eat/domain/models/topic.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/topic_rules.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/discover/discover_providers.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/unread_count.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 发现页.
///
/// - 舞台: 转盘. 拖动或点击 "换一个" 切换菜品, 点击 "就它了" 进入菜品详情.
/// - 抽屉: 分类栏和两列推荐流. 有当期专题时, 专题紧跟 "今日推荐" 出现在分类栏中.
/// - 顶栏: 左侧为地点和饭点, 右侧为搜索和消息.
class DiscoverPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  DishCategory? _category;

  /// 分类栏选中了专题. 当期专题消失 (如切换到没有专题的校区) 时按 "今日推荐" 显示.
  var _topicSelected = false;
  late final AppLifecycleListener _lifecycle;
  var _staleNoticed = false;
  var _explaining = false;
  Timer? _mealTimer;

  @override
  void initState() {
    super.initState();
    // 回到前台时刷新铃铛上的未读标记.
    // 离开期间饭点可能已切换, 因此同时重算饭点.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(unreadCountProvider.notifier).refresh();
        ref.invalidate(currentPlaceProvider);
        ref.invalidate(currentTopicProvider);
      },
    );
    _scheduleMealChange();
    ref.listenManual(placeAndMealProvider, (_, _) => _scheduleMealChange());
    // 说明是否已展示需要从本地存储读出.
    // 读出结果为未展示, 且尚未申请过系统权限时, 才弹出说明.
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

  /// 在当前饭点的时间段结束时切换到下一个饭点, 转盘和列表随之刷新.
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

  /// 首次进入发现页时先说明定位用途. 用户点击 "允许定位" 后再弹出系统权限框.
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

    final topic = ref.watch(currentTopicProvider).value;
    final topicShown = _topicSelected && topic != null;
    final shelfStart = topic == null ? 1 : 2;

    return StageScaffold(
      stage: stage,
      topBar: const _TopBar(),
      stageContent: stageContent,
      sheetSlivers: [
        SliverToBoxAdapter(
          child: EatTabs(
            tabs: [
              const EatTabItem('今日推荐'),
              if (topic != null) EatTabItem(topic.name, icon: EatIcons.topic),
              for (final category in DishCategory.shelf)
                EatTabItem(category.label),
            ],
            selected: topicShown
                ? 1
                : _category == null
                ? 0
                : DishCategory.shelf.indexOf(_category!) + shelfStart,
            onSelected: (i) => setState(() {
              _topicSelected = topic != null && i == 1;
              _category = i < shelfStart
                  ? null
                  : DishCategory.shelf[i - shelfStart];
            }),
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: topicShown
              ? _TopicList(topic: topic)
              : _DishList(category: _category),
        ),
      ],
    );
  }
}

/// 舞台顶栏.
///
/// - 左侧: 当前地点和饭点, 点击打开选择面板.
/// - 右侧: 搜索和消息. 有未读消息时铃铛上显示圆点.
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

/// "地点和饭点" 面板: 校区和饭点两组单选, 另有 "按现在的时间" 选项. 选择后立即生效.
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

/// 发现页舞台: 转盘, 菜名, 店名和距离, 价格, 批次圆点, 以及 "换一个" 和 "就它了" 按钮.
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
    final where = [?dish.shopName, distance ?? dish.hubName].join('  ');

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

/// 当前地点和饭点下没有菜品时的舞台: 插画, 说明文字和 "发布一道菜" 按钮.
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
                '加一道菜',
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

/// 推荐请求失败且没有上一批数据时的舞台, 显示 "加载失败" 和 "重试".
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

/// 抽屉中的两列推荐流, 滚动到底部时加载下一批.
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

/// 分类栏选中专题时的抽屉内容: 介绍, 称呼和起止时间, 专题里的菜, 底部为 "往期专题".
///
/// 专题里的菜由运营排定, 不受饭点影响.
class _TopicList extends ConsumerWidget {
  const new({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final c = eat.colors;
    final now = clock.now();
    final provider = discoverTopicProvider(topic.id);
    final value = ref.watch(provider);
    final dishes = value.value?.dishes;

    final Widget list;
    if (!value.hasValue) {
      list = SliverToBoxAdapter(
        child: value.hasError && !value.isLoading
            ? FailureState(
                message: (value.error as AppFailure?)?.message,
                onRetry: () => ref.invalidate(provider),
              )
            : const TileGridPlaceholder(count: 4),
      );
    } else if (dishes == null || dishes.isEmpty) {
      list = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: dishes == null
              ? const EmptyState(
                  icon: EatIcons.topic,
                  title: '这期专题已撤下',
                  message: '去看看其他推荐的菜。',
                )
              : const EmptyState(
                  icon: EatIcons.bowl,
                  title: '这期专题的菜都已删除',
                  message: '去看看其他推荐的菜。',
                ),
        ),
      );
    } else {
      final tileWidth = (MediaQuery.sizeOf(context).width - 54) / 2;
      list = SliverTileGrid(
        count: dishes.length,
        builder: (context, i) => DishTile(
          image: networkImage(dishes[i].cover, width: tileWidth),
          name: dishes[i].name,
          shop: dishes[i].shopName,
          onTap: () => context.push(Paths.dish(dishes[i].id), extra: dishes[i]),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: EatSpace.s4,
            children: [
              if (topic.introduction.isNotEmpty)
                Text(
                  topic.introduction,
                  style: eat.text.body.copyWith(height: 22 / 15, color: c.ink),
                ),
              Text(
                '${TopicRules.kind(topic, now)}，${TopicRules.range(topic, now)}',
                style: eat.text.meta.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s16)),
        list,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: EatSpace.s8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: EatTappable(
                onTap: () => context.push(Paths.topics),
                label: '往期专题',
                focusShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                builder: (context, _) => SizedBox(
                  height: EatSize.touch,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: [
                      Text(
                        '往期专题',
                        style: eat.text.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      EatIcon(EatIcons.chevronRight, size: 16, color: c.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
