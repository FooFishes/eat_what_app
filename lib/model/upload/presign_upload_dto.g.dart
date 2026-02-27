// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_upload_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresignUploadRespDTO _$PresignUploadRespDTOFromJson(
  Map<String, dynamic> json,
) => _PresignUploadRespDTO(
  putUrl: json['putUrl'] as String,
  key: json['key'] as String,
  expireAt: (json['expireAt'] as num).toInt(),
);

Map<String, dynamic> _$PresignUploadRespDTOToJson(
  _PresignUploadRespDTO instance,
) => <String, dynamic>{
  'putUrl': instance.putUrl,
  'key': instance.key,
  'expireAt': instance.expireAt,
};

_PresignBatchUploadRespDTO _$PresignBatchUploadRespDTOFromJson(
  Map<String, dynamic> json,
) => _PresignBatchUploadRespDTO(
  files: (json['files'] as List<dynamic>)
      .map((e) => PresignUploadRespDTO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PresignBatchUploadRespDTOToJson(
  _PresignBatchUploadRespDTO instance,
) => <String, dynamic>{'files': instance.files};
