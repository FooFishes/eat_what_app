import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_picker.g.dart';

/// 选取并压缩后的照片: JPEG 字节和像素尺寸.
class const PickedPhoto({
  required final Uint8List bytes,
  required final int width,
  required final int height,
});

/// 无法取得照片的原因. 用户取消不算失败, 返回空列表.
enum PhotoPickFailure {
  /// 没有相机或相册权限.
  denied,

  /// 无法解码, 例如 Web 上的 HEIC.
  unsupported,
}

class const PhotoPickException(final PhotoPickFailure reason)
    implements Exception;

/// 拍照或从相册多选. 照片压缩为 JPEG 并去除 EXIF, 长边不超过 [PlatformPhotoPicker.maxSide].
///
/// 逐张顺序压缩, 避免同时解码多张大图导致内存占用过高.
/// Web 上为文件选择框, 手机浏览器可直接调用相机.
abstract interface class PhotoPicker {
  /// 从相册选取, 最多 [limit] 张.
  Future<List<PickedPhoto>> pickFromGallery({required int limit});

  /// 拍摄一张照片. 用户取消时返回 null.
  Future<PickedPhoto?> takePhoto();
}

class PlatformPhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  static const maxSide = 2048;
  static const quality = 85;

  @override
  Future<List<PickedPhoto>> pickFromGallery({required int limit}) async {
    final files = await _guard(
      () => limit == 1
          ? _picker.pickImage(source: ImageSource.gallery).then((f) => [?f])
          : _picker.pickMultiImage(limit: limit),
    );
    final photos = <PickedPhoto>[];
    for (final file in files.take(limit)) {
      photos.add(await compress(await file.readAsBytes()));
    }
    return photos;
  }

  @override
  Future<PickedPhoto?> takePhoto() async {
    final file = await _guard(
      () => _picker.pickImage(source: ImageSource.camera),
    );
    return file == null ? null : compress(await file.readAsBytes());
  }

  static Future<T> _guard<T>(Future<T> Function() pick) async {
    try {
      return await pick();
    } on Object catch (e) {
      // 插件把权限被拒报告为 PlatformException, 错误码因平台而异
      // (camera_access_denied, photo_access_denied), 因此按异常文本匹配.
      if ('$e'.contains('denied')) {
        throw const PhotoPickException(PhotoPickFailure.denied);
      }
      rethrow;
    }
  }

  /// 压缩为长边不超过 [maxSide] 的 JPEG.
  ///
  /// `flutter_image_compress` 的 `minWidth` 和 `minHeight` 实际按短边限制缩放.
  /// 因此先读取原图尺寸, 再按长边换算出这两个参数.
  static Future<PickedPhoto> compress(Uint8List bytes) async {
    final (width, height) = await _size(bytes);
    final scale = math.max(width, height) / maxSide;
    final out = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: scale > 1 ? (width / scale).round() : width,
      minHeight: scale > 1 ? (height / scale).round() : height,
      quality: quality,
    );
    final (outWidth, outHeight) = await _size(out);
    return PickedPhoto(bytes: out, width: outWidth, height: outHeight);
  }

  /// 只读取文件头中的尺寸, 不解码整张图片.
  static Future<(int, int)> _size(Uint8List bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } on Object {
      throw const PhotoPickException(PhotoPickFailure.unsupported);
    }
  }
}

@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) => PlatformPhotoPicker();
