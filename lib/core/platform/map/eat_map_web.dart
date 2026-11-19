import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/platform/map/bd09.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/tokens/eat_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

MapEngine createMapEngine(AppConfig config) =>
    _WebMapEngine(config.baiduMapAkWeb);

/// Web 端的百度地图 JS API GL 实现, 仅在首次渲染地图时按需加载脚本.
class _WebMapEngine implements MapEngine {
  _WebMapEngine(this.apiKey);

  final String apiKey;

  @override
  bool get available => apiKey.isNotEmpty;

  @override
  Widget build(EatMap map) => _WebMap(apiKey: apiKey, map: map);

  /// 基于 `LocalSearch` 执行周边检索, 请求入参与响应坐标均在 GCJ-02 与 BD-09 之间自动转换.
  @override
  Future<List<MapPoi>> searchNearby(
    String keyword,
    MapLatLng center, {
    required int radius,
  }) async {
    await _loadScript(apiKey);
    final done = Completer<List<MapPoi>>();
    final bd = Bd09.fromGcj(center);
    final point = _BPoint(bd.lng, bd.lat);
    late final _BLocalSearch search;
    search = _BLocalSearch(
      point,
      _options({
        'pageCapacity': 20.toJS,
        'onSearchComplete': ((_BLocalResult? result) {
          if (done.isCompleted) return;
          final status = search.getStatus();
          // 状态码 0 为成功 (BMAP_STATUS_SUCCESS), 2 为无结果 (BMAP_STATUS_UNKNOWN_LOCATION), 其余状态码均视为超时或检索失败.
          if (status != 0 && status != 2) {
            done.completeError(StateError('百度地点检索失败: $status'));
            return;
          }
          done.complete([
            if (result != null)
              for (var i = 0; i < result.getCurrentNumPois(); i++)
                if (result.getPoi(i) case final poi?
                    when poi.uid.isNotEmpty &&
                        poi.point != null &&
                        _isPlace(poi))
                  MapPoi(
                    uid: poi.uid,
                    name: poi.title,
                    address: poi.address ?? '',
                    point: Bd09.toGcj(
                      MapLatLng(
                        poi.point!.lat.toDouble(),
                        poi.point!.lng.toDouble(),
                      ),
                    ),
                  ),
          ]);
        }).toJS,
      }),
    );
    search.searchNearby(keyword, point, radius);
    return done.future;
  }
}

Future<void>? _script;

/// 调整四角 logo, 版权及比例尺的偏移样式, 使之推入未被浮层遮挡的可见区域, 效果与原生 SDK 设置内边距一致.
///
/// 百度地图要求不得遮挡 logo 与审图号, 而控件默认紧贴容器边缘易被抽屉或左侧面板覆盖,
/// 故通过 [_WebMapState._sync] 动态更新容器的 CSS 变量来避让.
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

/// 按需加载 JS API GL 脚本, 携带 `callback` 参数以在异步加载真正地图库完毕后触发就绪回调.
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

  /// 标记当前相机移动是否由代码触发, 以便在移动结束时区分手势操作与程序控制.
  var _movingByCode = false;

  /// 已应用的内边距中心偏移量, 当内边距变化时仅平移差值, 保持可见区域中心地理坐标不变.
  var _appliedOffset = (dx: 0.0, dy: 0.0);
  EdgeInsets? _appliedInsets;

  final _markers = <String, (_BMarker, MapMarker)>{};
  final _polygons = <_BPolygon>[];
  List<MapPolygon>? _sentPolygons;

  /// 地图刚创建时是默认样式, 即浅色.
  var _sentDark = false;

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
    // 地图初始化时需读取容器实际尺寸, 因此需等待 div 挂载至页面 DOM 树.
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

  /// `moveend` 与 `zoomend` 常连续触发, 通过防抖合并为一次空闲回调.
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
    if (_map.dark != _sentDark) {
      _sentDark = _map.dark;
      unawaited(_applyStyle(bmap, dark: _sentDark));
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

  /// 深色用 `assets/map/dark_style.json`, 浅色传空样式换回默认. 读文件时深浅又变了就不再应用.
  Future<void> _applyStyle(_BMap bmap, {required bool dark}) async {
    final List<Object?> styleJson;
    try {
      styleJson = dark ? await (_darkStyle ??= _loadDarkStyle()) : [];
    } on Object {
      // 读不到样式就留在当前样式, 下次切换再试.
      _darkStyle = null;
      return;
    }
    if (_sentDark != dark || !identical(_bmap, bmap)) return;
    bmap.setMapStyleV2({'styleJson': styleJson}.jsify()! as JSObject);
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(
        color: _map.dark ? EatPalette.mapGroundDark : EatPalette.mapGround,
      ),
      HtmlElementView.fromTagName(tagName: 'div', onElementCreated: _created),
    ],
  );
}

/// 深色底图样式, 和 App 的 `.sty` 出自同一份配置. 见技术架构 14.4.
Future<List<Object?>>? _darkStyle;

Future<List<Object?>> _loadDarkStyle() async =>
    jsonDecode(await rootBundle.loadString('assets/map/dark_style.json'))
        as List<Object?>;

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

/// 构造包含 JS 对象值的配置项 (纯基本类型的配置可直接调用 `jsify`).
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
  external void setMapStyleV2(JSObject style);
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

/// 过滤公交站与地铁站, 仅保留普通 POI (站点类型的 `type` 不等于 `BMAP_POI_TYPE_NORMAL`).
bool _isPlace(_BLocalPoi poi) {
  final type = poi.type;
  final normal = globalContext['BMAP_POI_TYPE_NORMAL'];
  return type == null ||
      normal == null ||
      type == (normal as JSNumber).toDartInt;
}

@JS('BMapGL.LocalSearch')
extension type _BLocalSearch._(JSObject _) implements JSObject {
  external factory _BLocalSearch(_BPoint location, JSObject options);

  external void searchNearby(String keyword, _BPoint center, num radius);
  external int getStatus();
}

extension type _BLocalResult._(JSObject _) implements JSObject {
  external int getCurrentNumPois();
  external _BLocalPoi? getPoi(int index);
}

extension type _BLocalPoi._(JSObject _) implements JSObject {
  external String get title;
  external String get uid;
  external String? get address;
  external _BPoint? get point;
  external int? get type;
}

@JS('BMapGL.Polygon')
extension type _BPolygon._(JSObject _) implements JSObject {
  external factory _BPolygon(JSArray<_BPoint> points, JSObject options);
}
