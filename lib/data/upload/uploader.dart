import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/upload_client.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'uploader.g.dart';

/// 图片上传器, 负责执行 "申请签名 – `PUT` 上传 – 确认完成" 三步流程并返回存储 key.
///
/// 每次上传 (含失败重试) 均重新申请签名, 以避免沿用已超过 `expireAt` 的过期地址.
class Uploader {
  Uploader(this._api, this._client);

  final UploadApi _api;
  final UploadClient _client;

  static const _contentType = 'image/jpeg';

  Future<String> upload(
    Uint8List jpeg, {
    required UploadBiz biz,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final presign = await _api.presign(
      fileName: 'photo-${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: _contentType,
      fileSize: jpeg.length,
      biz: biz,
    );
    final putUrl = presign.putUrl;
    final key = presign.key;
    if (putUrl == null || key == null) {
      throw const AppFailure(FailureKind.unknown, serverMessage: 'no putUrl');
    }
    if (cancelToken?.isCancelled ?? false) throw const AppFailure.cancelled();
    await _client.put(
      putUrl,
      jpeg,
      contentType: _contentType,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    if (cancelToken?.isCancelled ?? false) throw const AppFailure.cancelled();
    await _api.complete(key);
    return key;
  }
}

@Riverpod(keepAlive: true)
Uploader uploader(Ref ref) =>
    Uploader(ref.watch(uploadApiProvider), ref.watch(uploadClientProvider));
