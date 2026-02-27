import 'package:freezed_annotation/freezed_annotation.dart';

part 'presign_upload_dto.freezed.dart';
part 'presign_upload_dto.g.dart';

@freezed
abstract class PresignUploadRespDTO with _$PresignUploadRespDTO {
  const factory PresignUploadRespDTO({
    required String putUrl,
    required String key,
    required int expireAt,
  }) = _PresignUploadRespDTO;

  factory PresignUploadRespDTO.fromJson(Map<String, dynamic> json) =>
      _$PresignUploadRespDTOFromJson(json);
}

@freezed
abstract class PresignBatchUploadRespDTO with _$PresignBatchUploadRespDTO {
  const factory PresignBatchUploadRespDTO({
    required List<PresignUploadRespDTO> files,
  }) = _PresignBatchUploadRespDTO;

  factory PresignBatchUploadRespDTO.fromJson(Map<String, dynamic> json) =>
      _$PresignBatchUploadRespDTOFromJson(json);
}
