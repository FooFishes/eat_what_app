import 'package:eat_what_app/core/api/model/result.dart';
import 'package:eat_what_app/core/api/request_client.dart';
import 'package:eat_what_app/model/upload/presign_batch_upload_req_dto.dart';
import 'package:eat_what_app/model/upload/presign_batch_upload_resp_dto.dart';
import 'package:eat_what_app/model/upload/presign_upload_req_dto.dart';
import 'package:eat_what_app/model/upload/presign_upload_resp_dto.dart';

import '../core/constant/urls.dart';

class UploadRepository {
  final RequestClient _api;
  UploadRepository(this._api);

  Future<Result<PresignUploadRespDto>> presign(PresignUploadReqDto dto) {
    return _api.post<PresignUploadRespDto>(
      Urls.uploadPresign,
      data: dto.toJson(),
      fromJson: (json) => PresignUploadRespDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<PresignBatchUploadRespDto>> presignBatch(
    PresignBatchUploadReqDto dto,
  ) {
    return _api.post<PresignBatchUploadRespDto>(
      Urls.uploadPresignBatch,
      data: dto.toJson(),
      fromJson: (json) => PresignBatchUploadRespDto.fromJson(json as Map<String, dynamic>),
    );
  }
}