import 'package:eat/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'eat_map_io.dart'
    if (dart.library.js_interop) 'eat_map_web.dart'
    as platform;

part 'eat_map.g.dart';

/// 地图上的一点, 坐标系是 GCJ-02.
///
/// `core` 不能依赖 `domain`, 所以不直接用 `GcjPoint`. 两者的互转在 `features/system/base_map.dart`.
class const MapLatLng(final double lat, final double lng) {
  @override
  bool operator ==(Object other) =>
      other is MapLatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'MapLatLng($lat, $lng)';
}

/// 地图上的一个地点, 来自地点检索. [uid] 是百度地点的唯一标识.
class const MapPoi({
  required final String uid,
  required final String name,
  required final String address,
  required final MapLatLng point,
});

class const MapCamera({
  required final MapLatLng center,
  required final double zoom,
});

/// 标记的图片: 按 [scale] 倍绘制的 PNG.
///
/// [anchor] 是图片里对准坐标的那一点, 用 0–1 的比例表示.
/// 同一张图应复用同一个实例: 比较标记是否变化时只看是不是同一个实例, 不比较字节.
class MarkerImage({
  required final Uint8List png,
  required final double scale,
  required final Size size,
  required final Offset anchor,
});

class const MapMarker({
  required final String id,
  required final MapLatLng point,
  required final MarkerImage image,
  final int zIndex = 0,
}) {
  /// 两个同 id 的标记看起来是否一样.
  bool sameAs(MapMarker other) =>
      point == other.point &&
      identical(image, other.image) &&
      zIndex == other.zIndex;
}

class const MapPolygon({
  required final String id,
  required final List<MapLatLng> points,
  required final Color fill,
  required final Color stroke,
  final double strokeWidth = 1.5,
  final bool dashed = false,
}) {
  @override
  bool operator ==(Object other) =>
      other is MapPolygon &&
      other.id == id &&
      listEquals(other.points, points) &&
      other.fill == fill &&
      other.stroke == stroke &&
      other.strokeWidth == strokeWidth &&
      other.dashed == dashed;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(points),
    fill,
    stroke,
    strokeWidth,
    dashed,
  );
}

/// 从 [before] 变成 [after] 要新增或修改的标记, 和要删掉的标记 id.
({List<MapMarker> upserts, List<String> removed}) diffMarkers(
  List<MapMarker> before,
  List<MapMarker> after,
) {
  final old = {for (final m in before) m.id: m};
  final next = {for (final m in after) m.id: m};
  return (
    upserts: [
      for (final m in after)
        if (!(old[m.id]?.sameAs(m) ?? false)) m,
    ],
    removed: [
      for (final id in old.keys)
        if (!next.containsKey(id)) id,
    ],
  );
}

/// 操作一张地图. 地图还没建好时, 调用什么也不做.
class EatMapController {
  MapHandle? _handle;

  /// 把 [center] 移到可见区域的中心. [zoom] 为 null 时不改缩放级别.
  Future<void> moveTo(MapLatLng center, {double? zoom, bool animated = true}) =>
      _handle?.moveTo(center, zoom: zoom, animated: animated) ?? Future.value();

  /// 缩放到刚好装下 [points], 四周再各留 [margin].
  Future<void> fit(
    List<MapLatLng> points, {
    EdgeInsets margin = const EdgeInsets.all(40),
    bool animated = true,
  }) =>
      _handle?.fit(points, margin: margin, animated: animated) ??
      Future.value();

  /// 当前的相机. 地图还没建好时为 null.
  Future<MapCamera?> camera() => _handle?.camera() ?? Future.value();
}

/// 引擎实现的地图操作, 由 [EatMapController] 转发.
abstract interface class MapHandle {
  Future<void> moveTo(MapLatLng center, {double? zoom, bool animated});

  Future<void> fit(
    List<MapLatLng> points, {
    required EdgeInsets margin,
    bool animated,
  });

  Future<MapCamera?> camera();
}

/// 引擎实现在建好地图后调用, 把自己交给控制器.
void attachMapHandle(EatMapController controller, MapHandle? handle) =>
    controller._handle = handle;

/// 声明式的地图. 页面每次 build 给出完整的标记和多边形, 由引擎比较新旧后只改变化的部分.
///
/// - 跟着地理坐标走的东西 (标记, 范围) 交给地图引擎画, 拖动时和底图一起动.
///   固定在屏幕上的东西 (搜索框, 按钮, 图钉) 由页面叠在地图上面.
/// - [insets] 是被浮层盖住的部分. 引擎把 logo 和比例尺移进剩下的可见区域,
///   相机的中心也指可见区域的中心.
/// - 只在用户同意隐私政策之后显示: 第一次显示时才初始化百度地图 SDK.
/// - 引擎画的标记不在语义树里. 地图整体用 [semanticLabel] 朗读, 页面要另给按钮替代.
class EatMap extends ConsumerWidget {
  const new({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 16,
    this.minZoom = 11,
    this.maxZoom = 18,
    this.insets = EdgeInsets.zero,
    this.markers = const [],
    this.polygons = const [],
    this.onCameraIdle,
    this.onMarkerTap,
    this.onFailed,
    this.semanticLabel = '地图',
  });

  final EatMapController controller;
  final MapLatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final EdgeInsets insets;
  final List<MapMarker> markers;
  final List<MapPolygon> polygons;

  /// 地图停止移动. [byGesture] 为 false 表示由代码移动.
  final void Function(MapCamera camera, bool byGesture)? onCameraIdle;
  final ValueChanged<String>? onMarkerTap;

  /// 鉴权失败, 渲染失败或迟迟加载不出来. 页面据此退回列表.
  final VoidCallback? onFailed;
  final String semanticLabel;

  /// 打开地图后多久还没加载完就算失败.
  static const loadTimeout = Duration(seconds: 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    label: semanticLabel,
    container: true,
    child: ExcludeSemantics(child: ref.watch(mapEngineProvider).build(this)),
  );
}

/// 一种地图实现. App 是百度地图原生 SDK, Web 是百度地图 JS API GL, 测试里换成假实现.
abstract interface class MapEngine {
  /// 能否显示地图. 当前平台没有 AK 时为 false, 页面只显示列表.
  bool get available;

  Widget build(EatMap map);

  /// [center] 周围 [radius] 米内和 [keyword] 匹配的地点, 最多 20 个. 公交站和地铁站不算.
  /// 没有结果时返回空列表, 检索失败时抛出异常. 只在 [available] 时调用.
  Future<List<MapPoi>> searchNearby(
    String keyword,
    MapLatLng center, {
    required int radius,
  });
}

/// 当前平台的地图实现. 测试中用 `overrideWithValue` 替换.
@Riverpod(keepAlive: true)
MapEngine mapEngine(Ref ref) =>
    platform.createMapEngine(ref.watch(appConfigProvider));
