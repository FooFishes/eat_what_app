import 'package:freezed_annotation/freezed_annotation.dart';

part 'presign_upload_req_dto.freezed.dart';
part 'presign_upload_req_dto.g.dart';

@freezed
abstract class PresignUploadReqDto with _$PresignUploadReqDto {
  const factory PresignUploadReqDto({
    required String fileName,
    required String contentType,
    required int fileSize,
    String? biz,
  }) = _PresignUploadReqDto;

  factory PresignUploadReqDto.fromJson(Map<String, dynamic> json) =>
      _$PresignUploadReqDtoFromJson(json);
}