// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_batch_upload_resp_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresignBatchUploadRespDto _$PresignBatchUploadRespDtoFromJson(
  Map<String, dynamic> json,
) => _PresignBatchUploadRespDto(
  files: (json['files'] as List<dynamic>?)
      ?.map((e) => PresignUploadRespDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PresignBatchUploadRespDtoToJson(
  _PresignBatchUploadRespDto instance,
) => <String, dynamic>{'files': instance.files};
