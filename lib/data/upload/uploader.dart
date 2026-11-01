import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/upload_client.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'uploader.g.dart';

/// 传一张图的三步（技术架构 13.3）：申请签名 → 向预签名地址 `PUT` → 确认完成，返回存储的 key。
///
/// 每次都从申请签名开始：失败后重试时，上一次的签名可能已经过了 `expireAt`。
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
