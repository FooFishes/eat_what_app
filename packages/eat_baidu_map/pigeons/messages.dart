/// Dart 与原生之间的接口定义. 修改后须在本包目录运行
/// `fvm dart run pigeon --input pigeons/messages.dart` 重新生成三端代码.
///
/// 坐标统一使用 GCJ-02, SDK 初始化时会配置全局坐标类型.
/// 长度单位均为逻辑像素, 由原生侧按屏幕密度换算.
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

  /// 可见区域中心的坐标, 即扣除 [InsetsMessage] 遮挡区域后的中心点.
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

  /// PNG 图像字节, 原生侧按 [iconScale] 缩放还原为逻辑尺寸.
  Uint8List icon;
  double iconScale;

  /// 锚点在图片内的归一化位置 (0–1), 用于对准 [position].
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

/// 地点检索的单条结果.
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

  /// 坐标类型与地图一致, 由初始化时设置的全局坐标类型决定.
  LatLngMessage location;
}

/// SDK 级别调用, 须在同意隐私政策后调用 [initialize], 整个进程仅需一次.
@HostApi()
abstract class SdkHostApi {
  /// 依次配置隐私政策同意状态, GCJ-02 坐标类型与 AK, 然后启动 SDK.
  ///
  /// 鉴权结果通过 [SdkFlutterApi.onAuthResult] 异步返回.
  void initialize(String apiKey);
}

@FlutterApi()
abstract class SdkFlutterApi {
  /// [code] 为 0 表示鉴权通过, 其余为百度错误码.
  void onAuthResult(int code, String message);
}

/// 单张地图实例的调用接口. 每个平台视图使用独立通道, 以平台视图 ID 作为后缀.
@HostApi()
abstract class MapViewHostApi {
  /// 新增或更新 [upserts] 中的标记, 并移除 [removedIds] 中的标记.
  void updateMarkers(List<MarkerMessage> upserts, List<String> removedIds);

  /// 使用 [polygons] 替换地图上的全部多边形.
  void setPolygons(List<PolygonMessage> polygons);

  /// 设置地图被浮层遮挡的边距, logo, 比例尺与地图中心将移至剩余可见区域.
  void setInsets(InsetsMessage insets);

  /// 将 [center] 移至可见区域中心; [zoom] 为 null 时保持当前缩放级别.
  void moveCamera(LatLngMessage center, double? zoom, bool animated);

  /// 缩放至刚好完整显示 [points], 四周各留出 [margin] 边距.
  void fitPoints(
    List<LatLngMessage> points,
    InsetsMessage margin,
    bool animated,
  );

  CameraMessage getCamera();

  /// 换成 Flutter 资源 [asset] 里的个性化样式 (`.sty`); 为 null 时换回百度默认样式.
  void setCustomStyle(String? asset);

  /// 底图是否已加载完成. Dart 端在平台视图创建后才开始监听事件, 可能错过 [MapViewFlutterApi.onLoaded].
  bool isLoaded();
}

@FlutterApi()
abstract class MapViewFlutterApi {
  void onLoaded();

  /// 地图停止移动时触发; [byGesture] 表示此次移动是否由用户手势引发.
  void onCameraIdle(CameraMessage camera, bool byGesture);

  void onMarkerTap(String id);

  /// 地图数据无效或渲染失败时触发, 例如 AK 无效.
  void onError(int code, String message);
}

/// 地点检索接口, 与地图共用同一次 SDK 初始化, 不依赖具体地图视图.
@HostApi()
abstract class PlaceSearchHostApi {
  /// 搜索 [center] 周围 [radius] 米内名称或地址匹配 [keyword] 的地点, 最多返回 [pageSize] 条.
  ///
  /// 无匹配结果时返回空列表, 检索失败时抛出异常.
  @async
  List<PlaceMessage> searchNearby(
    String keyword,
    LatLngMessage center,
    int radius,
    int pageSize,
  );
}
