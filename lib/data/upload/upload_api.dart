import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/upload/upload_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_api.g.dart';

/// 上传用途, 决定文件的存储位置和所需权限: 头像只需登录, 菜品和店铺需要认证.
enum UploadBiz { avatar, foods, restaurants }

/// 接口分组 Upload: 申请签名, 确认上传完成.
///
/// 两步之间的 `PUT` 由 `UploadClient` 直接发往存储服务, 不经过业务网关.
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
