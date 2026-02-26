import 'package:freezed_annotation/freezed_annotation.dart';

part 'presign_upload_resp_dto.freezed.dart';
part 'presign_upload_resp_dto.g.dart';

@freezed
abstract class PresignUploadRespDto with _$PresignUploadRespDto {
  const factory PresignUploadRespDto({
    String? putUrl,
    String? key,
    int? expireAt,
  }) = _PresignUploadRespDto;

  factory PresignUploadRespDto.fromJson(Map<String, dynamic> json) =>
      _$PresignUploadRespDtoFromJson(json);
}