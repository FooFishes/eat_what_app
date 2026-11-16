import 'package:eat/core/network/api_client.dart';
import 'package:eat/data/upload/upload_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_api.g.dart';

/// 图片上传业务用途, 决定文件的存储路径与所需权限; 头像和反馈截图仅需登录, 菜品, 店铺和评论则需完成身份认证.
///
/// 各用途下的文件均通过公开的稳定地址访问, 发布后立即可见.
enum UploadBiz { avatar, foods, restaurants, comments, feedback }

/// UploadApi 调用的接口路径, 相对于业务接口地址.
abstract final class UploadEndpoints {
  static const presign = '/upload/presign';
  static const complete = '/upload/complete';
}

/// 文件上传接口 (`Upload` 分组), 负责申请预签名 URL 与确认上传完成.
///
/// 两步之间的 `PUT` 上传由 `UploadClient` 直连对象存储服务, 不经过业务网关.
class UploadApi {
  UploadApi(this._client);

  final ApiClient _client;

  Future<PresignDto> presign({
    required String fileName,
    required String contentType,
    required int fileSize,
    required UploadBiz biz,
  }) async => decodeJson(
    await _client.post(
      UploadEndpoints.presign,
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
      _client.post(UploadEndpoints.complete, body: {'key': key});
}

@Riverpod(keepAlive: true)
UploadApi uploadApi(Ref ref) => UploadApi(ref.watch(apiClientProvider));
