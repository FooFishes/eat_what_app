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
import 'package:eat/design/widgets/eat_option.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_refresh.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_segment_slider.dart';
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
import 'package:eat/features/system/shop_entry.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 附近页, 以地图作为舞台并在下方可拖动抽屉中列出附近店铺.
///
/// - 顶部: 商圈按钮, 搜索框和筛选按钮. 点商圈按钮打开 "选商圈" 面板.
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

  /// 用户在 "选商圈" 面板里选中的商圈, 为 null 时是 "附近", 不限商圈.
  ///
  /// [_hubTouched] 为 false 时不使用该值, 选中的商圈跟随 "我所在的商圈".
  int? _hubId;
  var _hubTouched = false;

  int? _selectedShopId;
  var _keyword = '';
  var _filter = const NearbyFilter();
  var _mapFailed = false;

  /// 抽屉高度占屏幕高度的比例. "回到我的位置" 按钮随抽屉上沿移动.
  ///
  /// 地图的下内边距固定按抽屉的初始高度算, 不跟着抽屉变: 内边距一变, 地图引擎会把视野挪一下, 拖抽屉时地图跟着动.
  var _sheetExtent = _sheetInitial;

  /// 上一次查到的店. 换了查询条件 (如拖动地图) 后新结果回来之前先接着显示它, 列表上面走一条加载条.
  List<Shop>? _lastShops;

  static const _sheetInitial = 0.42;

  /// 店铺行的估算高度: 店名, 距离和商圈, 地址各一行.
  static const _rowExtent = 70.0;
  static const _zoom = 16.0;

  @override
  void dispose() {
    _moveDebounce?.cancel();
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

  void _onSheetMoved(double extent) => setState(() => _sheetExtent = extent);

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

  /// 选中商圈 [hub]: 地图移到商圈并画出范围, 列表只看这个商圈的店.
  ///
  /// [hub] 为 null 时是 "附近": 不限商圈, 按当前地图中心找, 地图不动.
  void _selectHub(Hub? hub) {
    setState(() {
      _hubTouched = true;
      _hubId = hub?.id;
      _selectedShopId = null;
    });
    if (hub == null) return;
    unawaited(ref.read(recentHubsProvider.notifier).add(hub.id));
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

  Future<void> _openHubs({
    required int? selectedId,
    required Campus? campus,
    required GcjPoint? me,
  }) async {
    final pick = await showPanel<({Hub? hub})>(
      context,
      builder: (_) => _HubPanel(selectedId: selectedId, campus: campus, me: me),
    );
    if (!mounted || pick == null) return;
    _selectHub(pick.hub);
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

  /// 点地图标记或列表行: 第一次选中这家, 第二次进餐厅详情.
  ///
  /// - 从列表点: 地图移到这家店 (不重新查附近的店), 抽屉拉得太高时先落回初始高度, 让地图露出来.
  /// - 从地图点: 列表滚到这家.
  /// - 没有地图时列表行直接进餐厅详情.
  void _tapShop(Shop shop, List<Shop> shops, {bool fromList = false}) {
    if (_selectedShopId == shop.id || (fromList && !_hasMap)) {
      context.push(Paths.shop(shop.id));
      return;
    }
    setState(() => _selectedShopId = shop.id);
    if (fromList) {
      unawaited(_map.moveTo(mapPoint(shop.point)));
      if (_sheet.isAttached && _sheet.size > _sheetInitial) {
        unawaited(
          _sheet.animateTo(
            _sheetInitial,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
          ),
        );
      }
      return;
    }
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
    final hubs = ref.watch(hubsProvider).value ?? const <Hub>[];
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
    if (shops.hasValue && !shops.isLoading) _lastShops = shops.value;
    final last = _lastShops;
    // 新结果回来之前接着显示上一次的店, 不退回骨架.
    final stale = !shops.hasValue && shops.isLoading && last != null;
    final list = shops.value ?? (stale ? last : const <Shop>[]);
    // 搜索能选到离校区远的商圈, 所以在全部商圈里找.
    final selectedHub =
        hubs.where((h) => h.id == hubId).firstOrNull ??
        (myHub?.id == hubId ? myHub : null);

    final safe = MediaQuery.viewPaddingOf(context);
    final screen = MediaQuery.sizeOf(context);
    // 地图被搜索框和抽屉 (宽屏是左侧面板) 盖住的部分.
    final insets = layout.isWide
        ? EdgeInsets.only(
            left: EatLayout.widePanelInset + EatLayout.widePanelWidth,
            top: safe.top,
          )
        : EdgeInsets.only(
            top: _searchBottom(safe),
            bottom: screen.height * _sheetInitial,
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

    final search = Row(
      spacing: EatSpace.s8,
      children: [
        _HubButton(
          name: selectedHub?.name,
          floating: _hasMap,
          onTap: () => _openHubs(selectedId: hubId, campus: campus, me: me),
        ),
        Expanded(
          child: EatSearchField(
            hintText: '搜店名或地址',
            controller: _keywordInput,
            floating: _hasMap,
            onSubmitted: (value) => setState(() {
              _keyword = value.trim();
              _selectedShopId = null;
            }),
            onChanged: (value) {
              if (value.isEmpty && _keyword.isNotEmpty) {
                setState(() => _keyword = '');
              }
            },
            onFilter: () => _openFilter(query),
            filterCount: _filter.count,
          ),
        ),
      ],
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
      title: selectedHub?.name ?? '附近',
      count: shops.hasValue || stale ? list.length : null,
      loading: shops.isLoading && (shops.hasValue || stale),
    );
    final rows = _rows(shops, list, stale: stale);

    if (layout.isWide) {
      return StageScaffold.map(
        map: Stack(
          children: [
            Positioned.fill(child: map),
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
          rows,
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
                        rows,
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
    // 状态栏压在地图上, 底图跟着深浅变, 图标也跟着变.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.eat.colors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
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
            // 抽屉拉高后按钮放不下 (会压到搜索框), 就收起来.
            if (height * (1 - _sheetExtent) - EatSpace.s14 - 48 >
                _searchBottom(safe))
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
                        rows,
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

  /// 窄屏有地图时, 浮在地图上的搜索框这一行的下沿再留一段间距.
  static double _searchBottom(EdgeInsets safe) =>
      safe.top + 8 + 48 + EatSpace.s10;

  /// 店铺列表, 连同加载, 失败和空列表, 左右留页面边距.
  Widget _rows(
    AsyncValue<List<Shop>> shops,
    List<Shop> list, {
    required bool stale,
  }) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: EatSpace.s20),
    sliver: _shopList(shops, list, stale: stale),
  );

  Widget _shopList(
    AsyncValue<List<Shop>> shops,
    List<Shop> list, {
    required bool stale,
  }) {
    if (list.isEmpty || !(shops.hasValue || stale)) {
      return _states(shops, list);
    }
    return SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const ShopEntryDivider(),
      itemBuilder: (context, i) {
        final shop = list[i];
        final selected = _hasMap && shop.id == _selectedShopId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShopEntry(
              shop: shop,
              index: i,
              dishes: false,
              onTap: () => _tapShop(shop, list, fromList: true),
            ),
            if (selected)
              _EnterHint(onTap: () => context.push(Paths.shop(shop.id))),
          ],
        );
      },
    );
  }

  /// 加载中, 失败和空列表.
  Widget _states(AsyncValue<List<Shop>> shops, List<Shop> list) {
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
        child: ShopEntryPlaceholder(count: 5, dishes: false),
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
}

/// 列表头: "附近" 或选中的商圈名, 后面是店铺数量. 店铺只按距离排列, 不提供排序选项.
class _ListHeader extends StatelessWidget {
  const new({required this.title, required this.count, this.loading = false});

  final String title;
  final int? count;

  /// 正在按新的查询条件加载, 列表里还是上一次的店. 标题下面走一条加载条.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EatSpace.s20,
        0,
        EatSpace.s20,
        EatSpace.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: EatSize.touch,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$title '),
                      TextSpan(
                        text: count == null ? '' : '$count',
                        style: eat.text.stat.copyWith(fontSize: 20, height: 1),
                      ),
                      TextSpan(text: count == null ? '' : ' 家'),
                    ],
                  ),
                  style: eat.text.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(height: 2, child: loading ? const _LoadingBar() : null),
        ],
      ),
    );
  }
}

