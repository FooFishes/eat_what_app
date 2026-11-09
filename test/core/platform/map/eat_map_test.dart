import 'dart:typed_data';

import 'package:eat/core/platform/map/bd09.dart';
import 'package:eat/core/platform/map/eat_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diffMarkers', () {
    final a = _image();
    final b = _image();
    MapMarker m(
      String id, {
      double lat = 36.66,
      MarkerImage? image,
      int z = 0,
    }) => MapMarker(
      id: id,
      point: MapLatLng(lat, 117.13),
      image: image ?? a,
      zIndex: z,
    );

    test('没变的不发，新增的发，消失的删', () {
      final diff = diffMarkers([m('1'), m('2')], [m('1'), m('3')]);

      expect(diff.upserts.map((m) => m.id), ['3']);
      expect(diff.removed, ['2']);
    });

    test('位置、图片或层级变了都要重发', () {
      final diff = diffMarkers(
        [m('1'), m('2'), m('3')],
        [m('1', lat: 36.67), m('2', image: b), m('3', z: 3)],
      );

      expect(diff.upserts.map((m) => m.id), ['1', '2', '3']);
      expect(diff.removed, isEmpty);
    });

    test('图片只看是不是同一个实例', () {
      final copy = MarkerImage(
        png: a.png,
        scale: a.scale,
        size: a.size,
        anchor: a.anchor,
      );

      expect(
        diffMarkers([m('1')], [m('1', image: copy)]).upserts,
        hasLength(1),
      );
    });
  });

  group('Bd09', () {
    // 常被引用的天安门示例: BD-09 (39.915, 116.404) 对应 GCJ-02 (39.90865, 116.39762).
    const gcj = MapLatLng(39.90865, 116.39762);
    const bd = MapLatLng(39.915, 116.404);

    test('GCJ-02 转 BD-09', () {
      final p = Bd09.fromGcj(gcj);
      expect(p.lat, closeTo(bd.lat, 1e-5));
      expect(p.lng, closeTo(bd.lng, 1e-5));
    });

    test('转过去再转回来误差在 1 米以内', () {
      final back = Bd09.toGcj(Bd09.fromGcj(gcj));
      expect(back.lat, closeTo(gcj.lat, 1e-5));
      expect(back.lng, closeTo(gcj.lng, 1e-5));
    });
  });

  test('多边形按值比较, 页面每次 build 新建的同一个范围不会重发', () {
    MapPolygon p() => const MapPolygon(
      id: 'hub-1',
      points: [MapLatLng(1, 2), MapLatLng(3, 4), MapLatLng(5, 6)],
      fill: Color(0x3DF5B800),
      stroke: Color(0xFF231C18),
      dashed: true,
    );

    expect(p(), p());
    expect(p().hashCode, p().hashCode);
  });
}

MarkerImage _image() => MarkerImage(
  png: Uint8List(0),
  scale: 2,
  size: const Size(40, 40),
  anchor: const Offset(0.5, 0.5),
);
