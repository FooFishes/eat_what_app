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

/// 无法获取照片的失败原因 (用户主动取消不视为失败, 而是返回空列表或 null).
enum PhotoPickFailure {
  /// 缺少相机或相册访问权限.
  denied,

  /// 图片格式无法解码, 例如 Web 端传入 HEIC 格式.
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

  /// 把 [photo] 中的圆形取景裁成边长 [size] 的正方形 JPEG, 用于头像.
  ///
  /// [centerX], [centerY] 是圆心按照片宽高归一化的位置, [diameter] 是直径占照片短边的比例.
  Future<Uint8List> cropSquare(
    PickedPhoto photo, {
    required double centerX,
    required double centerY,
    required double diameter,
    int size = 512,
  });
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

  @override
  Future<Uint8List> cropSquare(
    PickedPhoto photo, {
    required double centerX,
    required double centerY,
    required double diameter,
    int size = 512,
  }) async {
    final codec = await ui.instantiateImageCodec(photo.bytes);
    final image = (await codec.getNextFrame()).image;
    final side = math.min(image.width, image.height) * diameter;
    final source = ui.Rect.fromCenter(
      center: ui.Offset(centerX * image.width, centerY * image.height),
      width: side,
      height: side,
    );
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      source,
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final cropped = await recorder.endRecording().toImage(size, size);
    final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();
    codec.dispose();
    if (png == null) {
      throw const PhotoPickException(PhotoPickFailure.unsupported);
    }
    return FlutterImageCompress.compressWithList(
      png.buffer.asUint8List(),
      minWidth: size,
      minHeight: size,
      quality: quality,
    );
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

  /// 仅从文件头解析图片宽高, 避免解码整张图片.
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
