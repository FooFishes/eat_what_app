import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/api_parser.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/upload/presign_upload_dto.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadRepository {
  static const String _foodsBiz = 'foods';

  final RequestClient _api;
  final RequestClient _rawApi;

  const ImageUploadRepository({
    required RequestClient api,
    required RequestClient rawApi,
  }) : _api = api,
       _rawApi = rawApi;

  Future<List<String>> uploadImages({required List<XFile> images}) async {
    if (images.isEmpty) {
      return const [];
    }

    final request = PresignBatchUploadRequest(
      biz: _foodsBiz,
      files: await Future.wait(
        images.map(
          (image) => PresignUploadRequest.fromXFile(
            image,
            contentType: _resolveMimeType(image.name),
          ),
        ),
      ),
    );

    final presign = await _api.post<PresignBatchUploadResponse>(
      Urls.uploadPresignBatch,
      data: request.toJson(),
      parser: (data) =>
          ApiParser.parseObject(data, PresignBatchUploadResponse.fromJson),
    );

    if (presign == null) {
      throw const ParseException(message: '图片上传预签名为空');
    }
    if (presign.files.length != images.length) {
      throw const ParseException(message: '预签名返回数量与图片数量不一致');
    }

    final uploadedKeys = <String>[];
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final target = presign.files[index];

      await _rawApi.putRaw(
        target.putUrl,
        data: await image.readAsBytes(),
        options: Options(
          headers: {'Content-Type': _resolveMimeType(image.name)},
        ),
      );

      uploadedKeys.add(target.key);
    }

    return uploadedKeys;
  }

  String _resolveMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }
}
