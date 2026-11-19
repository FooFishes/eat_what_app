import 'dart:async';

import 'package:eat/core/platform/location.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/remove_padding.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/permission_policy.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:eat/features/nearby/nearby_providers.dart';
import 'package:eat/features/system/base_map.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/features/system/shop_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 附近页, 以地图作为舞台并在下方可拖动抽屉中列出附近店铺.
///
/// - 顶部: 搜索框, 筛选按钮和商圈胶囊.
/// - 地图: 每家店对应一个圆形标记, 右下角提供 "回到我的位置" 按钮; 拖动地图停止后按新中心点重新查询店铺.
/// - 排序与筛选: 店铺固定按距离升序排列, 筛选条件同时作用于地图标记与抽屉列表.
///
/// 地图由百度地图提供; 若当前平台未配置 AK 或地图加载失败, 整页回退为纯列表布局, 不保留空白地图区域.
class NearbyPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  final _map = EatMapController();
  late final _pins = PinImages(() {
    if (mounted) setState(() {});
  });
  final _sheet = DraggableScrollableController();
  final _keywordInput = TextEditingController();
  ScrollController? _list;

  /// 用于查找店铺的地图中心. 拖动停止并经过防抖后才更新, 尚未确定时为 null.
  GcjPoint? _center;
  Timer? _moveDebounce;

  /// 用户在商圈胶囊中选中的商圈.
  ///
  /// [_hubTouched] 为 false 时不使用该值, 选中的商圈跟随 "我所在的商圈".
  int? _hubId;
  var _hubTouched = false;

  int? _selectedShopId;
  var _keyword = '';
  var _filter = const NearbyFilter();
  var _mapFailed = false;

  /// 抽屉高度占屏幕高度的比例. "回到我的位置" 按钮随抽屉上沿移动.
  var _sheetExtent = _sheetInitial;

  /// 抽屉静止后的高度比例, 用作地图的下内边距.
  ///
  /// 拖动过程中不实时更新该值, 因为每次变更都会触发平台通道调用, 需等待停稳防抖后再同步.
  var _sheetRest = _sheetInitial;
  Timer? _sheetDebounce;

  static const _sheetInitial = 0.42;

  /// 店铺行的估算高度: 店名, 距离和商圈, 地址各一行.
  static const _rowExtent = 70.0;
  static const _zoom = 16.0;

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _sheetDebounce?.cancel();
    _pins.dispose();
    _sheet.dispose();
    _keywordInput.dispose();
    super.dispose();
  }

  bool get _hasMap => !_mapFailed && ref.read(mapEngineProvider).available;

  void _onMapFailed() {
    if (_mapFailed) return;
    setState(() => _mapFailed = true);
    showToast(context, '地图加载失败，已切换为列表');
  }

  /// 仅手势拖动地图时触发防抖重查; 程序触发的视角移动 (如回到定位, 切换商圈) 由调用方直接更新中心点.
  void _onMoved(MapCamera camera, bool byGesture) {
    if (!byGesture) return;
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _center = gcjOf(camera.center));
    });
  }

  void _onSheetMoved(double extent) {
    setState(() => _sheetExtent = extent);
    _sheetDebounce?.cancel();
    _sheetDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _sheetRest = _sheetExtent);
    });
  }

  void _moveTo(GcjPoint point, {double zoom = _zoom}) {
    if (!_hasMap) {
      setState(() => _center = point);
      return;
    }
    unawaited(_map.moveTo(mapPoint(point), zoom: zoom));
    setState(() => _center = point);
  }

  Future<void> _backToMe() async {
    final location = ref.read(currentLocationProvider.notifier);
    var state = ref.read(currentLocationProvider);
    if (state.access != LocationAccess.granted) {
      await location.request();
      state = ref.read(currentLocationProvider);
    } else {
      await location.refresh();
      state = ref.read(currentLocationProvider);
    }
    if (!mounted) return;
    final me = state.point;
    if (me != null) {
      _moveTo(me);
    } else if (ref.read(currentPlaceProvider).campus case final campus?) {
      showToast(context, '没有定位权限，显示的是校区附近');
      _moveTo(campus.center);
    }
  }

  void _selectHub(Hub hub) {
    final selected = _hubId == hub.id && _hubTouched;
    setState(() {
      _hubTouched = true;
      _hubId = selected ? null : hub.id;
      _selectedShopId = null;
    });
    if (selected) return;
    if (_hasMap && hub.boundary.isNotEmpty) {
      unawaited(
        _map.fit([
          for (final ring in hub.boundary)
            for (final p in ring) mapPoint(p),
        ]),
      );
      setState(() => _center = hub.center);
    } else {
      _moveTo(hub.center);
    }
  }

  Future<void> _openFilter(NearbyQuery query) async {
    final filter = await showPanel<NearbyFilter>(
      context,
      builder: (_) => _FilterPanel(query: query),
    );
    if (!mounted || filter == null || filter == _filter) return;
    setState(() {
      _filter = filter;
      _selectedShopId = null;
    });
  }

  void _tapShop(Shop shop, List<Shop> shops) {
    if (_selectedShopId == shop.id) {
      context.push(Paths.shop(shop.id));
      return;
    }
    setState(() => _selectedShopId = shop.id);
    final index = shops.indexOf(shop);
    final list = _list;
    if (index >= 0 && list != null && list.hasClients) {
      // 行高随文字行数变化, 无法精确计算目标位置. 按三行文字的行高估算, 误差不超过一行.
      list.animateTo(
        (_rowExtent + 18) * index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = EatLayout.of(context);
    final campus = ref.watch(currentPlaceProvider.select((p) => p.campus));
    final me = ref.watch(currentLocationProvider.select((s) => s.point));
    final myHub = ref.watch(myHubProvider).value;
    // 商圈不属于校区, 只显示离所选校区不远的商圈.
    final hubs = [
      for (final hub in ref.watch(hubsProvider).value ?? const <Hub>[])
        if (campus == null ||
            GeoRules.distance(hub.center, campus.center) <=
                GeoRules.maxDistanceFromCampus)
          hub,
    ];
    final hubId = _hubTouched ? _hubId : myHub?.id;
    final center = _center ?? me ?? campus?.center;
    if (center == null) {
      return StageScaffold.map(
        map: ColoredBox(color: context.eat.colors.mapGround),
        sheetSlivers: const [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: EatSpace.s20),
            sliver: SliverToBoxAdapter(
              child: RowListPlaceholder(count: 5, thumbSize: EatSize.thumbLg),
            ),
          ),
        ],
      );
    }
    final query = NearbyQuery(
      center: center,
      hubId: hubId,
      keyword: _keyword,
      filter: _filter,
    );
    final shops = ref.watch(nearbyShopsProvider(query));
    final list = shops.value ?? const <Shop>[];
    final selectedHub = hubs.where((h) => h.id == hubId).firstOrNull;

    final safe = MediaQuery.viewPaddingOf(context);
    final screen = MediaQuery.sizeOf(context);
    // 地图被搜索框, 商圈胶囊和抽屉 (宽屏是左侧面板) 盖住的部分.
    final insets = layout.isWide
        ? EdgeInsets.only(
            left: EatLayout.widePanelInset + EatLayout.widePanelWidth,
            top: safe.top + EatSpace.s16 + EatSize.touch,
          )
        : EdgeInsets.only(
            top: safe.top + 8 + 48 + EatSpace.s10 + EatSize.touch,
            bottom: screen.height * _sheetRest,
          );
    final map = _hasMap
        ? _NearbyMap(
            controller: _map,
            pins: _pins,
            initialCenter: center,
            insets: insets,
            me: me,
            shops: list,
            selectedShopId: _selectedShopId,
            hub: selectedHub,
            onMoved: _onMoved,
            onFailed: _onMapFailed,
            onShopTap: (shop) => _tapShop(shop, list),
          )
        : ColoredBox(color: context.eat.colors.mapGround);

    final search = EatSearchField(
      hintText: '搜店名或地址',
      controller: _keywordInput,
      floating: _hasMap,
      onSubmitted: (value) => setState(() {
        _keyword = value.trim();
        _selectedShopId = null;
      }),
      onChanged: (value) {
        if (value.isEmpty && _keyword.isNotEmpty) setState(() => _keyword = '');
      },
      onFilter: () => _openFilter(query),
      filterCount: _filter.count,
    );
    final chips = SizedBox(
      height: EatSize.touch,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: layout.isWide
              ? EatLayout.widePanelInset +
                    EatLayout.widePanelWidth +
                    EatSpace.s24
              : EatSpace.s16,
          right: EatSpace.s16,
        ),
        children: [
          for (final hub in hubs)
            Padding(
              padding: const EdgeInsets.only(right: EatSpace.s8),
              child: (_hasMap ? EatChip.district : EatChip.choice)(
                hub.name,
                selected: hub.id == hubId,
                onTap: () => _selectHub(hub),
              ),
            ),
        ],
      ),
    );
    final locate = EatTappable(
      onTap: _backToMe,
      label: '回到我的位置',
      focusShape: const CircleBorder(),
      builder: (context, _) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.eat.colors.paper,
          shape: BoxShape.circle,
          boxShadow: context.eat.shadows.float.outer,
        ),
        child: Center(
          child: EatIcon(
            EatIcons.locate,
            size: 22,
            color: context.eat.colors.ink,
          ),
        ),
      ),
    );
    final header = _ListHeader(count: shops.value?.length);
    final rows = _rows(shops, list);

    if (layout.isWide) {
      final top = MediaQuery.paddingOf(context).top;
      return StageScaffold.map(
        map: Stack(
          children: [
            Positioned.fill(child: map),
            Positioned(
              left: 0,
              right: 0,
              top: top + EatSpace.s16,
              child: chips,
            ),
            Positioned(
              right: EatSpace.s24,
              bottom: EatSpace.s24,
              child: locate,
            ),
          ],
        ),
        topBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
          child: search,
        ),
        sheetSlivers: [
          SliverToBoxAdapter(child: header),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
            sliver: rows,
          ),
        ],
      );
    }

    final navInset = NavBarInset.of(context);
    if (!_hasMap) {
      // 没有地图时整页显示列表, 不保留空白的地图区域. 搜索, 商圈和筛选的行为不变.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.eat.colors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: ColoredBox(
          color: context.eat.colors.paper,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  EatSpace.s16,
                  safe.top + 8,
                  EatSpace.s16,
                  EatSpace.s10,
                ),
                child: search,
              ),
              chips,
              Expanded(
                child: RemovePadding(
                  removeTop: true,
                  child: EatRefresh(
                    onRefresh: () => pullToRefresh(
                      context,
                      ref,
                      invalidate: [nearbyShopsProvider(query)],
                      wait: () => ref.read(nearbyShopsProvider(query).future),
                    ),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(
                          child: SizedBox(height: EatSpace.s10),
                        ),
                        SliverToBoxAdapter(child: header),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EatSpace.s20,
                          ),
                          sliver: rows,
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: navInset > 0 ? navInset : 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final height = screen.height;
    // 地图底图不分深浅, 状态栏压在地图上, 图标固定用深色.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: context.eat.colors.paper,
        child: Stack(
          children: [
            Positioned.fill(child: map),
            Positioned(
              left: EatSpace.s16,
              right: EatSpace.s16,
              top: safe.top + 8,
              child: search,
            ),
            Positioned(
              left: 0,
              right: 0,
              top: safe.top + 8 + 48 + EatSpace.s10,
              child: chips,
            ),
            Positioned(
              right: EatSpace.s16,
              bottom: height * _sheetExtent + EatSpace.s14,
              child: locate,
            ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                _onSheetMoved(n.extent);
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: _sheetInitial,
                minChildSize: 0.2,
                maxChildSize: 0.88,
                snap: true,
                snapSizes: const [_sheetInitial],
                builder: (context, scroll) {
                  _list = scroll;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.eat.colors.paper,
                      borderRadius: const BorderRadius.vertical(
                        top: EatRadius.sheet,
                      ),
                      boxShadow: context.eat.shadows.sheet.outer,
                    ),
                    child: CustomScrollView(
                      controller: scroll,
                      slivers: [
                        const SliverPadding(
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: EatSpace.s14,
                          ),
                          sliver: SliverToBoxAdapter(child: SheetHandle()),
                        ),
                        SliverToBoxAdapter(child: header),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EatSpace.s20,
                          ),
                          sliver: rows,
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: navInset > 0 ? navInset : 24),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rows(AsyncValue<List<Shop>> shops, List<Shop> list) {
    if (!shops.hasValue) {
      if (shops.hasError && !shops.isLoading) {
        return SliverToBoxAdapter(
          child: FailureState(
            error: shops.error,
            onRetry: () => ref.invalidate(nearbyShopsProvider),
          ),
        );
      }
      return const SliverToBoxAdapter(
        child: RowListPlaceholder(count: 5, thumbSize: EatSize.thumbLg),
      );
    }
    if (list.isEmpty && _keyword.isEmpty && _filter.count > 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.filter,
            title: '没有符合筛选条件的店',
            message: '减少筛选条件，或拖动地图看看附近。',
            action: EatButton.mist(
              '清空筛选',
              onPressed: () => setState(() => _filter = const NearbyFilter()),
            ),
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.store,
            title: _keyword.isEmpty ? '这附近还没有店' : '没找到「$_keyword」',
            message: _keyword.isEmpty ? '拖动地图看看附近，或切换其他商圈。' : '换个店名或地址试试。',
          ),
        ),
      );
    }
    return SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, i) => ShopRow(
        shop: list[i],
        onTap: () => context.push(Paths.shop(list[i].id)),
      ),
    );
  }
}

