import 'dart:convert';
import 'dart:typed_data';

import 'package:eat_what_app/app/shell/widgets/custom_bottom_navigation_bar.dart';
import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/core/theme/app_theme.dart';
import 'package:eat_what_app/features/upload/presentation/widgets/editable_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// 保留预览器提供的 MediaQuery，使尺寸和字体缩放配置生效。
Widget componentPreviewWrapper(Widget child) => Directionality(
  textDirection: .ltr,
  child: Theme(
    data: AppTheme.light,
    child: Material(color: AppColors.background, child: child),
  ),
);

@Preview(
  group: '底部导航',
  name: '常规宽度',
  size: Size(390, 130),
  wrapper: componentPreviewWrapper,
)
@Preview(
  group: '底部导航',
  name: '窄屏',
  size: Size(320, 130),
  wrapper: componentPreviewWrapper,
)
@Preview(
  group: '底部导航',
  name: '宽屏',
  size: Size(600, 130),
  wrapper: componentPreviewWrapper,
)
Widget bottomNavigationPreview() => const _BottomNavigationDemo();

@Preview(
  group: '底部导航',
  name: '较大字体',
  size: Size(390, 150),
  textScaleFactor: 1.5,
  wrapper: componentPreviewWrapper,
)
Widget largeTextBottomNavigationPreview() =>
    const _BottomNavigationDemo(height: 120);

@Preview(
  group: '图片网格',
  name: '空白',
  size: Size(390, 380),
  wrapper: componentPreviewWrapper,
)
Widget emptyImageGridPreview() => const _ImageGridDemo(initialCount: 0);

@Preview(
  group: '图片网格',
  name: '部分图片',
  size: Size(390, 380),
  wrapper: componentPreviewWrapper,
)
@Preview(
  group: '图片网格',
  name: '窄屏较大字体',
  size: Size(320, 380),
  textScaleFactor: 1.5,
  wrapper: componentPreviewWrapper,
)
Widget partialImageGridPreview() => const _ImageGridDemo(initialCount: 2);

@Preview(
  group: '图片网格',
  name: '满九张',
  size: Size(390, 380),
  wrapper: componentPreviewWrapper,
)
Widget fullImageGridPreview() => const _ImageGridDemo(initialCount: 9);

class _BottomNavigationDemo extends StatefulWidget {
  const new({this.height = 100});

  final double height;

  @override
  State<_BottomNavigationDemo> createState() => _BottomNavigationDemoState();
}

class _BottomNavigationDemoState extends State<_BottomNavigationDemo> {
  int _currentIndex = 0;

  static const _tabs = [
    (label: '首页', icon: Icons.home_outlined),
    (label: '地图', icon: Icons.map_outlined),
    (label: '上传', icon: Icons.add_photo_alternate_outlined),
    (label: '餐厅', icon: Icons.restaurant_outlined),
    (label: '我的', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) => Align(
    alignment: .bottomCenter,
    child: CustomBottomNavigationBar(
      currentIndex: _currentIndex,
      height: widget.height,
      items: List.generate(_tabs.length, (index) {
        final tab = _tabs[index];
        final selected = index == _currentIndex;
        return GestureDetector(
          behavior: .opaque,
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisSize: .min,
            children: [
              SizedBox(
                height: 65,
                width: 65,
                child: Icon(
                  tab.icon,
                  size: 32,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}

class _ImageGridDemo extends StatefulWidget {
  const new({required this.initialCount});

  final int initialCount;

  @override
  State<_ImageGridDemo> createState() => _ImageGridDemoState();
}

class _ImageGridDemoState extends State<_ImageGridDemo> {
  // 内嵌本地 PNG，预览时不会触发相册权限或下载图片。
  static final _sampleImage = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAALklEQVR4nO3OIQEAAAgDsOckLNVODMzE/NKdfoqAgICAgICAgICAgICAgMB34AAtVFi1GyiM1AAAAABJRU5ErkJggg==',
  );
  late final List<Uint8List> _images = List.generate(
    widget.initialCount,
    (_) => _sampleImage,
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const .all(16),
    child: EditableImageGrid(
      images: _images,
      onAdd: () {
        if (_images.length < 9) {
          setState(() => _images.add(_sampleImage));
        }
      },
      onRemove: (index) => setState(() => _images.removeAt(index)),
    ),
  );
}
