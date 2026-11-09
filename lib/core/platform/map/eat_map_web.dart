import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/map/bd09.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

MapEngine createMapEngine(AppConfig config) =>
    _WebMapEngine(config.baiduMapAkWeb);

/// Web 上的百度地图 JS API GL. 第一次显示地图时才加载脚本.
class _WebMapEngine implements MapEngine {
  _WebMapEngine(this.apiKey);

  final String apiKey;

  @override
  bool get available => apiKey.isNotEmpty;

  @override
  Widget build(EatMap map) => _WebMap(apiKey: apiKey, map: map);
}

Future<void>? _script;

/// 把四个角上的 logo, 版权和比例尺推进可见区域, 和 App 上 SDK 设了内边距的效果一样.
///
/// 百度要求不遮挡 logo 和审图号, 而它们默认贴着容器边缘, 会被抽屉或左侧面板盖住.
/// 内边距写成容器上的 CSS 变量, 由 [_WebMapState._sync] 更新.
const _controlsCss = '''
.eat-baidu-map .anchorBL { margin-left: var(--eat-left, 0); margin-bottom: var(--eat-bottom, 0); }
.eat-baidu-map .anchorBR { margin-right: var(--eat-right, 0); margin-bottom: var(--eat-bottom, 0); }
.eat-baidu-map .anchorTL { margin-left: var(--eat-left, 0); margin-top: var(--eat-top, 0); }
.eat-baidu-map .anchorTR { margin-right: var(--eat-right, 0); margin-top: var(--eat-top, 0); }
''';

var _controlsStyled = false;

void _styleControls() {
  if (_controlsStyled) return;
  _controlsStyled = true;
  web.document.head!.append(web.HTMLStyleElement()..textContent = _controlsCss);
}

/// 加载 JS API GL. 带 `callback` 参数时脚本异步插入真正的地图库, 加载完调用回调.
Future<void> _loadScript(String apiKey) => _script ??= () {
  final done = Completer<void>();
  const callback = '__eatBaiduMapReady';
  globalContext[callback] = (() {
    if (!done.isCompleted) done.complete();
  }).toJS;
  final script = web.HTMLScriptElement()
    ..async = true
    ..src =
        'https://api.map.baidu.com/api?type=webgl&v=1.0'
        '&ak=${Uri.encodeQueryComponent(apiKey)}&callback=$callback';
  script.onerror = ((web.Event _) {
    _script = null;
    if (!done.isCompleted) done.completeError(StateError('百度地图脚本加载失败'));
  }).toJS;
  web.document.head!.append(script);
  return done.future;
}();

class _WebMap extends StatefulWidget {
  const new({required this.apiKey, required this.map});

  final String apiKey;
  final EatMap map;

  @override
  State<_WebMap> createState() => _WebMapState();
}

class _WebMapState extends State<_WebMap> implements MapHandle {
  late final Future<void> _ready = _loadScript(widget.apiKey);
  web.HTMLDivElement? _element;
  _BMap? _bmap;
  Timer? _timeout;
  Timer? _idle;
  var _loaded = false;
  var _failed = false;

  /// 正在执行代码发起的移动. 停下时据此区分手势和代码.
  var _movingByCode = false;

  /// 已经按内边距平移过的偏移. 内边距变化时只平移差值, 让可见区域中心的坐标不变.
  var _appliedOffset = (dx: 0.0, dy: 0.0);
  EdgeInsets? _appliedInsets;

  final _markers = <String, (_BMarker, MapMarker)>{};
  final _polygons = <_BPolygon>[];
  List<MapPolygon>? _sentPolygons;

