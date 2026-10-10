import 'package:image_picker/image_picker.dart';

class const PresignUploadRequest({
  required final String fileName,
  required final String contentType,
  required final int fileSize,
  final String? biz,
}) {
  static Future<PresignUploadRequest> fromXFile(
    XFile file, {
    required String contentType,
    String? biz,
  }) async {
    final fileName = file.name;
    return PresignUploadRequest(
      fileName: fileName,
      contentType: contentType,
      fileSize: await file.length(),
      biz: biz,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'contentType': contentType,
      'fileSize': fileSize,
      if (biz != null) 'biz': biz,
    };
  }
}

class const PresignBatchUploadRequest({
  required final String biz,
  required final List<PresignUploadRequest> files,
}) {
  Map<String, dynamic> toJson() {
    return {'biz': biz, 'files': files.map((item) => item.toJson()).toList()};
  }
}

class const PresignUploadResponse({
  required final String putUrl,
  required final String key,
  required final int expireAt,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return PresignUploadResponse(
      putUrl: json['putUrl'] as String,
      key: json['key'] as String,
      expireAt: json['expireAt'] as int,
    );
  }
}

class const PresignBatchUploadResponse({
  required final List<PresignUploadResponse> files,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return PresignBatchUploadResponse(
      files: (json['files'] as List<dynamic>)
          .map((e) => PresignUploadResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
