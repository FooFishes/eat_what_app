import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/upload/upload_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_api.g.dart';

/// 上传的用途，决定文件存在哪、要什么权限：头像只要登录，菜和店要认证。
enum UploadBiz { avatar, foods, restaurants }

/// 接口分组 Upload：申请签名、确认上传完成。中间的 `PUT` 走 `UploadClient`，不经过业务网关。
class UploadApi {
  UploadApi(this._client);

  final ApiClient _client;

  static const endpoints = ['POST /upload/presign', 'POST /upload/complete'];

  Future<PresignDto> presign({
    required String fileName,
    required String contentType,
    required int fileSize,
    required UploadBiz biz,
  }) async => decodeJson(
    await _client.post(
      '/upload/presign',
      body: {
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': fileSize,
        'biz': biz.name,
      },
    ),
    PresignDto.fromJson,
  );

  Future<void> complete(String key) =>
      _client.post('/upload/complete', body: {'key': key});
}

@Riverpod(keepAlive: true)
UploadApi uploadApi(Ref ref) => UploadApi(ref.watch(apiClientProvider));
