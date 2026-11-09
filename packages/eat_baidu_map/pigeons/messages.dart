/// Dart 与原生之间的接口定义. 改完后在本包目录运行
/// `fvm dart run pigeon --input pigeons/messages.dart` 重新生成三端代码.
///
/// 坐标一律是 GCJ-02: SDK 初始化时把全局坐标类型设成 GCJ-02.
/// 长度一律是逻辑像素, 由原生侧按屏幕密度换算.
library;

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'eat_baidu_map',
    kotlinOut: 'android/src/main/kotlin/you/v50to/eat/baidu_map/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'you.v50to.eat.baidu_map'),
    swiftOut: 'ios/eat_baidu_map/Sources/eat_baidu_map/Messages.g.swift',
  ),
)
class LatLngMessage {
  LatLngMessage({required this.lat, required this.lng});

  double lat;
  double lng;
}

class CameraMessage {
  CameraMessage({required this.center, required this.zoom});

  /// 可见区域中心的坐标, 即扣掉 [InsetsMessage] 之后那块区域的中心.
  LatLngMessage center;
  double zoom;
}

class InsetsMessage {
  InsetsMessage({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double left;
  double top;
  double right;
  double bottom;
}

class MarkerMessage {
  MarkerMessage({
    required this.id,
    required this.position,
    required this.icon,
    required this.iconScale,
    required this.anchorX,
    required this.anchorY,
    required this.zIndex,
  });

  String id;
  LatLngMessage position;

  /// PNG. 按 [iconScale] 倍绘制, 原生侧据此还原成逻辑尺寸.
  Uint8List icon;
  double iconScale;

  /// 锚点在图片内的位置, 0–1, 对准 [position].
  double anchorX;
  double anchorY;
  int zIndex;
}

class PolygonMessage {
  PolygonMessage({
    required this.id,
    required this.points,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.dashed,
  });

  String id;
  List<LatLngMessage> points;

  /// ARGB.
  int fillColor;
  int strokeColor;
  double strokeWidth;
  bool dashed;
}

/// SDK 级别的调用. 同意隐私政策之后调用 [initialize], 整个进程只需一次.
/// 地点检索的一条结果.
class PlaceMessage {
  PlaceMessage({
    required this.uid,
    required this.name,
    required this.address,
    required this.location,
  });

  /// 百度地点的唯一标识.
  String uid;
  String name;
  String address;

  /// 坐标类型和地图一样, 由初始化时设置的全局坐标类型决定.
  LatLngMessage location;
}

@HostApi()
abstract class SdkHostApi {
  /// 依次设置同意隐私政策, GCJ-02 坐标类型和 AK, 然后启动 SDK.
  ///
  /// 鉴权结果异步回到 [SdkFlutterApi.onAuthResult].
  void initialize(String apiKey);
}

@FlutterApi()
abstract class SdkFlutterApi {
  /// [code] 为 0 表示鉴权通过, 其余是百度的错误码.
  void onAuthResult(int code, String message);
}

/// 单张地图的调用. 每个平台视图用自己的通道, 通道后缀是平台视图 id.
@HostApi()
abstract class MapViewHostApi {
  /// 新增或更新 [upserts] 中的标记, 删除 [removedIds] 中的标记.
  void updateMarkers(List<MarkerMessage> upserts, List<String> removedIds);

  /// 用 [polygons] 替换地图上全部的多边形.
  void setPolygons(List<PolygonMessage> polygons);

  /// 地图被浮层盖住的部分. logo, 比例尺和地图中心都移到剩下的区域.
  void setInsets(InsetsMessage insets);

  /// 把 [center] 移到可见区域中心. [zoom] 为 null 时不改缩放级别.
  void moveCamera(LatLngMessage center, double? zoom, bool animated);

  /// 缩放到刚好装下 [points], 四周再各留 [margin].
  void fitPoints(
    List<LatLngMessage> points,
    InsetsMessage margin,
    bool animated,
  );

  CameraMessage getCamera();

  /// 底图是否已经加载完. Dart 在平台视图创建后才开始收事件, 可能错过 [MapViewFlutterApi.onLoaded].
  bool isLoaded();
}

@FlutterApi()
abstract class MapViewFlutterApi {
  void onLoaded();

  /// 地图停止移动. [byGesture] 表示这次移动由用户手势触发.
  void onCameraIdle(CameraMessage camera, bool byGesture);

  void onMarkerTap(String id);

  /// 地图数据无效或渲染失败, 例如 AK 无效时.
  void onError(int code, String message);
}

/// 地点检索. 和地图共用一次 SDK 初始化, 不依赖地图视图.
@HostApi()
abstract class PlaceSearchHostApi {
  /// [center] 周围 [radius] 米内名字或地址和 [keyword] 匹配的地点, 最多 [pageSize] 条.
  /// 没有结果时返回空列表, 检索失败时报错.
  @async
  List<PlaceMessage> searchNearby(
    String keyword,
    LatLngMessage center,
    int radius,
    int pageSize,
  );
}
