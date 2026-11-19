import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_icon_button.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show InteractiveViewer, MaterialPageRoute;

/// 表示大图浏览器中的单张照片, [credit] 为拍摄者昵称 (未知时为 null).
class const ViewerPhoto({required final String url, final String? credit});

/// 全屏大图浏览页面, 支持左右翻页, 双指缩放以及显示每张照片的拍摄者.
///
/// 页面依赖内存中的图片地址列表且刷新后无法恢复, 因此不注册路由路径.
class PhotoViewer extends StatefulWidget {
  const new({super.key, required this.photos, this.initialIndex = 0});

  final List<ViewerPhoto> photos;
  final int initialIndex;

  static Route<void> route({
    required List<ViewerPhoto> photos,
    int initialIndex = 0,
  }) => MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => PhotoViewer(photos: photos, initialIndex: initialIndex),
  );

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late var _index = widget.initialIndex;
  late final _pages = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eat = context.eat;
    final safe = MediaQuery.viewPaddingOf(context);
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width;
    final credit = widget.photos[_index].credit;
    return ColoredBox(
      color: eat.colors.shade,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image(
                  image: networkImage(widget.photos[i].url, width: width)!,
                  fit: BoxFit.contain,
                  semanticLabel: '第 ${i + 1} 张照片',
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned(
            top: safe.top + 4,
            left: 8,
            child: EatIconButton(
              EatIcons.close,
              label: '关闭',
              color: eat.colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: EatSpace.s20,
            right: EatSpace.s20,
            bottom: safe.bottom + EatSpace.s24,
            child: Text(
              [
                '${_index + 1} / ${widget.photos.length}',
                if (credit != null) '$credit 拍的',
              ].join('  '),
              style: eat.text.meta.copyWith(color: eat.colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
