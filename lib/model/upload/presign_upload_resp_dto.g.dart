// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_upload_resp_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PresignUploadRespDto _$PresignUploadRespDtoFromJson(
  Map<String, dynamic> json,
) => _PresignUploadRespDto(
  putUrl: json['putUrl'] as String?,
  key: json['key'] as String?,
  expireAt: (json['expireAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$PresignUploadRespDtoToJson(
  _PresignUploadRespDto instance,
) => <String, dynamic>{
  'putUrl': instance.putUrl,
  'key': instance.key,
  'expireAt': instance.expireAt,
};
