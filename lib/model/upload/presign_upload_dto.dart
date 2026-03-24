import 'package:image_picker/image_picker.dart';

class PresignUploadRequest {
  final String fileName;
  final String contentType;
  final int fileSize;
  final String? biz;

  const PresignUploadRequest({
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    this.biz,
  });

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

class PresignBatchUploadRequest {
  final String biz;
  final List<PresignUploadRequest> files;

  const PresignBatchUploadRequest({required this.biz, required this.files});

  Map<String, dynamic> toJson() {
    return {'biz': biz, 'files': files.map((item) => item.toJson()).toList()};
  }
}

class PresignUploadResponse {
  final String putUrl;
  final String key;
  final int expireAt;

  const PresignUploadResponse({
    required this.putUrl,
    required this.key,
    required this.expireAt,
  });

  factory PresignUploadResponse.fromJson(Map<String, dynamic> json) {
    return PresignUploadResponse(
      putUrl: json['putUrl'] as String,
      key: json['key'] as String,
      expireAt: json['expireAt'] as int,
    );
  }
}

class PresignBatchUploadResponse {
  final List<PresignUploadResponse> files;

  const PresignBatchUploadResponse({required this.files});

  factory PresignBatchUploadResponse.fromJson(Map<String, dynamic> json) {
    return PresignBatchUploadResponse(
      files: (json['files'] as List<dynamic>)
          .map((e) => PresignUploadResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
