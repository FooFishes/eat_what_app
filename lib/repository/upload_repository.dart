import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/api_parser.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/activity/create_activity_food_request.dart';
import 'package:eat_what_app/model/location/city_response.dart';
import 'package:eat_what_app/model/location/province_response.dart';
import 'package:eat_what_app/model/upload/presign_upload_dto.dart';

class UploadRepository {
  final RequestClient _api;
  final RequestClient _rawApi;

  UploadRepository({required RequestClient api, required RequestClient rawApi})
    : _api = api,
      _rawApi = rawApi;

  Future<List<ProvinceResponse>> getProvinces() async {
    final result = await _api.get<List<ProvinceResponse>>(
      Urls.provinces,
      parser: (data) => ApiParser.parseList(data, ProvinceResponse.fromJson),
    );
    if (result == null) throw ParseException(message: "省份列表为空");
    return result;
  }

  Future<List<CityResponse>> getCities(int provinceId) async {
    final result = await _api.get<List<CityResponse>>(
      Urls.cities(provinceId),
      parser: (data) => ApiParser.parseList(data, CityResponse.fromJson),
    );
    if (result == null) throw ParseException(message: "城市列表为空");
    return result;
  }

  Future<void> publishActivityFood({
    required String foodName,
    required String? description,
    required int provinceId,
    required int cityId,
    required List<XFile> images,
  }) async {
    final presign = await _presignBatchUpload(images);

    if (presign.files.length != images.length) {
      throw ParseException(message: '预签名返回数量与上传数量不一致');
    }

    final uploadedKeys = <String>[];
    for (int index = 0; index < images.length; index++) {
      final image = images[index];
      final target = presign.files[index];
      final fileName = image.name;

      await _uploadFileToPresignUrl(
        putUrl: target.putUrl,
        fileBytes: await image.readAsBytes(),
        mimeType: _resolveMimeType(fileName),
      );

      uploadedKeys.add(target.key);
    }

    final String? content;
    if (description == null || description.trim().isEmpty) {
      content = null;
    } else {
      content = description.trim();
    }

    await _createActivityFood(
      CreateActivityFoodRequest(
        foodName: foodName.trim(),
        description: content,
        provinceId: provinceId,
        cityId: cityId,
        pictureUrl: uploadedKeys,
      ),
    );
  }

  Future<PresignBatchUploadResponse> _presignBatchUpload(
    List<XFile> images,
  ) async {
    final files = <PresignUploadRequest>[];
    for (final image in images) {
      final fileName = image.name;
      files.add(
        await PresignUploadRequest.fromXFile(
          image,
          contentType: _resolveMimeType(fileName),
        ),
      );
    }
    final request = PresignBatchUploadRequest(biz: 'activity', files: files);
    final result = await _api.post<PresignBatchUploadResponse>(
      Urls.uploadPresignBatch,
      data: request.toJson(),
      parser: (data) =>
          ApiParser.parseObject(data, PresignBatchUploadResponse.fromJson),
    );
    if (result == null) throw ParseException(message: '预签名上传响应为空');
    return result;
  }

  Future<void> _uploadFileToPresignUrl({
    required String putUrl,
    required List<int> fileBytes,
    required String mimeType,
  }) async {
    await _rawApi.putRaw(
      putUrl,
      data: fileBytes,
      options: Options(headers: {'Content-Type': mimeType}),
    );
  }

  Future<void> _createActivityFood(CreateActivityFoodRequest request) async {
    await _api.postVoid(Urls.activityFoods, data: request.toJson());
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
