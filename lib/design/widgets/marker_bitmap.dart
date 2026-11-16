import 'dart:ui' as ui;

import 'package:eat/core/platform/map/eat_map.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 将 Flutter 组件离屏渲染为地图标记位图, 使地图引擎绘制的标记与屏幕组件外观一致.
///
/// 组件会在不上屏的渲染树中完成排版与绘制, 再按当前屏幕像素比导出 PNG, 同时原样保留 [context] 中的主题, 字体, 文字方向和 MediaQuery.
/// 组件引用的网络图片需提前写入缓存, 否则导出的位图仅包含占位底色.
abstract final class MarkerBitmap {
  /// 根据排好的尺寸返回坐标锚点位置的回调, 单位为逻辑像素.
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
      // 已缓存的图片在首遍 build 时同步返回并标脏 Image, 因此需要执行第二遍 build.
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
