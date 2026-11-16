import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/network/upload_client.dart';
import 'package:eat/data/upload/upload_api.dart';
import 'package:eat/data/upload/upload_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'uploader.g.dart';

/// 图片上传器, 负责执行 "申请签名 – `PUT` 上传 – 确认完成" 三步流程并返回存储 key.
///
/// 多张图片一次申请所有上传地址 ([presignAll]), 再逐张上传.
/// 预先申请的地址临近 `expireAt` 时改为单张重新申请; 失败重试不传入旧地址, 总是重新申请.
class Uploader {
  Uploader(this._api, this._client);

  final UploadApi _api;
  final UploadClient _client;

  static const _contentType = 'image/jpeg';

  /// 距 `expireAt` 不足这段时间的地址视为过期, 留出开始 `PUT` 前的余量.
  static const _expiryMargin = Duration(seconds: 30);

  /// 为 [files] 一次申请上传地址, 超过 [UploadApi.batchMax] 张时分批申请; 结果与 [files] 顺序一致.
  Future<List<PresignDto>> presignAll(
    List<Uint8List> files, {
    required UploadBiz biz,
  }) async {
    final result = <PresignDto>[];
    for (var i = 0; i < files.length; i += UploadApi.batchMax) {
      final chunk = files.skip(i).take(UploadApi.batchMax).toList();
      final batch = await _api.presignBatch(
        files: [for (final f in chunk) _spec(f)],
        biz: biz,
      );
      final presigned = batch.files ?? const [];
      if (presigned.length != chunk.length) {
        throw const AppFailure(
          FailureKind.unknown,
          serverMessage: 'presign count mismatch',
        );
      }
      result.addAll(presigned);
    }
    return result;
  }

  /// 上传一张图片并返回存储 key.
  ///
  /// [presigned] 是 [presignAll] 预先申请的地址, 缺失或临近过期时单张重新申请.
  Future<String> upload(
    Uint8List jpeg, {
    required UploadBiz biz,
    PresignDto? presigned,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final presign = presigned != null && _usable(presigned)
        ? presigned
        : await _presignOne(jpeg, biz);
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

  /// 按顺序上传 [files] 并返回各自的存储 key; 两张及以上时一次申请所有地址.
  ///
  /// 每张完成后回调 [onEach], 调用方据此保存已上传的 key, 中途失败重试时不必重传.
  Future<List<String>> uploadAll(
    List<Uint8List> files, {
    required UploadBiz biz,
    void Function(int index, String key)? onEach,
  }) async {
    final presigned = files.length > 1
        ? await presignAll(files, biz: biz)
        : null;
    final keys = <String>[];
    for (var i = 0; i < files.length; i++) {
      final key = await upload(files[i], biz: biz, presigned: presigned?[i]);
      keys.add(key);
      onEach?.call(i, key);
    }
    return keys;
  }

  Future<PresignDto> _presignOne(Uint8List jpeg, UploadBiz biz) {
    final spec = _spec(jpeg);
    return _api.presign(
      fileName: spec.fileName,
      contentType: spec.contentType,
      fileSize: spec.fileSize,
      biz: biz,
    );
  }

  ({String fileName, String contentType, int fileSize}) _spec(Uint8List jpeg) =>
      (
        fileName: 'photo-${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: _contentType,
        fileSize: jpeg.length,
      );

  bool _usable(PresignDto presign) {
    final expireAt = presign.expireAt;
    return expireAt != null &&
        DateTime.fromMillisecondsSinceEpoch(expireAt)
            .isAfter(DateTime.now().add(_expiryMargin));
  }
}

@Riverpod(keepAlive: true)
Uploader uploader(Ref ref) =>
    Uploader(ref.watch(uploadApiProvider), ref.watch(uploadClientProvider));
