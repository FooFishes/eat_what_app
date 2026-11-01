import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_dio/sentry_dio.dart';

part 'api_client.g.dart';

/// 网络层把会话相关的事件交给上层处理的回调.
///
/// 登录过期和自动同意都要修改登录态, 登录态属于 `state`.
/// `core` 不能导入 `state`, 因此由 `state` 构造回调并注入.
class const ApiHooks({
  final VoidCallback? onSessionExpired,
  final VoidCallback? onForbidden,
  final Future<bool> Function()? grantConsent,
});

/// 业务接口客户端. 负责添加鉴权头, 解开 `{code, msg, data}` 外壳, 把失败统一转换为 [AppFailure].
///
/// - 只返回外壳中的 `data`.
/// - HTTP 200 但 `code` 非零同样视为失败.
/// - 写请求不自动重试. 读请求的重试由 Provider 的重试策略 [retryOnNetworkFailure] 负责.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._tokens,
    this._hooks = const ApiHooks(),
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           sendTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           responseType: ResponseType.json,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    // 只给崩溃上报加上最近请求的面包屑. 失败的请求由页面处理, 不作为错误上报.
    _dio.addSentry(captureFailedRequests: false);
  }

  final Dio _dio;
  final TokenStore _tokens;
  final ApiHooks _hooks;
  Future<bool>? _granting;

  /// 自动同意成功的累计次数.
  ///
  /// 请求发出后若计数已变化, 说明其他请求已完成同意. 此时收到要求同意的业务码直接重发, 不再次同意.
  var _grants = 0;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => _send('GET', path, query: query, headers: headers, cancel: cancelToken);

  /// [consentRetry] 为 false 时, 收到要求同意的业务码不自动同意. 同意接口本身以 false 调用.
  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool consentRetry = true,
  }) => _send(
    'POST',
    path,
    body: body,
    headers: headers,
    cancel: cancelToken,
    consentRetry: consentRetry,
  );

  Future<Object?> delete(String path, {CancelToken? cancelToken}) =>
      _send('DELETE', path, cancel: cancelToken);

  Future<Object?> put(String path, {Object? body, CancelToken? cancelToken}) =>
      _send('PUT', path, body: body, cancel: cancelToken);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    Map<String, String>? headers,
    CancelToken? cancel,
    bool consentRetry = true,
  }) async {
    final token = _tokens.current;
    final grants = _grants;
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancel,
        options: Options(
          method: method,
          headers: {
            ...?headers,
            if (token != null) token.name: token.headerValue,
          },
        ),
      );
      return _unwrap(response.data);
    } on _BizError catch (e) {
      _log(method, path, e.code);
      if (BizCodes.consentCodes.contains(e.code) &&
          consentRetry &&
          token != null &&
          _hooks.grantConsent != null) {
        if (_grants != grants || await _grantOnce()) {
          return _send(
            method,
            path,
            query: query,
            body: body,
            headers: headers,
            cancel: cancel,
            consentRetry: false,
          );
        }
        throw AppFailure(
          FailureKind.unknown,
          code: e.code,
          serverMessage: e.msg,
        );
      }
      final failure = switch (e.code) {
        final Object code => AppFailure.fromCode(
          code,
          serverMessage: e.msg,
          data: e.data,
        ),
        null => AppFailure(FailureKind.unknown, serverMessage: e.msg),
      };
      _notify(failure, token);
      throw failure;
    } on DioException catch (e) {
      final failure = _fromDio(e);
      _log(method, path, failure.code ?? failure.kind.name);
      _notify(failure, token);
      throw failure;
    }
  }

  /// 并发的多个请求要求同意时只调用一次同意接口, 其余请求等待同一结果.
  ///
  /// 同意失败返回 false, 不抛出异常.
  Future<bool> _grantOnce() async {
    final pending = _granting ??= () async {
      try {
        final granted = await _hooks.grantConsent!();
        if (granted) _grants++;
        return granted;
      } on Object {
        return false;
      }
    }();
    try {
      return await pending;
    } finally {
      if (identical(_granting, pending)) _granting = null;
    }
  }

  void _notify(AppFailure failure, AuthToken? sent) {
    switch (failure.kind) {
      // 仅当请求携带的凭证仍是当前凭证时通知.
      // 第一次通知会清除凭证, 并发过期的其余请求据此跳过, 避免重复处理.
      case FailureKind.sessionExpired
          when sent != null && identical(_tokens.current, sent):
        _hooks.onSessionExpired?.call();
      case FailureKind.forbidden:
        _hooks.onForbidden?.call();
      default:
    }
  }

  static Object? _unwrap(Object? body) {
    if (body is! Map) throw const _BizError(null, 'unexpected body');
    final code = body['code'];
    if (code == BizCodes.success) return body['data'];
    throw _BizError(code, '${body['msg']}', body['data']);
  }

  static AppFailure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return const AppFailure.cancelled();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        // 网关和鉴权拦截返回非 200 状态码和 `ErrorResponse`, 其中 `code` 是字符串, 原样保留.
        if (body is Map) {
          final code = body['code'];
          if (code != null && code != BizCodes.success) {
            return AppFailure.fromCode(code, serverMessage: '${body['msg']}');
          }
        }
        return AppFailure(
          status >= 500 ? FailureKind.server : FailureKind.unknown,
          code: status,
        );
      case DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.transformTimeout ||
          DioExceptionType.connectionError ||
          DioExceptionType.badCertificate ||
          DioExceptionType.unknown:
        return const AppFailure.network();
    }
  }

  /// 记录失败的请求: 调试构建打印日志, 同时作为崩溃上报的面包屑.
  ///
  /// 只记录方法, 路径和业务码.
  /// 不记录参数, 请求头和响应体, 以免凭证和个人信息进入日志.
  static void _log(String method, String path, Object? code) {
    if (kDebugMode) debugPrint('[api] $method $path → $code');
    CrashReporter.recordRequestFailure(method, path, code);
  }
}

/// 外壳中的 `code` 不为 0.
class const _BizError(
  final Object? code,
  final String? msg, [
  final Object? data,
]) implements Exception;

/// 用 [fromJson] 把 `data` 解析为 DTO.
///
/// 结构不符时抛出 [FailureKind.unknown], 避免解析异常传到页面.
T decodeJson<T>(Object? data, T Function(Map<String, dynamic> json) fromJson) {
  if (data is! Map<String, dynamic>) {
    throw const AppFailure(FailureKind.unknown, serverMessage: 'bad data');
  }
  try {
    return fromJson(data);
  } on Object catch (e) {
    throw AppFailure(FailureKind.unknown, serverMessage: '$e');
  }
}

/// 读请求的重试策略: 仅在网络不可达时重试, 最多 2 次.
///
/// 业务错误, 登录过期和解析失败不重试.
Duration? retryOnNetworkFailure(int retryCount, Object error) {
  if (retryCount >= 2) return null;
  if (error is! AppFailure || error.kind != FailureKind.network) return null;
  return Duration(milliseconds: 400 * (1 << retryCount));
}

/// 网络层的会话回调. 默认为空, 由 `state/api_hooks.dart` 覆盖为实际处理.
@Riverpod(keepAlive: true)
ApiHooks apiHooks(Ref ref) => const ApiHooks();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(
  baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
  tokens: ref.watch(tokenStoreProvider),
  hooks: ref.watch(apiHooksProvider),
);
