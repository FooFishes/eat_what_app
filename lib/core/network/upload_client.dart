import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_client.g.dart';

/// 向预签名地址 `PUT` 图片的客户端.
///
/// 不添加鉴权头: 鉴权头会把 token 泄露给存储服务, 还会破坏签名.
/// `Content-Type` 必须与申请签名时声明的值一致.
class UploadClient {
  UploadClient({HttpClientAdapter? adapter})
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;

  /// [onProgress] 接收 0–1 的进度.
  ///
  /// 失败统一转换为 [AppFailure]: 取消为 `cancelled`, 5xx 和无响应为 `network`, 其余为 `unknown`.
  /// 上传队列据此提供单张重试.
  Future<void> put(
    String url,
    Uint8List bytes, {
    required String contentType,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.put<void>(
        url,
        data: Stream.fromIterable([bytes]),
        cancelToken: cancelToken,
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const AppFailure.cancelled();
      }
      final status = e.response?.statusCode ?? 0;
      throw status >= 500 || status == 0
          ? const AppFailure.network()
          : AppFailure(FailureKind.unknown, code: status);
    }
  }
}

@Riverpod(keepAlive: true)
UploadClient uploadClient(Ref ref) => UploadClient();
