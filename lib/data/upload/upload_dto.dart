import 'package:json_annotation/json_annotation.dart';

part 'upload_dto.g.dart';

/// `/upload/presign` 的结果. 向 [putUrl] `PUT` 原始字节, 完成后把 [key] 写入业务字段.
@JsonSerializable(createToJson: false)
class const PresignDto({
  final String? putUrl,
  final String? key,
  final int? expireAt,
}) {
  factory PresignDto.fromJson(Map<String, dynamic> json) =>
      _$PresignDtoFromJson(json);
}
