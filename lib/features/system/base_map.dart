import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/map_tiles.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// 附近页和新建店页共用的底图: 天地图矢量底图和注记.
///
/// 放在 `FlutterMap.children` 的第一项, 商圈和标记叠加在其上.
class BaseMapLayers extends ConsumerWidget {
  const new({super.key, this.onTileError});

  /// 瓦片加载失败时调用. 页面据此计数, 失败次数达到阈值后改为只显示列表.
  final VoidCallback? onTileError;

  /// 底图的调色矩阵: 略微降低饱和度并提高暖色, 使底图接近 `map-ground` 的色调.
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
      tileProvider: NetworkTileProvider(headers: mapTileHeaders()),
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

/// 把 GCJ-02 坐标转换为天地图使用的 WGS-84 坐标.
///
/// 天地图瓦片使用 WGS-84, 直接放入 GCJ-02 坐标会偏移数百米.
LatLng mapPoint(GcjPoint point) {
  final w = GeoRules.toWgs(point);
  return LatLng(w.lat, w.lng);
}

/// 把地图上的 WGS-84 坐标转换为接口使用的 GCJ-02 坐标.
GcjPoint gcjOf(LatLng point) =>
    GeoRules.toGcj(WgsPoint(point.latitude, point.longitude));

// TODO: 天地图要求同时显示审图号, 目前只显示 "© 天地图". 取得正式 Key 后按控制台提供的审图号补上.
/// 使用天地图瓦片时必须显示的标识.
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
