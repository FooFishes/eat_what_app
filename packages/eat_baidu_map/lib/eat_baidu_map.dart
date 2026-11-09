/// 百度地图原生桥: Android 和 iOS 上的百度地图平台视图.
///
/// 只做转发, 不含业务: 标记的差异比较, 坐标类型和失败回退都由 App 的 `core/platform/map/` 处理.
library;

import 'dart:async';

import 'package:eat_baidu_map/src/messages.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

export 'src/messages.g.dart'
    show
        CameraMessage,
        InsetsMessage,
        LatLngMessage,
        MarkerMessage,
        PlaceMessage,
        PolygonMessage;

/// 百度地图 SDK. 同意隐私政策之后调用 [initialize], 整个进程只需一次.
abstract final class BaiduMapSdk {
  static final _auth = Completer<(int, String)>();
  static Future<void>? _starting;

  /// 鉴权结果. 第一个值为 0 表示通过, 其余是百度的错误码.
  static Future<(int, String)> get authResult => _auth.future;

  static Future<void> initialize(String apiKey) =>
      _starting ??= _initialize(apiKey);

  static Future<void> _initialize(String apiKey) async {
    SdkFlutterApi.setUp(_AuthListener());
    await SdkHostApi().initialize(apiKey);
  }
}

/// 百度地点检索. 要先 [BaiduMapSdk.initialize].
abstract final class BaiduPlaceSearch {
  static final _api = PlaceSearchHostApi();

  /// [center] 周围 [radius] 米内和 [keyword] 匹配的地点, 最多 [pageSize] 条 (百度上限 20).
  static Future<List<PlaceMessage>> searchNearby(
    String keyword,
    LatLngMessage center, {
    required int radius,
    int pageSize = 20,
  }) => _api.searchNearby(keyword, center, radius, pageSize);
}

class _AuthListener implements SdkFlutterApi {
  @override
  void onAuthResult(int code, String message) {
    if (!BaiduMapSdk._auth.isCompleted) {
      BaiduMapSdk._auth.complete((code, message));
    }
  }
}

/// 一张百度地图的事件.
class BaiduMapListener {
  const new({this.onLoaded, this.onCameraIdle, this.onMarkerTap, this.onError});

  final VoidCallback? onLoaded;
  final void Function(CameraMessage camera, bool byGesture)? onCameraIdle;
  final ValueChanged<String>? onMarkerTap;
  final void Function(int code, String message)? onError;
}

/// 平台视图创建后交给 [BaiduMapView.onCreated], 用来操作这张地图.
class BaiduMapController {
  BaiduMapController._(int id)
    : _api = MapViewHostApi(messageChannelSuffix: '$id');

  final MapViewHostApi _api;

  Future<void> updateMarkers(
    List<MarkerMessage> upserts,
    List<String> removedIds,
  ) => _api.updateMarkers(upserts, removedIds);

  Future<void> setPolygons(List<PolygonMessage> polygons) =>
      _api.setPolygons(polygons);

  Future<void> setInsets(InsetsMessage insets) => _api.setInsets(insets);

  Future<void> moveCamera(
    LatLngMessage center, {
    double? zoom,
    bool animated = true,
  }) => _api.moveCamera(center, zoom, animated);

  Future<void> fitPoints(
    List<LatLngMessage> points, {
    required InsetsMessage margin,
    bool animated = true,
  }) => _api.fitPoints(points, margin, animated);

  Future<CameraMessage> getCamera() => _api.getCamera();

  Future<bool> isLoaded() => _api.isLoaded();
}

/// 百度地图的平台视图. 只支持 Android 和 iOS.
///
/// 视图内的手势全部交给地图, 叠在上面的 Flutter 组件照常接收点击.
class BaiduMapView extends StatefulWidget {
  const new({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.listener,
    required this.onCreated,
  });

  final LatLngMessage initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;

  /// 只在创建时读取一次. 要换回调, 让回调本身读取最新的状态.
  final BaiduMapListener listener;
  final ValueChanged<BaiduMapController> onCreated;

  static const _viewType = 'you.v50to.eat/baidu_map';

  @override
  State<BaiduMapView> createState() => _BaiduMapViewState();
}

class _BaiduMapViewState extends State<BaiduMapView> {
  int? _id;

  static final _gestures = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  Map<String, Object> get _params => {
    'lat': widget.initialCenter.lat,
    'lng': widget.initialCenter.lng,
    'zoom': widget.initialZoom,
    'minZoom': widget.minZoom,
    'maxZoom': widget.maxZoom,
  };

  @override
  void dispose() {
    if (_id case final id?) {
      MapViewFlutterApi.setUp(null, messageChannelSuffix: '$id');
    }
    super.dispose();
  }

  Future<void> _created(int id) async {
    _id = id;
    MapViewFlutterApi.setUp(
      _Events(widget.listener),
      messageChannelSuffix: '$id',
    );
    final controller = BaiduMapController._(id);
    widget.onCreated(controller);
    if (await controller.isLoaded() && mounted) {
      widget.listener.onLoaded?.call();
    }
  }

  @override
  Widget build(BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidView(
      viewType: BaiduMapView._viewType,
      creationParams: _params,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: _gestures,
      onPlatformViewCreated: _created,
    ),
    TargetPlatform.iOS => UiKitView(
      viewType: BaiduMapView._viewType,
      creationParams: _params,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: _gestures,
      onPlatformViewCreated: _created,
    ),
    _ => throw UnsupportedError('百度地图原生桥只支持 Android 和 iOS'),
  };
}

class _Events implements MapViewFlutterApi {
  _Events(this.listener);

  final BaiduMapListener listener;

  @override
  void onLoaded() => listener.onLoaded?.call();

  @override
  void onCameraIdle(CameraMessage camera, bool byGesture) =>
      listener.onCameraIdle?.call(camera, byGesture);

  @override
  void onMarkerTap(String id) => listener.onMarkerTap?.call(id);

  @override
  void onError(int code, String message) =>
      listener.onError?.call(code, message);
}
