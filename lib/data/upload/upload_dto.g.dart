// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignDto _$PresignDtoFromJson(Map<String, dynamic> json) => PresignDto(
  putUrl: json['putUrl'] as String?,
  key: json['key'] as String?,
  expireAt: (json['expireAt'] as num?)?.toInt(),
);

PresignBatchDto _$PresignBatchDtoFromJson(Map<String, dynamic> json) =>
    PresignBatchDto(
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => PresignDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
