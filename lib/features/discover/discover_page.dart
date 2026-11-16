import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/location.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/icons/illustrations.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_motion.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/theme/stage_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/dish_plate.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_dialog.dart';
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
import 'package:eat/domain/models/meal_time.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:eat/domain/rules/meal_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/discover/discover_providers.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:eat/state/shops.dart';
import 'package:eat/state/unread_count.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 发现页.
///
/// - 舞台: 美食店推荐转盘, 支持拖动或点击 "换一个" 切换店铺, 点击 "就它了" 进入餐厅详情, 或标记 "不想去这家".
/// - 抽屉: 包含分类栏 ("美食", "甜点饮品" 及待接入的专题) 与推荐店铺列表; 分类切换仅影响抽屉列表, 不影响转盘.
/// - 顶栏: 左侧显示当前地点, 饭点与用餐场景, 右侧为搜索和消息入口.
class DiscoverPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  /// 抽屉列表的类型.
  var _kind = ShopKind.food;
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
    final allow = await showEatDialog<bool>(
      context,
      builder: (dialog) => EatDialog(
        icon: EatIcons.locate,
        title: '允许定位后，能看到离你多远',
        subtitle: '只在打开发现和附近时定位一次，不记录你去过哪里。',
        actions: Row(
          spacing: EatSpace.s10,
          children: [
            Expanded(
              child: EatButton.mist(
                '暂不开启',
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ),
            Expanded(
              child: EatButton.solid(
                '允许定位',
                onPressed: () => Navigator.of(dialog).pop(true),
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
        : turntableColors(feed.shops);
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

    final tabs = EatTabs(
      tabs: [
        for (final kind in ShopKind.values) EatTabItem(kind.label),
        const EatTabItem('专题', icon: EatIcons.topic, pending: true),
      ],
      selected: ShopKind.values.indexOf(_kind),
      onSelected: (i) {
        if (i >= ShopKind.values.length) {
          showPending(context, PendingFeature.topics);
          return;
        }
        setState(() => _kind = ShopKind.values[i]);
      },
      padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
    );

    return StageScaffold(
      stage: stage,
      topBar: const _TopBar(),
      stageContent: stageContent,
      // 分类栏滚动到顶栏下方后固定显示. 浏览列表的任意位置都可以切换分类.
      pinnedBottom: tabs,
      onRefresh: _refresh,
      sheetSlivers: [
        SliverToBoxAdapter(child: tabs),
        const SliverToBoxAdapter(child: SizedBox(height: EatSpace.s14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          sliver: _ShopList(kind: _kind),
        ),
      ],
    );
  }

  /// 下拉刷新当前抽屉分类列表与未读消息数.
  ///
  /// 当转盘已有正常推荐数据时不刷新转盘 (切店由 "换一个" 完成); 仅在转盘为空, 加载失败或正展示过期缓存批次时一并重新请求转盘.
  Future<void> _refresh() async {
    ref.read(unreadCountProvider.notifier).refresh();
    final queue = ref.read(turntableQueueProvider).value;
    if (queue?.current == null || queue!.stale) {
      _staleNoticed = false;
      ref.invalidate(turntableQueueProvider);
    }
    try {
      final provider = discoverShopsProvider(_kind);
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on AppFailure catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }
}

/// 舞台顶栏.
///
/// - 左侧: 当前地点和饭点, 点外卖时后接 "· 外卖". 点击打开选择面板.
/// - 右侧: 搜索和消息. 有未读消息时铃铛上显示圆点.
class _TopBar extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final place = ref.watch(currentPlaceProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final where = place.campus?.name ?? '软件园';
    final what = place.meal.label;
    final delivery = place.scene == RatingScene.delivery;
    final strong = eat.text.subhead;
    final plain = strong.copyWith(fontWeight: FontWeight.w400);
    final dotBorder =
        StageTheme.maybeOf(context)?.background ?? eat.colors.paper;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: EatTappable(
              onTap: () => _showPlacePanel(context, ref),
              label: delivery
                  ? '在$where吃$what，点外卖，切换地点和饭点'
                  : '在$where吃$what，切换地点和饭点',
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
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            style: plain,
                            children: [
                              TextSpan(text: '在 ', style: strong),
                              TextSpan(text: where),
                              TextSpan(text: ' 吃 ', style: strong),
                              TextSpan(text: what),
                              if (delivery) const TextSpan(text: ' · 外卖'),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const EatIcon(EatIcons.chevronDown, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
              onPressed: () async {
                if (await guardAction(context, ref, Capability.viewInbox) &&
                    context.mounted) {
                  await context.push(Paths.inbox);
                }
              },
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

/// "在哪吃" 切换面板, 包含校区, 饭点与用餐场景三组单选以及 "按现在的时间" 快捷操作.
///
/// 面板内的变更仅在本地暂存, 点击 "确定" 后才生效, 直接关闭则放弃修改.
Future<void> _showPlacePanel(BuildContext context, WidgetRef ref) =>
    showPanel<void>(context, builder: (panel) => const _PlacePanel());

class _PlacePanel extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_PlacePanel> createState() => _PlacePanelState();
}

class _PlacePanelState extends ConsumerState<_PlacePanel> {
  late int? _campusId;

  /// 手动选择的饭点. 为 null 时按当前时间自动选择.
  late MealTime? _meal;
  late RatingScene _scene;

  @override
  void initState() {
    super.initState();
    final place = ref.read(currentPlaceProvider);
    _campusId = place.campus?.id;
    _meal = place.autoMeal ? null : place.meal;
    _scene = place.scene;
  }

  void _confirm() {
    final place = ref.read(currentPlaceProvider);
    final notifier = ref.read(placeAndMealProvider.notifier);
    if (_campusId case final id? when id != place.campus?.id) {
      unawaited(notifier.selectCampus(id));
    }
    switch (_meal) {
      case null when !place.autoMeal:
        unawaited(notifier.autoMeal());
      case final meal? when place.autoMeal || meal != place.meal:
        unawaited(notifier.selectMeal(meal));
      default:
    }
    if (_scene != place.scene) unawaited(notifier.selectScene(_scene));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final campuses = ref.watch(campusesProvider).value ?? const [];
    final meal = _meal ?? MealRules.at(clock.now());
    return EatPanel(
      title: '在哪吃？',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '按现在的时间',
              icon: EatIcons.time,
              onPressed: _meal == null
                  ? null
                  : () => setState(() => _meal = null),
            ),
          ),
          Expanded(child: EatButton.solid('确定', onPressed: _confirm)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final campus in campuses)
            EatRadioRow(
              title: campus.name,
              selected: campus.id == _campusId,
              onSelected: () => setState(() => _campusId = campus.id),
            ),
          const _GroupTitle('吃哪顿？'),
          for (final m in MealTime.values)
            EatRadioRow(
              title: m.label,
              selected: m == meal,
              onSelected: () => setState(() => _meal = m),
            ),
          const _GroupTitle('怎么吃？'),
          for (final scene in RatingScene.values)
            EatRadioRow(
              title: switch (scene) {
                RatingScene.dineIn => '去店里吃',
                RatingScene.delivery => '点外卖',
              },
              selected: scene == _scene,
              onSelected: () => setState(() => _scene = scene),
            ),
        ],
      ),
    );
  }
}

/// 面板中一组单选的标题, 如 "吃哪顿？".
class _GroupTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s20, bottom: 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: eat.text.heading.copyWith(color: eat.colors.ink),
        ),
      ),
    );
  }
}

/// 发现页舞台区域, 展示转盘, 店铺及招牌菜信息, 距离或商圈, 推荐率, 批次圆点以及操作按钮.
///
/// 盘中照片优先取首道招牌菜图, 其次取门头图, 均无图时显示 `mist` 底色; 招牌菜摘要不含封面裁剪参数, 按居中短边内切圆展示.
class _TurntableStage extends ConsumerWidget {
  const new({required this.feed});

  final TurntableFeed feed;

  /// 手机端舞台大字单行最大宽度 (按 40px 字号四字宽度计), 超出时右端会遮挡盘沿.
  static const _nameMaxWidth = 160.0;

  /// 舞台底部信息栏与抽屉顶边之间的间距.
  static double _columnGap(bool wide) => wide ? 40 : 22;

  /// 手机上盘子 (连盘沿) 与顶栏和按钮之间至少留出的距离.
  static const _plateGap = EatSpace.s10;

  /// 价格与菜名之间的间距. 由于菜名行高较紧凑, 需预留更大间距以避免视觉粘连.
  static const _priceGap = EatSpace.s14;

  /// 菜名下方各信息行之间的统一垂直间距.
  static const _factGap = EatSpace.s8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = EatLayout.of(context);
    final palette = StageTheme.of(context);
    final eat = context.eat;
    final shop = feed.current!;
    final distance = ref.watch(distanceToProvider(shop.point));
    final where = distance ?? shop.hubName;
    final rate = ShopRules.rateOf(shop);
    final signature = shop.signatures.firstOrNull;
    final price = DishRules.priceText(signature?.price);
    final scale = layout.stageScale;
    final textScale = layout.stageTextScale;
    final batch = feed.batch;
    final queue = ref.read(turntableQueueProvider.notifier);
    // 有招牌菜时菜是主角, 店名排在菜名下方. 没有招牌菜时店名是主角.
    final hero = signature?.name ?? shop.name;
    final lines = signature != null
        ? DishRules.stageLines(hero)
        : ShopRules.stageLines(hero);
    final longest = lines.fold(0, (m, l) => math.max(m, l.runes.length));
    final nameWidth = layout.isWide ? 260.0 : _nameMaxWidth * textScale;
    final nameSize = math.min(
      layout.stageNameSize(lines),
      nameWidth / math.max(longest, 1),
    );
    // 菜名下方的价格, 店名, 距离和推荐率比各自的预设稍大. 价格, 距离和推荐率用同一种样式.
    final shopStyle = eat.text.subhead.copyWith(
      fontSize: 17,
      color: palette.foreground,
    );
    final numberStyle = eat.text.count.copyWith(
      fontSize: 17,
      color: palette.secondaryForeground,
    );
    final metaStyle = eat.text.meta.copyWith(
      fontSize: 14,
      color: palette.secondaryForeground,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final double plate;
        final Offset plateCenter;
        if (layout.isWide) {
          plate = (height * 440 / 800).clamp(260.0, 520.0);
          plateCenter = Offset(width - plate * 0.3, height / 2);
        } else {
          // 盘子右半边和 "就它了", "更多" 上下相邻, 不能压到按钮上.
          // 放不下时先上移, 上移到顶栏下方仍放不下再缩小.
          final preferred = 296 * scale;
          final rim = DishPlate.rimFor(preferred);
          final top = StageScaffold.barBottomOf(context) + _plateGap;
          final bottom =
              height -
              EatSize.sheetOverlap -
              _columnGap(false) -
              EatSize.button -
              _plateGap;
          plate = math.min(preferred, bottom - top - rim * 2);
          plateCenter = Offset(
            width - 58 * scale,
            math.min(300 * scale, bottom - rim - plate / 2),
          );
        }
        final textWidth = layout.isWide ? 260.0 : 200.0 * textScale;
        // 招牌菜和距离所在的高度接近盘子的圆心, 此处盘子最宽.
        // 宽度限制在盘子左边缘以内, 文字过长时换行, 不与照片重叠.
        final lineWidth = layout.isWide
            ? textWidth
            : plateCenter.dx - plate / 2 - EatSpace.s20 - EatSpace.s8;
        return Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: '转盘，左右拖动换一家店',
                child: Turntable(
                  items: [
                    for (final s in feed.shops)
                      switch (s.signatures.firstOrNull) {
                        ShopDish(:final photo?, :final crop) => TurntableItem(
                          image: networkImage(photo, width: plate),
                          centerX: crop.centerX,
                          centerY: crop.centerY,
                          diameter: crop.diameter,
                        ),
                        _ => TurntableItem(
                          image: networkImage(s.photo, width: plate),
                        ),
                      },
                  ],
                  index: feed.index,
                  onIndexChanged: queue.select,
                  plateSize: plate,
                  plateCenter: plateCenter,
                  wide: layout.isWide,
                  spinning: feed.shops.length >= 5,
                ),
              ),
            ),
            Positioned(
              left: EatSpace.s20,
              right: EatSpace.s20,
              top: layout.isWide
                  ? EatSpace.s24
                  : StageScaffold.barBottomOf(context) + _plateGap,
              bottom: EatSize.sheetOverlap + _columnGap(layout.isWide),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 矮屏或菜名三行时整段文字等比缩小, 不顶到顶栏.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.bottomStart,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: textWidth,
                          child: Semantics(
                            liveRegion: true,
                            // 换店时文字交叉淡入淡出, 与盘子转动和舞台换色同时过渡.
                            // 两家店的行数可能不同. 按左下角对齐时, 最后一行的位置保持不变.
                            child: AnimatedSwitcher(
                              duration: context.motion(EatMotion.select),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: AlignmentDirectional.bottomStart,
                                children: [...previous, ?current],
                              ),
                              child: Column(
                                key: ValueKey(shop.id),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lines.join('\n'),
                                    semanticsLabel: hero,
                                    textScaler: TextScaler.noScaling,
                                    style: eat.text.stage.copyWith(
                                      fontSize: nameSize,
                                      height: (nameSize + 4) / nameSize,
                                      color: palette.foreground,
                                    ),
                                  ),
                                  // 价格归属招牌菜并紧随菜名之后; 店名, 距离与推荐率另起分组并以图标区分.
                                  if (price != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: _priceGap,
                                      ),
                                      child: _StageFact(
                                        EatIcons.price,
                                        price,
                                        style: numberStyle,
                                      ),
                                    ),
                                  if (signature != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: _factGap,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: lineWidth,
                                        ),
                                        child: _StageFact(
                                          EatIcons.store,
                                          shop.name,
                                          maxLines: 2,
                                          style: shopStyle,
                                        ),
                                      ),
                                    ),
                                  if (where != null || rate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: _factGap,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: lineWidth,
                                        ),
                                        // 盘子左边放不下时折成两行.
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: EatSpace.s14,
                                          runSpacing: _factGap,
                                          children: [
                                            if (distance != null)
                                              _StageFact(
                                                EatIcons.pin,
                                                distance,
                                                style: numberStyle,
                                              )
                                            else if (shop.hubName
                                                case final hub?)
                                              _StageFact(
                                                EatIcons.district,
                                                hub,
                                                style: metaStyle,
                                              ),
                                            if (rate != null)
                                              Text(
                                                ShopRules.rateText(rate),
                                                style: numberStyle,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
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
                            onPressed: () => context.push(Paths.shop(shop.id)),
                          ),
                        ),
                        EatIconButton(
                          EatIcons.dismiss,
                          label: '不想去这家',
                          color: palette.foreground,
                          onPressed: () => _dismissShop(context, ref, shop),
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

/// 处理 "不想去这家" 操作, 弹窗确认后直接标记屏蔽.
///
/// 游客触发时会弹出登录拦截; 由于当前不支持撤销屏蔽, 须先经用户二次确认.
/// 标记成功后将店铺从转盘和抽屉列表中移除, 且 30 天内不再推荐.
Future<void> _dismissShop(
  BuildContext context,
  WidgetRef ref,
  Shop shop,
) async {
  if (!await guardAction(context, ref, Capability.dismissShop) ||
      !context.mounted) {
    return;
  }
  final confirmed = await showEatDialog<bool>(
    context,
    builder: (dialog) => EatDialog(
      title: '不喜欢这家店？',
      subtitleSpan: TextSpan(
        children: [
          TextSpan(
            text: shop.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.eat.colors.ink,
            ),
          ),
          const TextSpan(text: ' 30 天内'),
          TextSpan(
            text: '不会',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.eat.colors.warn,
            ),
          ),
          const TextSpan(text: '再出现在推荐里。'),
        ],
      ),
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '算了',
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '不喜欢',
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await dismissShop(ref, shop.id);
    if (context.mounted) showToast(context, '30 天内不再推荐这家店');
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    await reportActionFailure(
      context,
      ref,
      e,
      capability: Capability.dismissShop,
      fallback: '标记失败，请重试',
    );
  }
}

