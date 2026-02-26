// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_batch_upload_req_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresignBatchUploadReqDto _$PresignBatchUploadReqDtoFromJson(
  Map<String, dynamic> json,
) => _PresignBatchUploadReqDto(
  biz: json['biz'] as String?,
  files: (json['files'] as List<dynamic>)
      .map((e) => PresignBatchUploadFileDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PresignBatchUploadReqDtoToJson(
  _PresignBatchUploadReqDto instance,
) => <String, dynamic>{'biz': instance.biz, 'files': instance.files};