  EatMap get _map => widget.map;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(EatMap.loadTimeout, () {
      if (!_loaded) _fail();
    });
    _ready.catchError((Object _) => _fail());
  }

  @override
  void didUpdateWidget(_WebMap old) {
    super.didUpdateWidget(old);
    if (old.map.controller != _map.controller && _bmap != null) {
      attachMapHandle(old.map.controller, null);
      attachMapHandle(_map.controller, this);
    }
    _sync();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _idle?.cancel();
    if (_bmap != null) attachMapHandle(_map.controller, null);
    _bmap?.destroy();
    super.dispose();
  }

  void _fail() {
    if (_failed || !mounted) return;
    _failed = true;
    _map.onFailed?.call();
  }

  Future<void> _created(Object element) async {
    final div = element as web.HTMLDivElement;
    div
      ..className = 'eat-baidu-map'
      ..style.width = '100%'
      ..style.height = '100%';
    _styleControls();
    _element = div;
    try {
      await _ready;
    } on Object {
      return;
    }
    // 地图在创建时读取容器尺寸, 要等元素挂到页面上.
    while (mounted && !div.isConnected) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (!mounted) return;
    final bmap = _BMap(
      div,
      {
            'minZoom': _map.minZoom,
            'maxZoom': _map.maxZoom,
            'enableRotate': false,
            'enableTilt': false,
            'enableRotateGestures': false,
            'enableTiltGestures': false,
          }.jsify()!
          as JSObject,
    );
    _bmap = bmap;
    bmap
      ..centerAndZoom(_point(_map.initialCenter), _map.initialZoom)
      ..enableScrollWheelZoom(true)
      ..addEventListener(
        'tilesloaded',
        ((JSAny? _) {
          _loaded = true;
          _timeout?.cancel();
        }).toJS,
      )
      ..addEventListener('moveend', ((JSAny? _) => _scheduleIdle()).toJS)
      ..addEventListener('zoomend', ((JSAny? _) => _scheduleIdle()).toJS);
    attachMapHandle(_map.controller, this);
    _sync();
  }

  /// `moveend` 和 `zoomend` 常常连着来, 合成一次.
  void _scheduleIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 60), () async {
      final byGesture = !_movingByCode;
      _movingByCode = false;
      final camera = await this.camera();
      if (camera != null && mounted) _map.onCameraIdle?.call(camera, byGesture);
    });
  }

  void _sync() {
    final bmap = _bmap;
    final element = _element;
    if (bmap == null || element == null) return;
    final insets = _map.insets;
    if (insets != _appliedInsets) {
      _appliedInsets = insets;
      element.style
        ..setProperty('--eat-left', '${insets.left}px')
        ..setProperty('--eat-top', '${insets.top}px')
        ..setProperty('--eat-right', '${insets.right}px')
        ..setProperty('--eat-bottom', '${insets.bottom}px');
      final offset = _offset;
      final dx = offset.dx - _appliedOffset.dx;
      final dy = offset.dy - _appliedOffset.dy;
      _appliedOffset = offset;
      if (dx != 0 || dy != 0) {
        _movingByCode = true;
        bmap.panBy(dx, dy, {'noAnimation': true}.jsify()! as JSObject);
      }
    }
    final diff = diffMarkers([
      for (final (_, m) in _markers.values) m,
    ], _map.markers);
    for (final id in diff.removed) {
      if (_markers.remove(id) case (final marker, _)) {
        bmap.removeOverlay(marker);
      }
    }
    for (final m in diff.upserts) {
      final icon = _icon(m.image);
      if (_markers[m.id] case (final marker, _)) {
        marker
          ..setPosition(_point(m.point))
          ..setIcon(icon)
          ..setZIndex(m.zIndex);
        _markers[m.id] = (marker, m);
        continue;
      }
      final marker = _BMarker(_point(m.point), _options({'icon': icon}))
        ..setZIndex(m.zIndex);
      final id = m.id;
      marker.addEventListener(
        'click',
        ((JSAny? _) => _map.onMarkerTap?.call(id)).toJS,
      );
      bmap.addOverlay(marker);
      _markers[id] = (marker, m);
    }
    if (!listEquals(_map.polygons, _sentPolygons)) {
      _sentPolygons = _map.polygons;
      for (final p in _polygons) {
        bmap.removeOverlay(p);
      }
      _polygons.clear();
      for (final p in _map.polygons) {
        if (p.points.length < 3) continue;
        final polygon = _BPolygon(
          [for (final point in p.points) _point(point)].toJS,
          {
                'strokeColor': _hex(p.stroke),
                'strokeOpacity': p.stroke.a,
                'strokeWeight': p.strokeWidth,
                'strokeStyle': p.dashed ? 'dashed' : 'solid',
                'fillColor': _hex(p.fill),
                'fillOpacity': p.fill.a,
              }.jsify()!
              as JSObject,
        );
        bmap.addOverlay(polygon);
        _polygons.add(polygon);
      }
    }
  }

  /// 可见区域中心相对容器中心的偏移.
  ({double dx, double dy}) get _offset {
    final i = _map.insets;
    return (dx: (i.left - i.right) / 2, dy: (i.top - i.bottom) / 2);
  }

  @override
  Future<void> moveTo(
    MapLatLng center, {
    double? zoom,
    bool animated = true,
  }) async {
    final bmap = _bmap;
    if (bmap == null) return;
    _movingByCode = true;
    final (:dx, :dy) = _offset;
    if (zoom != null && zoom != bmap.getZoom().toDouble()) {
      bmap
        ..centerAndZoom(_point(center), zoom)
        ..panBy(dx, dy, {'noAnimation': true}.jsify()! as JSObject);
      return;
    }
    final pixel = bmap.pointToPixel(_point(center));
    final target = bmap.pixelToPoint(_BPixel(pixel.x - dx, pixel.y - dy));
    if (animated) {
      bmap.panTo(target);
    } else {
      bmap.setCenter(target);
    }
  }

  @override
  Future<void> fit(
    List<MapLatLng> points, {
    required EdgeInsets margin,
    bool animated = true,
  }) async {
    final bmap = _bmap;
    if (bmap == null || points.isEmpty) return;
    _movingByCode = true;
    final i = _map.insets + margin;
    bmap.setViewport(
      [for (final p in points) _point(p)].toJS,
      {
            'margins': [i.top, i.right, i.bottom, i.left],
            'enableAnimation': animated,
          }.jsify()!
          as JSObject,
    );
  }

  @override
  Future<MapCamera?> camera() async {
    final bmap = _bmap;
    final element = _element;
    if (bmap == null || element == null) return null;
    final (:dx, :dy) = _offset;
    final center = bmap.pixelToPoint(
      _BPixel(element.clientWidth / 2 + dx, element.clientHeight / 2 + dy),
    );
    return MapCamera(
      center: Bd09.toGcj(
        MapLatLng(center.lat.toDouble(), center.lng.toDouble()),
      ),
      zoom: bmap.getZoom().toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: EatPalette.mapGround),
      HtmlElementView.fromTagName(tagName: 'div', onElementCreated: _created),
    ],
  );
}

