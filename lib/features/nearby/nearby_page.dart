import 'dart:async';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/env/pending_features.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/platform/location.dart';
import 'package:eat/design/icons/eat_icon.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/layout/eat_layout.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/design/widgets/eat_chip.dart';
import 'package:eat/design/widgets/eat_search_field.dart';
import 'package:eat/design/widgets/eat_sheet.dart';
import 'package:eat/design/widgets/eat_tappable.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/map_pin.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/stage_scaffold.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/features/nearby/nearby_providers.dart';
import 'package:eat/features/system/base_map.dart';
import 'package:eat/features/system/guard.dart';
import 'package:eat/features/system/shop_row.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/location.dart';
import 'package:eat/state/place.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// 附近（`G-Nearby`）：地图当舞台，每家店一个圆形标记，下面可拖动的抽屉列出附近的店。
///
/// 顶部是搜索框和筛选，下面一排商圈胶囊；右下「回到我的位置」。拖动地图后按新的中心重新找店。
/// 地图用天地图瓦片（技术架构 14.4）：没配 Key 或瓦片连着加载失败时只显示列表。
/// 筛选、按菜名找店、按推荐率和菜数排序还没有接口，带「待接入」。
class NearbyPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  final _map = MapController();
  final _sheet = DraggableScrollableController();
  final _keywordInput = TextEditingController();
  ScrollController? _list;

  /// 地图现在的中心；拖动停下 400ms 后才更新，用它找店。还没定下来时为 null。
  GcjPoint? _center;
  Timer? _moveDebounce;

  /// 点了胶囊的商圈；[_hubTouched] 之前跟着「我所在的商圈」走。
  int? _hubId;
  var _hubTouched = false;

  int? _selectedShopId;
  var _keyword = '';
  var _mapFailed = false;
  var _tileErrors = 0;

  /// 抽屉现在占屏幕高度的比例，「回到我的位置」跟着抽屉上沿走。
  var _sheetExtent = _sheetInitial;

  static const _sheetInitial = 0.42;
  static const _zoom = 16.0;

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _map.dispose();
    _sheet.dispose();
    _keywordInput.dispose();
    super.dispose();
  }

  bool get _hasMap =>
      !_mapFailed && ref.read(appConfigProvider).tiandituKey.isNotEmpty;

  void _onTileError() {
    if (_mapFailed || ++_tileErrors < 8) return;
    setState(() => _mapFailed = true);
    showToast(context, '地图加载失败，已切换为列表');
  }

  void _onMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final c = camera.center;
      setState(
        () => _center = GeoRules.toGcj(WgsPoint(c.latitude, c.longitude)),
      );
    });
  }

  void _moveTo(GcjPoint point, {double zoom = _zoom}) {
    if (!_hasMap) {
      setState(() => _center = point);
      return;
    }
    final w = GeoRules.toWgs(point);
    _map.move(LatLng(w.lat, w.lng), zoom);
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
      final points = [
        for (final ring in hub.boundary)
          for (final p in ring) LatLng(p.lat, p.lng),
      ];
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(40, 160, 40, 320),
        ),
      );
      setState(() => _center = hub.center);
    } else {
      _moveTo(hub.center);
    }
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
      list.animateTo(
        (64.0 + 18) * index,
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
    final query = NearbyQuery(center: center, hubId: hubId, keyword: _keyword);
    final shops = ref.watch(nearbyShopsProvider(query));
    final list = shops.value ?? const <Shop>[];
    final selectedHub = hubs.where((h) => h.id == hubId).firstOrNull;

    final map = _hasMap
        ? _NearbyMap(
            controller: _map,
            initialCenter: center,
            me: me,
            shops: list,
            selectedShopId: _selectedShopId,
            hub: selectedHub,
            onMoved: _onMoved,
            onTileError: _onTileError,
            onShopTap: (shop) => _tapShop(shop, list),
            attribution: layout.isWide,
          )
        : ColoredBox(color: context.eat.colors.mapGround);

    final search = EatSearchField(
      hintText: '搜店名',
      controller: _keywordInput,
      floating: true,
      onSubmitted: (value) => setState(() {
        _keyword = value.trim();
        _selectedShopId = null;
      }),
      onChanged: (value) {
        if (value.isEmpty && _keyword.isNotEmpty) setState(() => _keyword = '');
      },
      onFilter: () => showPending(context, PendingFeature.nearbyFilter),
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
              child: EatChip.district(
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

    final media = MediaQuery.of(context);
    final navInset = NavBarInset.of(context);
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
          if (_hasMap)
            Positioned(
              left: EatSpace.s16,
              bottom: height * _sheetExtent + 6,
              child: const MapAttribution(),
            ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (n) {
              setState(() => _sheetExtent = n.extent);
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
    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EatSpace.s24),
          child: EmptyState(
            icon: EatIcons.store,
            title: _keyword.isEmpty ? '这附近还没有店' : '没找到「$_keyword」',
            message: _keyword.isEmpty ? '拖动地图看看别处，或者换个商圈。' : '换个店名试试。',
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

/// 「附近 18 家」和排序。只有「按距离」能用，其余排序待接入。
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
              style: eat.text.sectionTitle,
            ),
          ),
          const Spacer(),
          EatChip.choice('按距离', selected: true, onTap: () {}),
          const SizedBox(width: EatSpace.s8),
          EatChip.choice(
            '推荐率',
            selected: false,
            onTap: () => showPending(context, PendingFeature.nearbyFilter),
          ),
        ],
      ),
    );
  }
}

