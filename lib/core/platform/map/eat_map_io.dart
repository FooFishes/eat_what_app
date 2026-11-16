import 'dart:async';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:eat_baidu_map/eat_baidu_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

MapEngine createMapEngine(AppConfig config) =>
    _NativeMapEngine(switch (defaultTargetPlatform) {
      TargetPlatform.android => config.baiduMapAkAndroid,
      TargetPlatform.iOS => config.baiduMapAkIos,
      _ => '',
    });

/// Android 与 iOS 端的百度地图实现, 通过本地插件 `eat_baidu_map` 调用原生 SDK.
class _NativeMapEngine implements MapEngine {
  _NativeMapEngine(this.apiKey);

  final String apiKey;

  @override
  bool get available => apiKey.isNotEmpty;

  @override
  Widget build(EatMap map) => _NativeMap(apiKey: apiKey, map: map);

  @override
  Future<List<MapPoi>> searchNearby(
    String keyword,
    MapLatLng center, {
    required int radius,
  }) async {
    await BaiduMapSdk.initialize(apiKey);
    // 鉴权尚未完成时发起检索会因缺少 token 而直接失败, 因此先等待鉴权结果.
    final (code, message) = await BaiduMapSdk.authResult;
    if (code != 0) throw StateError('百度地图鉴权失败: $code $message');
    final places = await BaiduPlaceSearch.searchNearby(
      keyword,
      _latLng(center),
      radius: radius,
    );
    return [
      for (final p in places)
        MapPoi(
          uid: p.uid,
          name: p.name,
          address: p.address,
          point: MapLatLng(p.location.lat, p.location.lng),
        ),
    ];
  }
}

class _NativeMap extends StatefulWidget {
  const new({required this.apiKey, required this.map});

  final String apiKey;
  final EatMap map;

  @override
  State<_NativeMap> createState() => _NativeMapState();
}

class _NativeMapState extends State<_NativeMap> implements MapHandle {
  late final Future<void> _ready = BaiduMapSdk.initialize(widget.apiKey);
  BaiduMapController? _controller;
  Timer? _timeout;
  var _loaded = false;
  var _failed = false;

  /// 已同步至原生侧的视图状态, 用于与后续 build 的最新属性做增量比对.
  var _sentMarkers = const <MapMarker>[];
  List<MapPolygon>? _sentPolygons;
  EdgeInsets? _sentInsets;

  EatMap get _map => widget.map;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(EatMap.loadTimeout, () {
      if (!_loaded) _fail();
    });
    _ready.then(
      (_) => BaiduMapSdk.authResult.then((result) {
        if (result.$1 != 0) _fail();
      }),
      onError: (Object _) => _fail(),
    );
  }

  @override
  void didUpdateWidget(_NativeMap old) {
    super.didUpdateWidget(old);
    if (old.map.controller != _map.controller && _controller != null) {
      attachMapHandle(old.map.controller, null);
      attachMapHandle(_map.controller, this);
    }
    _sync();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    if (_controller != null) attachMapHandle(_map.controller, null);
    super.dispose();
  }

  void _fail() {
    if (_failed || !mounted) return;
    _failed = true;
    _map.onFailed?.call();
  }

  void _created(BaiduMapController controller) {
    _controller = controller;
    attachMapHandle(_map.controller, this);
    _sync();
  }

  /// 计算当前 build 中内边距, 标记与多边形的增量变化, 并仅同步变更部分至原生侧.
  void _sync() {
    final c = _controller;
    if (c == null) return;
    if (_map.insets != _sentInsets) {
      _sentInsets = _map.insets;
      unawaited(c.setInsets(_insets(_map.insets)));
    }
    final diff = diffMarkers(_sentMarkers, _map.markers);
    _sentMarkers = _map.markers;
    if (diff.upserts.isNotEmpty || diff.removed.isNotEmpty) {
      unawaited(
        c.updateMarkers([
          for (final m in diff.upserts) _marker(m),
        ], diff.removed),
      );
    }
    if (!listEquals(_map.polygons, _sentPolygons)) {
      _sentPolygons = _map.polygons;
      unawaited(c.setPolygons([for (final p in _map.polygons) _polygon(p)]));
    }
  }

  @override
  Future<void> moveTo(
    MapLatLng center, {
    double? zoom,
    bool animated = true,
  }) async =>
      _controller?.moveCamera(_latLng(center), zoom: zoom, animated: animated);

  @override
  Future<void> fit(
    List<MapLatLng> points, {
    required EdgeInsets margin,
    bool animated = true,
  }) async => _controller?.fitPoints(
    [for (final p in points) _latLng(p)],
    margin: _insets(margin),
    animated: animated,
  );

  @override
  Future<MapCamera?> camera() async {
    final camera = await _controller?.getCamera();
    return camera == null ? null : _camera(camera);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done ||
          snapshot.hasError) {
        return const ColoredBox(color: EatPalette.mapGround);
      }
      return BaiduMapView(
        initialCenter: _latLng(_map.initialCenter),
        initialZoom: _map.initialZoom,
        minZoom: _map.minZoom,
        maxZoom: _map.maxZoom,
        onCreated: _created,
        listener: BaiduMapListener(
          onLoaded: () {
            _loaded = true;
            _timeout?.cancel();
          },
          onCameraIdle: (camera, byGesture) =>
              _map.onCameraIdle?.call(_camera(camera), byGesture),
          onMarkerTap: (id) => _map.onMarkerTap?.call(id),
          onError: (_, _) => _fail(),
        ),
      );
    },
  );
}

LatLngMessage _latLng(MapLatLng p) => LatLngMessage(lat: p.lat, lng: p.lng);

MapCamera _camera(CameraMessage c) =>
    MapCamera(center: MapLatLng(c.center.lat, c.center.lng), zoom: c.zoom);

InsetsMessage _insets(EdgeInsets e) =>
    InsetsMessage(left: e.left, top: e.top, right: e.right, bottom: e.bottom);

MarkerMessage _marker(MapMarker m) => MarkerMessage(
  id: m.id,
  position: _latLng(m.point),
  icon: m.image.png,
  iconScale: m.image.scale,
  anchorX: m.image.anchor.dx,
  anchorY: m.image.anchor.dy,
  zIndex: m.zIndex,
);

PolygonMessage _polygon(MapPolygon p) => PolygonMessage(
  id: p.id,
  points: [for (final point in p.points) _latLng(point)],
  fillColor: p.fill.toARGB32(),
  strokeColor: p.stroke.toARGB32(),
  strokeWidth: p.strokeWidth,
  dashed: p.dashed,
);