/// 加载条: 一道细的底线上来回滑一段 `ink`. 系统开启减少动态效果时只画底线和一段不动的 `ink`.
class _LoadingBar extends StatefulWidget {
  const new();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.eat.colors;
    return Semantics(
      label: '正在加载',
      liveRegion: true,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(EatRadius.pill),
        child: ColoredBox(
          color: c.hairline,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => FractionallySizedBox(
              widthFactor: 0.3,
              alignment: Alignment(
                Curves.easeInOut.transform(_controller.value) * 2.6 - 1.3,
                0,
              ),
              child: ColoredBox(color: c.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选中的那家下面的引导: "再点一次进店", 点它也进餐厅详情.
class _EnterHint extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s8),
      child: EatTappable(
        onTap: onTap,
        label: '在地图上了，再点一次进店',
        focusShape: const StadiumBorder(),
        builder: (context, _) => SizedBox(
          height: EatSize.touch,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: c.mist,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    Text(
                      '在地图上了，再点一次进店',
                      style: eat.text.meta.copyWith(
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

  /// 价位从便宜到贵, "不限" 放在最右边.
  static const _bands = <PriceBand?>[...PriceBand.values, null];
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
          EatSegmentSlider.coins(
            semanticsLabel: '价位',
            labels: [for (final band in _bands) band?.label ?? '不限'],
            allIndex: _bands.length - 1,
            selected: _bands.indexOf(_priceBand),
            onChanged: (i) => setState(() => _priceBand = _bands[i]),
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

/// 搜索框左边的商圈按钮: 选中的商圈名, 没选时写 "附近", 后面一个下拉箭头.
///
/// 和搜索框等高. 名字太长时省略, 宽度封顶, 给搜索框留出地方.
class _HubButton extends StatelessWidget {
  const new({required this.name, required this.floating, required this.onTap});

  /// 选中的商圈名. 为 null 时是 "附近".
  final String? name;

  /// 浮在地图上时 `paper` 底加 `shadow-float`, 和搜索框一致; 否则 `mist` 底.
  final bool floating;
  final VoidCallback onTap;

  static const _maxWidth = 128.0;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final c = eat.colors;
    final label = name ?? '附近';
    return EatTappable(
      onTap: onTap,
      label: '商圈，$label',
      focusShape: const StadiumBorder(),
      builder: (context, _) => Container(
        height: 48,
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        padding: const EdgeInsets.only(left: EatSpace.s16, right: 10),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: floating ? c.paper : c.mist,
          shadows: floating ? eat.shadows.float.outer : null,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eat.text.subhead.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
              EatIcon(EatIcons.chevronDown, size: 18, color: c.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// "选商圈" 面板: 顶部按名字搜, 下面是 "最近" 和 "全部" 两组胶囊. 点一个就关上面板, 返回选中的商圈, "附近" 返回 null.
///
/// - 没输入时只列离校区不远的商圈; 输入后在全部商圈里找, 校区外的也能搜到.
/// - 商圈按离我的距离排, 没有定位时按离校区中心排.
class _HubPanel extends ConsumerStatefulWidget {
  const new({required this.selectedId, required this.campus, required this.me});

  /// 当前选中的商圈, 为 null 时是 "附近".
  final int? selectedId;
  final Campus? campus;
  final GcjPoint? me;

  @override
  ConsumerState<_HubPanel> createState() => _HubPanelState();
}

class _HubPanelState extends ConsumerState<_HubPanel> {
  var _query = '';

  void _pick(Hub? hub) => Navigator.of(context).pop((hub: hub));

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final campus = widget.campus;
    final origin = widget.me ?? campus?.center;
    final all = ref.watch(hubsProvider).value ?? const <Hub>[];
    final recentIds = ref.watch(recentHubsProvider).value ?? const <int>[];
    final query = _query.trim();
    double? distance(Hub hub) =>
        origin == null ? null : GeoRules.distance(origin, hub.center);
    final hubs = [
      for (final hub in all)
        if (query.isEmpty
            ? campus == null ||
                  GeoRules.distance(hub.center, campus.center) <=
                      GeoRules.maxDistanceFromCampus
            : hub.name.contains(query))
          hub,
    ];
    if (origin != null) {
      hubs.sort((a, b) => distance(a)!.compareTo(distance(b)!));
    }
    final byId = {for (final hub in all) hub.id: hub};
    final recent = [for (final id in recentIds) ?byId[id]];

    Widget option(Hub hub) => EatOption(
      label: hub.name,
      detail: switch (distance(hub)) {
        final meters? => GeoRules.formatDistance(meters),
        null => null,
      },
      pill: true,
      selected: hub.id == widget.selectedId,
      onTap: () => _pick(hub),
    );
    Widget group(String label, List<Widget> children) => EatRadioGroup(
      label: label,
      child: Wrap(
        spacing: EatSpace.s8,
        runSpacing: EatSpace.s8,
        children: children,
      ),
    );

    return EatPanel(
      title: '选商圈',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatSearchField(
            hintText: '搜商圈',
            onChanged: (value) => setState(() => _query = value),
            onSubmitted: (value) => setState(() => _query = value),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: EatSpace.s16),
            if (hubs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: EatSpace.s8),
                child: Text(
                  '没找到「$query」',
                  style: eat.text.body.copyWith(color: eat.colors.inkMuted),
                ),
              )
            else
              group('搜索结果', [for (final hub in hubs) option(hub)]),
          ] else ...[
            if (recent.isNotEmpty) ...[
              const _HubGroupTitle('最近'),
              group('最近', [for (final hub in recent) option(hub)]),
            ],
            const _HubGroupTitle('全部'),
            group('全部', [
              EatOption(
                label: '附近',
                pill: true,
                selected: widget.selectedId == null,
                onTap: () => _pick(null),
              ),
              for (final hub in hubs) option(hub),
            ]),
          ],
        ],
      ),
    );
  }
}

/// "选商圈" 面板里一组胶囊的标题.
class _HubGroupTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Padding(
      padding: const EdgeInsets.only(top: EatSpace.s16, bottom: EatSpace.s8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: eat.text.subhead.copyWith(color: eat.colors.ink),
        ),
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
      dark: eat.colors.isDark,
      markers: markers,
      polygons: [
        if (hub case final hub?)
          for (final (i, ring) in hub.boundary.indexed)
            MapPolygon(
              id: 'hub-${hub.id}-$i',
              points: [for (final p in ring) mapPoint(p)],
              fill: StageColor.broth.color.withValues(alpha: 0.24),
              // 描边要和底图拉开: 浅色底图上用深色, 深灰底图上用浅色.
              stroke: eat.colors.isDark ? eat.colors.inkSoft : eat.colors.shade,
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
