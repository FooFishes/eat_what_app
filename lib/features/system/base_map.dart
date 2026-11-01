import 'package:eat/core/config/app_config.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// 附近页和新建店共用的底图：天地图矢量底图加注记（技术架构 14.4）。放在 `FlutterMap` 的
/// `children` 最前面，上面再叠商圈、标记。
class BaseMapLayers extends ConsumerWidget {
  const new({super.key, this.onTileError});

  /// 瓦片加载失败时调用，页面数够了次数就退回只有列表。
  final VoidCallback? onTileError;

  /// 底图整体往 `map-ground` 的暖色靠一点：稍微降饱和、提暖（技术架构 14.4）。
  static const _warm = ColorFilter.matrix([
    0.95, 0.05, 0.0, 0, 6, //
    0.03, 0.92, 0.03, 0, 4, //
    0.02, 0.06, 0.82, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(appConfigProvider).tiandituKey;
    TileLayer tiles(String layer) => TileLayer(
      urlTemplate:
          'https://t{s}.tianditu.gov.cn/DataServer?T=$layer&x={x}&y={y}&l={z}&tk=$key',
      subdomains: const ['0', '1', '2', '3', '4', '5', '6', '7'],
      userAgentPackageName: 'you.v50to.eat',
      errorTileCallback: (_, _, _) => onTileError?.call(),
    );
    return Stack(
      children: [
        ColorFiltered(colorFilter: _warm, child: tiles('vec_w')),
        tiles('cva_w'),
      ],
    );
  }
}

/// GCJ-02 的点放到天地图上要先转回 WGS-84（技术架构 14.1）。
LatLng mapPoint(GcjPoint point) {
  final w = GeoRules.toWgs(point);
  return LatLng(w.lat, w.lng);
}

/// 地图上的位置转回 GCJ-02，用来调接口。
GcjPoint gcjOf(LatLng point) =>
    GeoRules.toGcj(WgsPoint(point.latitude, point.longitude));

/// 「© 天地图」：用天地图的瓦片要显示的标识（技术架构 14.4）。审图号等拿到 Key 时按控制台给的补上。
class MapAttribution extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    return Text(
      '© 天地图',
      style: eat.text.caption.copyWith(
        fontSize: 10,
        color: eat.colors.inkMuted,
      ),
    );
  }
}