/// 当前地点, 饭点与场景下无推荐店铺时的空舞台, 展示插画, 引导文案和 "发布一道菜" 按钮.
class _EmptyStage extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final palette = StageTheme.of(context);
    final scale = EatLayout.of(context).stageScale;
    return Stack(
      children: [
        // 盘子直径小于有店时的 296. 直径为 280 时, 盘子与左下角的两行说明重叠.
        Positioned(
          right: -40 * scale,
          top: 104 * scale,
          child: DishPlate.illustration(
            IllustrationImage(Illustration.jiaozi, size: 240 * scale),
            size: 240 * scale,
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
                  '这附近还没人加过店，来发第一道菜',
                  style: eat.text.title.copyWith(color: palette.foreground),
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
            style: eat.text.title.copyWith(color: palette.foreground),
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

/// 抽屉中 [kind] 分类的推荐店铺列表, 支持触底分页加载与点击跳转餐厅详情.
class _ShopList extends ConsumerWidget {
  const new({required this.kind});

  final ShopKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = discoverShopsProvider(kind);
    final list = ref.watch(provider);
    final feed = list.value;
    if (feed == null) {
      if (list.hasError && !list.isLoading) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
            child: FailureState(
              message: (list.error as AppFailure?)?.message,
              onRetry: () => ref.invalidate(provider),
            ),
          ),
        );
      }
      return const SliverToBoxAdapter(
        child: RowListPlaceholder(count: 5, thumbSize: EatSize.thumbLg),
      );
    }
    if (feed.shops.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.store,
            title: switch (kind) {
              ShopKind.food => '还没有推荐的店',
              ShopKind.drink => '还没有推荐的甜点饮品店',
            },
            message: '换个饭点或校区看看，也可以发布第一道菜。',
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverList.separated(
          itemCount: feed.shops.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (context, i) => ShopRow(
            shop: feed.shops[i],
            onTap: () => context.push(Paths.shop(feed.shops[i].id)),
          ),
        ),
        if (feed.hasMore || feed.moreError != null)
          SliverToBoxAdapter(
            child: LoadMoreTrigger(
              generation: feed.shops.length,
              failed: feed.moreError != null,
              onVisible: () => ref.read(provider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }
}

/// 舞台上带前置图标的信息条目, 图标尺寸与颜色跟随文字样式.
///
/// 文字换行时图标与首行对齐; 若允许两行且第二行宽度不足首行的三分之一, 则限制为单行并在末尾省略, 避免次行大面积留白.
class _StageFact extends StatelessWidget {
  const new(this.icon, this.text, {required this.style, this.maxLines = 1});

  final EatIcons icon;
  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final fontSize = scaler.scale(style.fontSize ?? 16);
    final lineHeight = fontSize * (style.height ?? 1);
    Widget label(int lines) => Text(
      text,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EatSpace.s4,
      children: [
        Padding(
          padding: EdgeInsets.only(top: math.max(0, lineHeight - fontSize) / 2),
          child: EatIcon(icon, size: fontSize, color: style.color),
        ),
        Flexible(
          child: maxLines == 1
              ? label(1)
              : LayoutBuilder(
                  builder: (context, constraints) => label(
                    _wrapsShort(context, scaler, constraints.maxWidth)
                        ? 1
                        : maxLines,
                  ),
                ),
        ),
      ],
    );
  }

  /// 判断文本在指定宽度下是否恰好排成两行且末行不足首行宽度的三分之一.
  bool _wrapsShort(BuildContext context, TextScaler scaler, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: width);
    try {
      final lines = painter.computeLineMetrics();
      return lines.length == 2 && lines[1].width < lines[0].width / 3;
    } finally {
      painter.dispose();
    }
  }
}