_BPoint _point(MapLatLng gcj) {
  final bd = Bd09.fromGcj(gcj);
  return _BPoint(bd.lng, bd.lat);
}

_BIcon _icon(MarkerImage image) {
  final w = image.size.width;
  final h = image.size.height;
  return _BIcon(
    'data:image/png;base64,${base64Encode(image.png)}',
    _BSize(w, h),
    _options({
      'anchor': _BSize(w * image.anchor.dx, h * image.anchor.dy),
      'imageSize': _BSize(w, h),
    }),
  );
}

/// 值里有 JS 对象的选项. 只有基本类型的选项直接用 `jsify`.
JSObject _options(Map<String, JSAny?> values) {
  final options = JSObject();
  values.forEach((key, value) => options[key] = value);
  return options;
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

@JS('BMapGL.Map')
extension type _BMap._(JSObject _) implements JSObject {
  external factory _BMap(web.HTMLElement container, JSObject options);

  external void centerAndZoom(_BPoint center, num zoom);
  external void setCenter(_BPoint center);
  external void panTo(_BPoint center);
  external void panBy(num x, num y, JSObject options);
  external num getZoom();
  external void enableScrollWheelZoom(bool enable);
  external void setViewport(JSArray<_BPoint> points, JSObject options);
  external _BPixel pointToPixel(_BPoint point);
  external _BPoint pixelToPoint(_BPixel pixel);
  external void addOverlay(JSObject overlay);
  external void removeOverlay(JSObject overlay);
  external void addEventListener(String type, JSFunction handler);
  external void destroy();
}

@JS('BMapGL.Point')
extension type _BPoint._(JSObject _) implements JSObject {
  external factory _BPoint(num lng, num lat);

  external num get lng;
  external num get lat;
}

@JS('BMapGL.Pixel')
extension type _BPixel._(JSObject _) implements JSObject {
  external factory _BPixel(num x, num y);

  external num get x;
  external num get y;
}

@JS('BMapGL.Size')
extension type _BSize._(JSObject _) implements JSObject {
  external factory _BSize(num width, num height);
}

@JS('BMapGL.Icon')
extension type _BIcon._(JSObject _) implements JSObject {
  external factory _BIcon(String url, _BSize size, JSObject options);
}

@JS('BMapGL.Marker')
extension type _BMarker._(JSObject _) implements JSObject {
  external factory _BMarker(_BPoint point, JSObject options);

  external void setPosition(_BPoint point);
  external void setIcon(_BIcon icon);
  external void setZIndex(num zIndex);
  external void addEventListener(String type, JSFunction handler);
}

@JS('BMapGL.Polygon')
extension type _BPolygon._(JSObject _) implements JSObject {
  external factory _BPolygon(JSArray<_BPoint> points, JSObject options);
}