/// 天地图底图加注记，上面是商圈范围、店铺标记和我的位置。禁止旋转。
class _NearbyMap extends ConsumerWidget {
  const new({
    required this.controller,
    required this.initialCenter,
    required this.me,
    required this.shops,
    required this.selectedShopId,
    required this.hub,
    required this.onMoved,
    required this.onTileError,
    required this.onShopTap,
    this.attribution = true,
  });

  final MapController controller;
  final GcjPoint initialCenter;
  final GcjPoint? me;
  final List<Shop> shops;
  final int? selectedShopId;
  final Hub? hub;
  final PositionCallback onMoved;
  final VoidCallback onTileError;
  final ValueChanged<Shop> onShopTap;

  /// 天地图要求显示的标识。手机上抽屉会盖住地图底部，由页面画在抽屉上沿。
  final bool attribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eat = context.eat;
    final ring = StageColor.broth.color;
    final selected = shops.where((s) => s.id == selectedShopId);
    final others = shops.where((s) => s.id != selectedShopId);
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: mapPoint(initialCenter),
        initialZoom: 16,
        minZoom: 11,
        maxZoom: 18,
        backgroundColor: eat.colors.mapGround,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: onMoved,
      ),
      children: [
        BaseMapLayers(onTileError: onTileError),
        if (hub case final hub? when hub.boundary.isNotEmpty)
          PolygonLayer(
            polygons: [
              for (final ring in hub.boundary)
                Polygon(
                  points: [for (final p in ring) LatLng(p.lat, p.lng)],
                  color: StageColor.broth.color.withValues(alpha: 0.24),
                  borderColor: eat.colors.ink,
                  borderStrokeWidth: 1.5,
                  pattern: StrokePattern.dashed(segments: const [6, 4]),
                ),
            ],
          ),
        MarkerLayer(
          markers: [
            // 选中的那家最后画，压在别的标记上面。
            for (final shop in [...others, ...selected])
              Marker(
                point: mapPoint(shop.point),
                width: MapPin.size.width,
                height: MapPin.size.height,
                alignment: Alignment.center,
                child: Align(
                  alignment: const Alignment(0, -0.2),
                  child: MapPin(
                    name: shop.name,
                    image: networkImage(shop.photos.firstOrNull, width: 64),
                    selected: shop.id == selectedShopId,
                    ring: ring,
                    onTap: () => onShopTap(shop),
                  ),
                ),
              ),
            if (me case final me?)
              Marker(
                point: mapPoint(me),
                width: MyLocationDot.size,
                height: MyLocationDot.size,
                child: const IgnorePointer(child: MyLocationDot()),
              ),
          ],
        ),
        if (attribution)
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(padding: EdgeInsets.all(6), child: MapAttribution()),
          ),
      ],
    );
  }
}
