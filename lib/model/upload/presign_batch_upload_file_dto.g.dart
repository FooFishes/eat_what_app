// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_batch_upload_file_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresignBatchUploadFileDto _$PresignBatchUploadFileDtoFromJson(
  Map<String, dynamic> json,
) => _PresignBatchUploadFileDto(
  fileName: json['fileName'] as String,
  contentType: json['contentType'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
);

Map<String, dynamic> _$PresignBatchUploadFileDtoToJson(
  _PresignBatchUploadFileDto instance,
) => <String, dynamic>{
  'fileName': instance.fileName,
  'contentType': instance.contentType,
  'fileSize': instance.fileSize,
};
