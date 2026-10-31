import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

/// 网络层遇到会话问题时交给上层处理的回调。
///
/// `core` 不能导入 `data` 和 `state`，所以登录过期、自动同意这些要动登录态的事，由 `state`
/// 构造时传进来（技术架构 9.5）。
class const ApiHooks({
  final VoidCallback? onSessionExpired,
  final VoidCallback? onForbidden,
  final Future<bool> Function()? grantConsent,
});

/// 业务接口的客户端：加鉴权头、拆 `{code, msg, data}` 外壳，把各种失败都转成 [AppFailure]。
///
/// 只返回外壳里的 `data`；HTTP 200 带非零 `code` 也算失败。写操作不自动重试，读请求的重试
/// 由 Provider 的重试策略做（[retryOnNetworkFailure]）。
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
  }

  final Dio _dio;
  final TokenStore _tokens;
  final ApiHooks _hooks;
  Future<bool>? _granting;

  /// 自动同意成功的次数。请求发出后又有别的请求同意成功了，这个请求再遇到要求同意时直接重发，
  /// 不再同意一次。
  var _grants = 0;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => _send('GET', path, query: query, headers: headers, cancel: cancelToken);

  /// [consentRetry] 为 false 时遇到需要同意的码不自动同意，同意接口自己就这样调。
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
        final Object code => AppFailure.fromCode(code, serverMessage: e.msg),
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

  /// 几个请求同时要求同意时只同意一次，其余等同一个结果。同意失败算 false，不抛异常。
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
      // 只在这次请求带的还是当前凭证时通知：同时过期的其余请求看到凭证已清掉，就不再重复处理。
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
    throw _BizError(code, '${body['msg']}');
  }

  static AppFailure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return const AppFailure.cancelled();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        // 集群或授权拦截返回非 200 加 `ErrorResponse`，`code` 是字符串，按字符串保留。
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

  /// 调试构建里打一行请求结果。只打方法、路径和业务码，不打参数、请求头和响应体。
  static void _log(String method, String path, Object? code) {
    if (kDebugMode) debugPrint('[api] $method $path → $code');
  }
}

/// 外壳里的 `code` 不是 0。
class const _BizError(final Object? code, final String? msg)
    implements Exception;

/// 把 `data` 按 [fromJson] 解析成 DTO；形状不对时当作「未知」失败，不让解析异常漏到页面。
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

/// 读请求的自动重试：只重试连不上网，最多 2 次；业务错误、登录过期、解析失败都不重试。
Duration? retryOnNetworkFailure(int retryCount, Object error) {
  if (retryCount >= 2) return null;
  if (error is! AppFailure || error.kind != FailureKind.network) return null;
  return Duration(milliseconds: 400 * (1 << retryCount));
}

/// 网络层遇到登录过期、需要同意时的回调，由 `state` 覆盖成真正的处理（`state/api_hooks.dart`）。
@Riverpod(keepAlive: true)
ApiHooks apiHooks(Ref ref) => const ApiHooks();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(
  baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
  tokens: ref.watch(tokenStoreProvider),
  hooks: ref.watch(apiHooksProvider),
);