/// 列表头: 店铺数量. 店铺只按距离排列, 不提供排序选项.
class _ListHeader extends StatelessWidget {
  const new({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        0,
        EatSpace.s20,
        EatSpace.s10,
      ),
      child: SizedBox(
        height: EatSize.touch,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '附近 '),
                  TextSpan(
                    text: count == null ? '' : '$count',
                    style: eat.text.stat.copyWith(fontSize: 20, height: 1),
                  ),
                  TextSpan(text: count == null ? '' : ' 家'),
                ],
              ),
              style: eat.text.heading,
            ),
          ),
        ),
      ),
    );
  }
}

/// 附近店铺筛选面板, 支持类型单选, 品类多选, 价位单选及口碑和收藏开关.
///
/// - 面板内调整先写入草稿, 点击 "看 N 家" 后正式生效; N 为草稿条件实时查询的结果数, 生效时直接复用该次查询缓存.
/// - 游客开启 "只看我收藏的店" 时先弹出登录拦截, 拦截期间不切换开关状态也不发起请求.
class _FilterPanel extends ConsumerStatefulWidget {
  const new({required this.query});

  /// 面板打开时的查询条件, 其中的筛选项作为草稿的初值.
  final NearbyQuery query;

  @override
  ConsumerState<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<_FilterPanel> {
  late var _kind = widget.query.filter.kind;
  late var _categories = {...widget.query.filter.categories};
  late var _priceBand = widget.query.filter.priceBand;
  late var _recommendedOnly = widget.query.filter.recommendedOnly;
  late var _favoritesOnly = widget.query.filter.favoritesOnly;

  /// 最近一次完成查询的结果数; 新查询加载期间沿用该数值, 避免按钮文案闪烁.
  int? _count;

  NearbyFilter get _draft => NearbyFilter(
    kind: _kind,
    categories: _categories,
    priceBand: _priceBand,
    recommendedOnly: _recommendedOnly,
    favoritesOnly: _favoritesOnly,
  );

  void _toggleCategory(ShopCategory category) => setState(() {
    _categories = _categories.contains(category)
        ? ({..._categories}..remove(category))
        : {..._categories, category};
  });

  Future<void> _setFavoritesOnly(bool value) async {
    if (value && !await guardAction(context, ref, Capability.viewFavorites)) {
      return;
    }
    if (mounted) setState(() => _favoritesOnly = value);
  }

  void _reset() => setState(() {
    _kind = null;
    _categories = {};
    _priceBand = null;
    _recommendedOnly = false;
    _favoritesOnly = false;
  });

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final draft = _draft;
    final shops = ref.watch(
      nearbyShopsProvider(widget.query.copyWith(filter: draft)),
    );
    if (!shops.isLoading) _count = shops.value?.length;
    final count = _count;
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
      title: '筛选',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '重置',
              onPressed: draft.count == 0 ? null : _reset,
            ),
          ),
          Expanded(
            flex: 2,
            child: EatButton.solid(
              count == null ? '看结果' : '看 $count 家',
              onPressed: () => Navigator.of(context).pop(draft),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          group('类型'),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              EatChip.choice(
                '不限',
                selected: _kind == null,
                onTap: () => setState(() => _kind = null),
              ),
              for (final kind in ShopKind.values)
                EatChip.choice(
                  kind.label,
                  selected: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: EatSpace.s8),
          group('品类，可以多选'),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final category in ShopCategory.values)
                EatChip.tag(
                  category.label,
                  selected: _categories.contains(category),
                  onTap: () => _toggleCategory(category),
                ),
            ],
          ),
          const SizedBox(height: EatSpace.s8),
          group('价位'),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              EatChip.choice(
                '不限',
                selected: _priceBand == null,
                onTap: () => setState(() => _priceBand = null),
              ),
              for (final band in PriceBand.values)
                EatChip.choice(
                  band.label,
                  selected: _priceBand == band,
                  onTap: () => setState(() => _priceBand = band),
                ),
            ],
          ),
          const SizedBox(height: EatSpace.s8),
          EatSwitch(
            label: '只看口碑好的',
            description:
                '至少 ${ShopRules.rateMinCount} 条评价，推荐率不低于 '
                '${NearbyFilter.recommendedRate}%',
            value: _recommendedOnly,
            onChanged: (value) => setState(() => _recommendedOnly = value),
          ),
          EatSwitch(
            label: '只看我收藏的店',
            value: _favoritesOnly,
            onChanged: _setFavoritesOnly,
          ),
        ],
      ),
    );
  }
}

