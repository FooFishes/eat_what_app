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

/// 地图标记图标, 包含按 [scale] 倍率绘制的 PNG 字节与布局信息.
///
/// [anchor] 为对齐地理坐标的归一化锚点 (0–1 比例).
/// 相同图标应复用同一 [MarkerImage] 实例, 标记变更比对仅校验实例引用而非字节内容.
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
  /// 判断同一 id 的两个标记在视觉与位置上是否完全一致.
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

/// 计算从 [before] 更新至 [after] 所需新增或修改的标记列表及待移除的标记 id.
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

/// 地图控制器, 在地图尚未就绪时调用其方法均为空操作.
class EatMapController {
  MapHandle? _handle;

  /// 将 [center] 移动至可见区域中心, [zoom] 为 null 时保持当前缩放级别.
  Future<void> moveTo(MapLatLng center, {double? zoom, bool animated = true}) =>
      _handle?.moveTo(center, zoom: zoom, animated: animated) ?? Future.value();

  /// 调整视野以完整容纳 [points], 并在四周保留 [margin] 边距.
  Future<void> fit(
    List<MapLatLng> points, {
    EdgeInsets margin = const EdgeInsets.all(40),
    bool animated = true,
  }) =>
      _handle?.fit(points, margin: margin, animated: animated) ??
      Future.value();

  /// 获取当前相机状态, 地图尚未就绪时返回 null.
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

/// 供地图引擎在初始化完成后向 [EatMapController] 绑定底层操作句柄.
void attachMapHandle(EatMapController controller, MapHandle? handle) =>
    controller._handle = handle;

/// 声明式地图组件, 页面每次 build 传入全量标记与多边形, 由引擎比对差异后增量更新.
///
/// - 随地理坐标移动的元素 (标记, 多边形) 交由地图引擎绘制; 固定于屏幕的控件 (搜索框, 按钮, 中心图钉) 由页面叠加在其上方.
/// - [insets] 为被浮层遮挡的区域, 引擎据此将 logo 与比例尺避让至可见区域, 相机中心亦对准可见区域中心.
/// - 仅可在用户同意隐私政策后渲染, 首次挂载时才会初始化百度地图 SDK.
/// - 引擎绘制的标记不进入无障碍语义树, 地图整体通过 [semanticLabel] 朗读, 页面需另行提供可交互的按钮替代.
class EatMap extends ConsumerWidget {
  const new({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 16,
    this.minZoom = 11,
    this.maxZoom = 18,
    this.insets = EdgeInsets.zero,
    this.dark = false,
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

  /// 用深灰的底图样式. 页面按深浅模式传入, 改了原地换样式, 不重建地图.
  final bool dark;
  final List<MapMarker> markers;
  final List<MapPolygon> polygons;

  /// 地图停止移动回调, [byGesture] 为 false 表示由代码触发移动.
  final void Function(MapCamera camera, bool byGesture)? onCameraIdle;
  final ValueChanged<String>? onMarkerTap;

  /// 鉴权, 渲染失败或加载超时回调, 页面据此降级回列表视图.
  final VoidCallback? onFailed;
  final String semanticLabel;

  /// 地图初始化后判定为加载超时的等待上限.
  static const loadTimeout = Duration(seconds: 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    label: semanticLabel,
    container: true,
    child: ExcludeSemantics(child: ref.watch(mapEngineProvider).build(this)),
  );
}

/// 地图引擎接口, App 端对应百度地图原生 SDK, Web 端对应百度地图 JS API GL, 测试中可替换为桩实现.
abstract interface class MapEngine {
  /// 地图引擎是否可用, 当平台未配置 AK 时返回 false, 页面据此仅展示列表.
  bool get available;

  Widget build(EatMap map);

  /// 检索 [center] 周围 [radius] 米内匹配 [keyword] 的地点 (最多 20 个, 已过滤公交站与地铁站).
  ///
  /// 无匹配结果时返回空列表, 检索异常时抛出错误, 仅应在 [available] 为 true 时调用.
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
