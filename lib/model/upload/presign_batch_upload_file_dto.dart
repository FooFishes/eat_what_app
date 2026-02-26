import 'package:freezed_annotation/freezed_annotation.dart';

part 'presign_batch_upload_file_dto.freezed.dart';
part 'presign_batch_upload_file_dto.g.dart';

@freezed
abstract class PresignBatchUploadFileDto with _$PresignBatchUploadFileDto {
  const factory PresignBatchUploadFileDto({
    required String fileName,
    required String contentType,
    required int fileSize,
  }) = _PresignBatchUploadFileDto;

  factory PresignBatchUploadFileDto.fromJson(Map<String, dynamic> json) =>
      _$PresignBatchUploadFileDtoFromJson(json);
}