import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/core/constant/urls.dart';
import 'package:eat_what_app/core/error/api_error_handler.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/upload/presign_upload_dto.dart';

class UploadRepository {
  final RequestClient _api;
  final Dio _dio;

  UploadRepository(this._api)
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  Future<Result<PresignBatchUploadRespDTO>> presignBatchUpload({
    required String biz,
    required List<Map<String, dynamic>> files,
  }) {
    final body = {'biz': biz, 'files': files};
    return _api.post<PresignBatchUploadRespDTO>(
      Urls.uploadPresignBatch,
      data: body,
      fromJson: (json) =>
          PresignBatchUploadRespDTO.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<void>> uploadFileToPresignedUrl({
    required String putUrl,
    required File file,
    required String contentType,
  }) async {
    try {
      final fileBytes = await file.readAsBytes();

      await _dio.put(
        putUrl,
        data: fileBytes,
        options: Options(headers: {'Content-Type': contentType}),
      );

      return Success(null);
    } on DioException catch (error) {
      return Failure(ApiErrorHandler.fromDioException(error));
    } catch (error) {
      return Failure(
        ParseException(message: '上传文件失败: $error', originalError: error),
      );
    }
  }
}
