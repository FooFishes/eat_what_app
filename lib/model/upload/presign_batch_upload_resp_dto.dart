import 'package:eat_what_app/model/upload/presign_upload_resp_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'presign_batch_upload_resp_dto.freezed.dart';
part 'presign_batch_upload_resp_dto.g.dart';

@freezed
abstract class PresignBatchUploadRespDto with _$PresignBatchUploadRespDto {
  const factory PresignBatchUploadRespDto({
    List<PresignUploadRespDto>? files,
  }) = _PresignBatchUploadRespDto;

  factory PresignBatchUploadRespDto.fromJson(Map<String, dynamic> json) =>
      _$PresignBatchUploadRespDtoFromJson(json);
}