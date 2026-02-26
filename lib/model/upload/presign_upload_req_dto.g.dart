// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_upload_req_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresignUploadReqDto _$PresignUploadReqDtoFromJson(Map<String, dynamic> json) =>
    _PresignUploadReqDto(
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      biz: json['biz'] as String?,
    );

Map<String, dynamic> _$PresignUploadReqDtoToJson(
  _PresignUploadReqDto instance,
) => <String, dynamic>{
  'fileName': instance.fileName,
  'contentType': instance.contentType,
  'fileSize': instance.fileSize,
  'biz': instance.biz,
};
