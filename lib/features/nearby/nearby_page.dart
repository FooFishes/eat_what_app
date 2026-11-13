import 'dart:async';

import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/location.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_radio_row.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/eat_switch.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/features/nearby/nearby_providers.dart';
import 'package:eat/features/system/base_map.dart';
import 'package:eat/features/system/refresh.dart';
import 'package:eat/features/system/shop_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 附近页. 以地图作为舞台, 下方可拖动的抽屉列出附近的店.
///
/// - 顶部: 搜索框, 筛选按钮, 商圈胶囊.
/// - 地图: 每家店一个圆形标记, 右下角是 "回到我的位置".
/// - 拖动地图停止后, 按新的地图中心重新查找店铺.
/// - 筛选和排序同时作用于地图标记和抽屉列表.
///
/// 地图是百度地图. 当前平台没有 AK, 或地图加载失败时整页改为列表, 不留空白的地图区域.
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
  var _sort = ShopSort.distance;
  var _mapFailed = false;

  /// 抽屉高度占屏幕高度的比例. "回到我的位置" 按钮随抽屉上沿移动.
  var _sheetExtent = _sheetInitial;

  /// 抽屉停下后的高度比例, 用作地图的下内边距.
  ///
  /// 拖动抽屉时不实时改: 每次改都要经过平台通道, 停下一会儿后才更新.
  var _sheetRest = _sheetInitial;
  Timer? _sheetDebounce;

  static const _sheetInitial = 0.42;

  /// 店铺行的估算高度: 店名一行, 距离, 地址, 招牌各一行.
  static const _rowExtent = 90.0;
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

  /// 只有手势移动才重新找店. 代码移动 (回到我的位置, 点商圈) 由调用方自己设中心.
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

  Future<void> _openSort() async {
    final sort = await showPanel<ShopSort>(
      context,
      builder: (panel) => EatPanel(
        title: '排序',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final sort in ShopSort.values)
              EatRadioRow(
                title: sort.label,
                selected: sort == _sort,
                onSelected: () => Navigator.of(panel).pop(sort),
              ),
          ],
        ),
      ),
    );
    if (!mounted || sort == null || sort == _sort) return;
    setState(() {
      _sort = sort;
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
      // 行高随文字行数变化, 无法精确计算目标位置. 按四行文字的行高估算, 误差不超过一行.
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
    final hubs = [
      for (final hub in ref.watch(hubsProvider).value ?? const <Hub>[])
        if (campus == null || hub.campusId == null || hub.campusId == campus.id)
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
      sort: _sort,
    );
    final shops = ref.watch(nearbyShopsProvider(query));
    final list = shops.value ?? const <Shop>[];
    final selectedHub = hubs.where((h) => h.id == hubId).firstOrNull;

    final media = MediaQuery.of(context);
    // 地图被搜索框, 商圈胶囊和抽屉 (宽屏是左侧面板) 盖住的部分.
    final insets = layout.isWide
        ? EdgeInsets.only(
            left: EatLayout.widePanelInset + EatLayout.widePanelWidth,
            top: media.padding.top + EatSpace.s16 + EatSize.touch,
          )
        : EdgeInsets.only(
            top: media.padding.top + 8 + 48 + EatSpace.s10 + EatSize.touch,
            bottom: media.size.height * _sheetRest,
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
      hintText: '搜店名或菜名',
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
    final header = _ListHeader(
      count: shops.value?.length,
      sort: _sort,
      onSort: _openSort,
    );
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
      return ColoredBox(
        color: context.eat.colors.paper,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                EatSpace.s16,
                media.padding.top + 8,
                EatSpace.s16,
                EatSpace.s10,
              ),
              child: search,
            ),
            chips,
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
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
      );
    }
    final height = media.size.height;
    return ColoredBox(
      color: context.eat.colors.paper,
      child: Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            left: EatSpace.s16,
            right: EatSpace.s16,
            top: media.padding.top + 8,
            child: search,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: media.padding.top + 8 + 48 + EatSpace.s10,
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
                        padding: EdgeInsets.only(top: 10, bottom: EatSpace.s14),
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
    );
  }

  Widget _rows(AsyncValue<List<Shop>> shops, List<Shop> list) {
    if (!shops.hasValue) {
      if (shops.hasError && !shops.isLoading) {
        return SliverToBoxAdapter(
          child: FailureState(
            message: (shops.error as AppFailure?)?.message,
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
            message: _keyword.isEmpty ? '拖动地图看看附近，或切换其他商圈。' : '换个店名或菜名试试。',
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

/// 列表头: 店铺数量和排序按钮. 点击排序按钮打开排序面板.
class _ListHeader extends StatelessWidget {
  const new({required this.count, required this.sort, required this.onSort});

  final int? count;
  final ShopSort sort;
  final VoidCallback onSort;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
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
          const Spacer(),
          EatTappable(
            onTap: onSort,
            label: '排序：${sort.label}',
            builder: (context, _) => ExcludeSemantics(
              child: SizedBox(
                height: EatSize.touch,
                child: Row(
                  spacing: 2,
                  children: [
                    Text(
                      sort.label,
                      style: eat.text.meta.copyWith(color: eat.colors.inkMuted),
                    ),
                    EatIcon(
                      EatIcons.chevronDown,
                      size: 14,
                      color: eat.colors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on ShopSort {
  String get label => switch (this) {
    ShopSort.distance => '按距离',
    ShopSort.recommendation => '推荐率最高',
    ShopSort.dishCount => '菜最多',
  };
}

/// 筛选面板: 分类多选, 价位单选, 只看推荐率 80% 以上, 只看我收藏的店.
///
/// 选项先作用于草稿, 点 "看 N 家" 后才生效. N 是按草稿查询的结果数, 随选项实时变化.
/// 草稿查询与生效后的查询条件相同, 因此生效时复用缓存的结果.
class _FilterPanel extends ConsumerStatefulWidget {
  const new({required this.query});

  /// 面板打开时的查询条件, 其中的筛选项作为草稿的初值.
  final NearbyQuery query;

  @override
  ConsumerState<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<_FilterPanel> {
  late var _categories = {...widget.query.filter.categories};
  late var _priceBand = widget.query.filter.priceBand;
  late var _recommendedOnly = widget.query.filter.recommendedOnly;
  late var _favoritesOnly = widget.query.filter.favoritesOnly;

  /// 最近一次查询到的结果数. 新的草稿查询进行中时沿用该值, 按钮文字不闪烁.
  int? _count;

  NearbyFilter get _draft => NearbyFilter(
    categories: _categories,
    priceBand: _priceBand,
    recommendedOnly: _recommendedOnly,
    favoritesOnly: _favoritesOnly,
  );

  void _toggleCategory(DishCategory category) => setState(() {
    _categories = _categories.contains(category)
        ? ({..._categories}..remove(category))
        : {..._categories, category};
  });

  void _reset() => setState(() {
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
          group('店里有这些菜，可以多选'),
          Wrap(
            spacing: EatSpace.s8,
            children: [
              for (final category in DishCategory.values)
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
            label: '只看推荐率 80% 以上',
            value: _recommendedOnly,
            onChanged: (value) => setState(() => _recommendedOnly = value),
          ),
          EatSwitch(
            label: '只看我收藏的店',
            value: _favoritesOnly,
            onChanged: (value) => setState(() => _favoritesOnly = value),
          ),
        ],
      ),
    );
  }
}

/// 附近页地图: 商圈范围, 店铺标记和我的位置. 标记由 [PinImages] 画成位图交给地图引擎.
///
/// 选中的店 `zIndex` 最高, 压在其他标记上面. 我的位置在最下面, 不接点击.
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
    final ring = StageColor.broth.color;
    final byId = {for (final shop in shops) '${shop.id}': shop};
    final markers = <MapMarker>[
      if (me case final me?)
        if (pins.me(context) case final image?)
          MapMarker(id: _mePrefix, point: mapPoint(me), image: image),
      for (final shop in shops)
        if (pins.shop(
              context,
              name: shop.name,
              cover: shop.cover ?? shop.photos.firstOrNull,
              selected: shop.id == selectedShopId,
              ring: ring,
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
              stroke: eat.colors.ink,
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
