import 'package:eat_what_app/model/upload/presign_batch_upload_file_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'presign_batch_upload_req_dto.freezed.dart';
part 'presign_batch_upload_req_dto.g.dart';

@freezed
abstract class PresignBatchUploadReqDto with _$PresignBatchUploadReqDto {
  const factory PresignBatchUploadReqDto({
    String? biz,
    required List<PresignBatchUploadFileDto> files,
  }) = _PresignBatchUploadReqDto;

  factory PresignBatchUploadReqDto.fromJson(Map<String, dynamic> json) =>
      _$PresignBatchUploadReqDtoFromJson(json);
}