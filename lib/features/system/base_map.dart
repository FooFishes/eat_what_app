/// 附近页和新建店共用的地图部分: 坐标类型的互转, 店铺标记的位图.
library;

import 'dart:async';

import 'package:eat/core/platform/map/eat_map.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:eat/design/widgets/map_pin.dart';
import 'package:eat/design/widgets/marker_bitmap.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:flutter/widgets.dart';

MapLatLng mapPoint(GcjPoint point) => MapLatLng(point.lat, point.lng);

GcjPoint gcjOf(MapLatLng point) => GcjPoint(point.lat, point.lng);

/// 店铺标记和我的位置画成的位图. 第一次用到时在后台画, 画好后调用 [onChanged] 让页面重建.
///
/// 封面图还没下载好时, 先给不带封面的版本, 图到了再换.
class PinImages {
  PinImages(this.onChanged);

  final VoidCallback onChanged;
  final _images = <_PinKey, MarkerImage>{};
  final _drawing = <_PinKey>{};
  var _disposed = false;

  /// 标记四周给阴影留的空白, 和 `shadow-pin` 的偏移, 模糊半径对应.
  static const _shadow = EdgeInsets.fromLTRB(10, 6, 10, 14);

  /// [ring] 是选中时外圈的颜色. 没画好时返回 null.
  MarkerImage? shop(
    BuildContext context, {
    required String name,
    required String? cover,
    required bool selected,
    required Color ring,
  }) {
    final key = _PinKey(selected ? name : '', cover, selected, ring);
    if (_images[key] case final image?) return image;
    _draw(context, key);
    if (cover == null) return null;
    final bare = _PinKey(key.name, null, selected, ring);
    _draw(context, bare);
    return _images[bare];
  }

  MarkerImage? me(BuildContext context) {
    const key = _PinKey('', null, false, Color(0x00000000), me: true);
    if (_images[key] case final image?) return image;
    _draw(context, key);
    return null;
  }

  void dispose() => _disposed = true;

  void _draw(BuildContext context, _PinKey key) {
    if (!_drawing.add(key)) return;
    scheduleMicrotask(() async {
      if (!context.mounted || _disposed) return;
      final image = key.me ? null : networkImage(key.cover, width: 64);
      if (image != null) {
        await precacheImage(image, context, onError: (_, _) {});
        if (!context.mounted || _disposed) return;
      }
      final outer = key.selected ? 72.0 : 44.0;
      final bitmap = await MarkerBitmap.render(
        context,
        Padding(
          padding: _shadow,
          child: key.me
              ? const MyLocationDot()
              : MapPin(
                  name: key.name,
                  image: image,
                  selected: key.selected,
                  ring: key.ring,
                  onTap: () {},
                ),
        ),
        anchor: (size) => Offset(
          size.width / 2,
          _shadow.top + (key.me ? MyLocationDot.size : outer) / 2,
        ),
      );
      if (_disposed) return;
      _images[key] = bitmap;
      onChanged();
    });
  }
}

class const _PinKey(
  final String name,
  final String? cover,
  final bool selected,
  final Color ring, {
  final bool me = false,
}) {
  @override
  bool operator ==(Object other) =>
      other is _PinKey &&
      other.name == name &&
      other.cover == cover &&
      other.selected == selected &&
      other.ring == ring &&
      other.me == me;

  @override
  int get hashCode => Object.hash(name, cover, selected, ring, me);
}