/// 附近页地图: 商圈范围, 店铺标记和我的位置. 标记由 [PinImages] 画成位图交给地图引擎.
///
/// - 标记里是店的门头照片. 选中时外圈是店铺的舞台色.
/// - 选中的店 `zIndex` 最高, 压在其他标记上面. 我的位置在最下面, 不接点击.
class _NearbyMap extends StatelessWidget {
  const new({
    required this.controller,
    required this.pins,
    required this.initialCenter,
    required this.insets,
    required this.me,
    required this.shops,
    required this.selectedShopId,
    required this.hub,
    required this.onMoved,
    required this.onFailed,
    required this.onShopTap,
  });

  final EatMapController controller;
  final PinImages pins;
  final GcjPoint initialCenter;
  final EdgeInsets insets;
  final GcjPoint? me;
  final List<Shop> shops;
  final int? selectedShopId;
  final Hub? hub;
  final void Function(MapCamera camera, bool byGesture) onMoved;
  final VoidCallback onFailed;
  final ValueChanged<Shop> onShopTap;

  static const _mePrefix = 'me';

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final byId = {for (final shop in shops) '${shop.id}': shop};
    final markers = <MapMarker>[
      if (me case final me?)
        if (pins.me(context) case final image?)
          MapMarker(id: _mePrefix, point: mapPoint(me), image: image),
      for (final shop in shops)
        if (pins.shop(
              context,
              name: shop.name,
              cover: shop.photo,
              selected: shop.id == selectedShopId,
              ring: ShopRules.stageOf(shop).color,
            )
            case final image?)
          MapMarker(
            id: '${shop.id}',
            point: mapPoint(shop.point),
            image: image,
            zIndex: shop.id == selectedShopId ? 3 : 2,
          ),
    ];
    return EatMap(
      controller: controller,
      initialCenter: mapPoint(initialCenter),
      insets: insets,
      markers: markers,
      polygons: [
        if (hub case final hub?)
          for (final (i, ring) in hub.boundary.indexed)
            MapPolygon(
              id: 'hub-${hub.id}-$i',
              points: [for (final p in ring) mapPoint(p)],
              fill: StageColor.broth.color.withValues(alpha: 0.24),
              // 地图底图不分深浅, 描边固定用深色.
              stroke: eat.colors.shade,
              dashed: true,
            ),
      ],
      onCameraIdle: onMoved,
      onMarkerTap: (id) {
        if (byId[id] case final shop?) onShopTap(shop);
      },
      onFailed: onFailed,
      semanticLabel: '地图，附近 ${shops.length} 家店',
    );
  }
}
