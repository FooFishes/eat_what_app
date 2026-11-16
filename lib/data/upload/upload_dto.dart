import 'package:json_annotation/json_annotation.dart';

part 'upload_dto.g.dart';

/// `/upload/presign` 接口响应; 向 [putUrl] 通过 `PUT` 上传原始字节流后, 将 [key] 写入对应的业务字段.
@JsonSerializable(createToJson: false)
class const PresignDto({
  final String? putUrl,
  final String? key,
  final int? expireAt,
}) {
  factory PresignDto.fromJson(Map<String, dynamic> json) =>
      _$PresignDtoFromJson(json);
}
