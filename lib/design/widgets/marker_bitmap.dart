import 'dart:ui' as ui;

import 'package:eat/core/platform/map/eat_map.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 把组件画成地图标记的位图, 让引擎画的标记和屏幕上的组件长得一样.
///
/// 组件在一棵不上屏的渲染树里排版, 绘制, 再按屏幕的像素比导出 PNG.
/// [context] 里的主题, 字体, 文字方向和 MediaQuery 原样带进去.
/// 组件里的网络图片要先放进缓存, 否则画出来的是占位底色.
abstract final class MarkerBitmap {
  /// [anchor] 根据排好的尺寸给出对准坐标的那一点, 单位为逻辑像素.
  static Future<MarkerImage> render(
    BuildContext context,
    Widget child, {
    required Offset Function(Size size) anchor,
    Size maxSize = const Size(240, 240),
  }) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final wrapped = MediaQuery(
      data: MediaQuery.of(context),
      child: Directionality(
        textDirection: Directionality.of(context),
        child: InheritedTheme.captureAll(context, child),
      ),
    );
    final boundary = RenderRepaintBoundary();
    final view = RenderView(
      view: View.of(context),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.loose(maxSize),
        devicePixelRatio: ratio,
      ),
      child: RenderPositionedBox(alignment: Alignment.topLeft, child: boundary),
    );
    final pipeline = PipelineOwner()..rootNode = view;
    view.prepareInitialFrame();
    final focus = FocusManager();
    final build = BuildOwner(focusManager: focus);
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: wrapped,
    ).attachToRenderTree(build);
    try {
      // 缓存里的图片在第一遍 build 时同步到达, 会把 Image 标脏, 所以再 build 一遍.
      build
        ..buildScope(root)
        ..buildScope(root)
        ..finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      final size = boundary.size;
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final point = anchor(size);
      return MarkerImage(
        png: data!.buffer.asUint8List(),
        scale: ratio,
        size: size,
        anchor: Offset(point.dx / size.width, point.dy / size.height),
      );
    } finally {
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
          .attachToRenderTree(build, root);
      build.finalizeTree();
      pipeline
        ..rootNode = null
        ..dispose();
      focus.dispose();
    }
  }
}
