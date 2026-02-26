import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/error/api_exception.dart';
import 'package:eat_what_app/model/upload/presign_batch_upload_file_dto.dart';
import 'package:eat_what_app/model/upload/presign_batch_upload_req_dto.dart';
import 'package:eat_what_app/model/upload/presign_batch_upload_resp_dto.dart';
import 'package:eat_what_app/model/upload/presign_upload_req_dto.dart';
import 'package:eat_what_app/model/upload/presign_upload_resp_dto.dart';
import 'package:eat_what_app/repository/upload_repository.dart';

class UploadUtil {
  final UploadRepository _uploadRepository;
  final Dio _dio;

  static const Set<String> _allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
  };

  static const Map<String, String> _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
  };

  static const String _errorMessage = '只支持上传图片文件（jpg, jpeg, png, gif, webp, bmp）';

  UploadUtil({
    required UploadRepository uploadRepository,
    Dio? dio,
  })  : _uploadRepository = uploadRepository,
        _dio = dio ?? Dio();

  Future<Result<String>> uploadFile({
    required File file,
    required String fileName,
    String? biz,
  }) async {
    final validation = _validateImageFile(fileName);
    if (validation != null) {
      return Failure(validation);
    }

    final fileInfo = await _getFileInfo(fileName, file);

    final presignReq = PresignUploadReqDto(
      fileName: fileName,
      contentType: fileInfo.contentType,
      fileSize: fileInfo.fileSize,
      biz: biz,
    );

    final presignResult = await _uploadRepository.presign(presignReq);

    return presignResult.when(
      success: (presignResp) async {
        final putResult = await _uploadFileToUrl(
          file: file,
          putUrl: presignResp.putUrl!,
          contentType: fileInfo.contentType,
        );

        return putResult.when(
          success: (_) => Success(presignResp.key!),
          failure: (error) => Failure(error),
        );
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<List<String>>> uploadFiles({
    required List<File> files,
    required List<String> fileNames,
    String? biz,
  }) async {
    if (files.length != fileNames.length) {
      return Failure(
        ParseException(message: '文件列表和文件名列表长度不一致'),
      );
    }

    final validation = _validateImageFiles(fileNames);
    if (validation != null) {
      return Failure(validation);
    }

    final fileInfos = await _buildFileInfos(files, fileNames);

    final presignReq = PresignBatchUploadReqDto(
      biz: biz,
      files: fileInfos,
    );

    final presignResult = await _uploadRepository.presignBatch(presignReq);

    return presignResult.when(
      success: (presignResp) async {
        final uploadResults = await Future.wait(
          List.generate(
            files.length,
            (i) => _uploadFileToUrl(
              file: files[i],
              putUrl: presignResp.files![i].putUrl!,
              contentType: fileInfos[i].contentType,
            ),
          ),
        );

        final keys = <String>[];
        final errors = <String>[];

        for (int i = 0; i < uploadResults.length; i++) {
          uploadResults[i].when(
            success: (_) => keys.add(presignResp.files![i].key!),
            failure: (error) => errors.add(error.message),
          );
        }

        if (errors.isNotEmpty) {
          return Failure(
            ParseException(message: '部分文件上传失败: ${errors.join(", ")}'),
          );
        }

        return Success(keys);
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<void>> _uploadFileToUrl({
    required File file,
    required String putUrl,
    required String contentType,
  }) async {
    try {
      final fileBytes = await file.readAsBytes();

      await _dio.put(
        putUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileBytes.length,
          },
        ),
      );

      return Success(null);
    } on DioException catch (e) {
      return Failure(
        NetworkException(
          message: '文件上传失败: ${e.message ?? "未知错误"}',
          dioExceptionType: e.type,
          originalError: e,
          stackTrace: e.stackTrace,
        ),
      );
    } catch (e, stackTrace) {
      return Failure(
        ParseException(
          message: '文件上传失败: ${e.toString()}',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  ParseException? _validateImageFile(String fileName) {
    final extension = _getFileExtension(fileName);
    if (!_allowedImageExtensions.contains(extension)) {
      return ParseException(message: _errorMessage);
    }
    return null;
  }

  ParseException? _validateImageFiles(List<String> fileNames) {
    for (final fileName in fileNames) {
      final validation = _validateImageFile(fileName);
      if (validation != null) {
        return validation;
      }
    }
    return null;
  }

  Future<({int fileSize, String contentType})> _getFileInfo(
    String fileName,
    File file,
  ) async {
    final fileSize = await file.length();
    final contentType = _getMimeType(fileName);
    return (fileSize: fileSize, contentType: contentType);
  }

  Future<List<PresignBatchUploadFileDto>> _buildFileInfos(
    List<File> files,
    List<String> fileNames,
  ) async {
    final fileInfos = <PresignBatchUploadFileDto>[];

    for (int i = 0; i < files.length; i++) {
      final fileInfo = await _getFileInfo(fileNames[i], files[i]);
      fileInfos.add(
        PresignBatchUploadFileDto(
          fileName: fileNames[i],
          contentType: fileInfo.contentType,
          fileSize: fileInfo.fileSize,
        ),
      );
    }

    return fileInfos;
  }

  String _getFileExtension(String fileName) {
    return fileName.toLowerCase().split('.').last;
  }

  String _getMimeType(String fileName) {
    final extension = _getFileExtension(fileName);
    return _mimeTypes[extension] ?? 'application/octet-stream';
  }
}