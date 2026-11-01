import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_picker.g.dart';

/// 选好、压好的一张照片：JPEG 字节和像素尺寸。
class const PickedPhoto({
  required final Uint8List bytes,
  required final int width,
  required final int height,
});

/// 选不出照片的原因。用户取消不算失败，返回空列表。
enum PhotoPickFailure {
  /// 没有相机或相册权限。
  denied,

  /// 解不开（Web 上的 HEIC 这类）。
  unsupported,
}

class const PhotoPickException(final PhotoPickFailure reason)
    implements Exception;

/// 拍照、从相册多选，选到的照片压成长边不超过 2048、质量 85 的 JPEG，去掉 EXIF（技术架构 13.2）。
///
/// 一张一张顺序压缩，避免同时解码多张大图占内存。Web 上是文件选择框，手机浏览器能直接拍。
abstract interface class PhotoPicker {
  /// 从相册选，最多 [limit] 张。
  Future<List<PickedPhoto>> pickFromGallery({required int limit});

  /// 拍一张；取消返回 null。
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
      // 插件把权限被拒报成 PlatformException，码在不同平台不一样（camera_access_denied、
      // photo_access_denied），只按字面判断。
      if ('$e'.contains('denied')) {
        throw const PhotoPickException(PhotoPickFailure.denied);
      }
      rethrow;
    }
  }

  /// 压成长边不超过 [maxSide] 的 JPEG。`flutter_image_compress` 的 `minWidth`、`minHeight` 其实是
  /// 按「短边」缩的上限，要先读出原图尺寸，按长边换算成它要的两个值。
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

  /// 只读文件头里的尺寸，不解码整张图。
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
