import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/icons/eat_icons.dart';
import 'package:eat/design/tokens/eat_dimensions.dart';
import 'package:eat/design/widgets/eat_button.dart';
import 'package:eat/design/widgets/eat_panel.dart';
import 'package:eat/design/widgets/eat_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Source { camera, gallery }

/// 弹出拍照或相册来源面板并选取最多 [limit] 张压缩后的照片.
///
/// 用户取消或发生异常时返回空列表, 并在异常时弹出轻提示.
Future<List<PickedPhoto>> pickPhotos(
  BuildContext context,
  WidgetRef ref, {
  required int limit,
  String title = '加照片',
}) async {
  final source = await showPanel<_Source>(
    context,
    builder: (panel) => EatPanel(
      title: title,
      subtitle: '请上传这道菜的实拍，不要用网图或菜单截图',
      actions: Row(
        spacing: EatSpace.s10,
        children: [
          Expanded(
            child: EatButton.mist(
              '从相册选',
              icon: EatIcons.image,
              onPressed: () => Navigator.of(panel).pop(_Source.gallery),
            ),
          ),
          Expanded(
            child: EatButton.solid(
              '拍一张',
              icon: EatIcons.camera,
              onPressed: () => Navigator.of(panel).pop(_Source.camera),
            ),
          ),
        ],
      ),
    ),
  );
  if (source == null) return const [];
  final picker = ref.read(photoPickerProvider);
  try {
    return switch (source) {
      _Source.camera => [?await picker.takePhoto()],
      _Source.gallery => await picker.pickFromGallery(limit: limit),
    };
  } on PhotoPickException catch (e) {
    if (context.mounted) {
      showToast(context, switch (e.reason) {
        PhotoPickFailure.denied => '请在系统设置中允许访问相机和相册',
        PhotoPickFailure.unsupported => '不支持该照片格式，请更换',
      });
    }
  } on Object {
    if (context.mounted) showToast(context, '照片读取失败，请重试');
  }
  return const [];
}
