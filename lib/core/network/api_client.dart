import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/failure/messages.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/core/platform/app_info.dart';
import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_dio/sentry_dio.dart';

part 'api_client.g.dart';

/// 网络层把会话相关的事件交给上层处理的回调.
///
/// 处理登录过期和请用户同意需要访问 `state` 中的登录态和 `features` 中的界面.
/// `core` 不能导入 `state`, 因此由 `state` 构造回调并注入.
class const ApiHooks({
  final VoidCallback? onSessionExpired,

  /// 带凭证的请求收到 [BizCodes.userDisabled] 后调用. 服务端已让该会话下线.
  final VoidCallback? onBanned,
  final VoidCallback? onForbidden,

  /// 已登录时收到要求同意的业务码 ([BizCodes.consentCodes]) 后调用: 请用户同意, 并提交同意.
  ///
  /// 正常返回表示已同意, 网络层随后重发一次原请求.
  /// 用户不同意或提交失败时抛出 [AppFailure], 网络层把它作为原请求的失败.
  final Future<void> Function()? requestConsent,
});

/// 业务接口客户端. 负责添加鉴权头, 解开 `{code, msg, data}` 外壳, 把失败统一转换为 [AppFailure].
///
/// - 只返回外壳中的 `data`.
/// - HTTP 200 但 `code` 非零同样视为失败.
/// - 写请求不自动重试. 读请求的重试由 Provider 的重试策略 [retryOnNetworkFailure] 负责.
///
/// [userAgent] 为 null 时不设置 `User-Agent`, 由浏览器或 Dart 运行时决定.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._tokens,
    this._hooks = const ApiHooks(),
    Future<String>? userAgent,
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
    if (userAgent != null) _dio.interceptors.add(_UserAgent(userAgent));
    if (kDebugMode) _dio.interceptors.add(const _DebugBodyLogger());
  }

  final Dio _dio;
  final TokenStore _tokens;
  final ApiHooks _hooks;
  Future<void>? _consenting;

  /// 同意成功的累计次数.
  ///
  /// 请求发出后若计数已变化, 说明其他请求已完成同意. 此时收到要求同意的业务码时重发原请求, 不再次请用户同意.
  var _grants = 0;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => _send('GET', path, query: query, headers: headers, cancel: cancelToken);

  /// [consentRetry] 为 false 时, 收到要求同意的业务码不请用户同意. 同意接口本身以 false 调用.
  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool consentRetry = true,
  }) => _send(
    'POST',
    path,
    body: body,
    query: query,
    headers: headers,
    cancel: cancelToken,
    consentRetry: consentRetry,
  );

  Future<Object?> delete(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => _send(
    'DELETE',
    path,
    query: query,
    headers: headers,
    cancel: cancelToken,
  );

  Future<Object?> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => _send('PUT', path, body: body, headers: headers, cancel: cancelToken);

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
          _hooks.requestConsent != null) {
        if (_grants == grants) await _consentOnce();
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
      final failure = switch (e.code) {
        // 服务端在封禁时让会话下线, 因此带凭证的请求按登录过期处理, 由 [_notify] 通知封禁.
        // 登录请求不带凭证, 仍按码表提示封禁.
        BizCodes.userDisabled when token != null => AppFailure(
          FailureKind.sessionExpired,
          code: BizCodes.userDisabled,
          serverMessage: e.msg,
        ),
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

  /// 并发的多个请求要求同意时只请用户确认一次, 其余请求等待同一结果.
  ///
  /// 用户不同意或提交失败时抛出 [AppFailure].
  Future<void> _consentOnce() async {
    final pending = _consenting ??= () async {
      try {
        await _hooks.requestConsent!();
        _grants++;
      } on AppFailure {
        rethrow;
      } on Object catch (e) {
        throw AppFailure(FailureKind.unknown, serverMessage: '$e');
      }
    }();
    try {
      await pending;
    } finally {
      if (identical(_consenting, pending)) _consenting = null;
    }
  }

  void _notify(AppFailure failure, AuthToken? sent) {
    switch (failure.kind) {
      // 仅当请求携带的凭证仍是当前凭证时通知.
      // 第一次通知会清除凭证, 并发过期的其余请求据此跳过, 避免重复处理.
      case FailureKind.sessionExpired
          when sent != null && identical(_tokens.current, sent):
        if (failure.code == BizCodes.userDisabled) {
          _hooks.onBanned?.call();
        } else {
          _hooks.onSessionExpired?.call();
        }
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
        // 接口不存在等少数情况返回非 200 状态码, 响应体仍是 `{code, msg}` 外壳.
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

/// 给 App 端的请求加上 [_value] 作为 `User-Agent`. 后端按它区分登录设备是 iOS 还是安卓.
///
/// 值依赖异步读取的版本名, 因此在发出请求前等待. 读取完成后每次请求只等待一个已完成的 Future.
class const _UserAgent(final Future<String> _value) extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['User-Agent'] = await _value;
    handler.next(options);
  }
}

/// App 端请求的 `User-Agent`, 如 `EatWhat/0.1.0 (Android)`. [version] 读取失败时为 null, 省略版本.
///
/// 后端在 `User-Agent` 中查找 `android` 和 `ios` (不区分大小写) 判断设备类型. 不能识别时登录设备显示为其他设备.
String appUserAgent(TargetPlatform platform, String? version) {
  final name = switch (platform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iOS',
    final other => other.name,
  };
  return '${version == null ? 'EatWhat' : 'EatWhat/$version'} ($name)';
}

/// 调试构建打印每个请求的请求体和响应体.
///
/// 不打印请求头, 以免凭证进入日志. 地址和正文里的手机号打码.
/// 只在 [kDebugMode] 下添加, 发布构建不含此拦截器.
class const _DebugBodyLogger() extends Interceptor {
  static final _mobile = RegExp(r'(?<!\d)(1\d{2})\d{4}(\d{4})(?!\d)');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _print('[api] → ${_line(options)}${_body(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _print(
      '[api] ← ${response.statusCode} ${_line(response.requestOptions)}'
      '${_body(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    _print(
      '[api] ✕ ${response?.statusCode ?? err.type.name} '
      '${_line(err.requestOptions)}${_body(response?.data)}',
    );
    handler.next(err);
  }

  static void _print(String text) =>
      debugPrint(text.replaceAllMapped(_mobile, (m) => '${m[1]}****${m[2]}'));

  static String _line(RequestOptions options) =>
      '${options.method} ${options.uri}';

  static String _body(Object? data) {
    if (data == null) return '';
    try {
      return '\n${const JsonEncoder.withIndent('  ').convert(data)}';
    } on Object {
      return '\n$data';
    }
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

/// Web 不能设置 `User-Agent`, 由浏览器决定.
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(
  baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
  tokens: ref.watch(tokenStoreProvider),
  hooks: ref.watch(apiHooksProvider),
  userAgent: kIsWeb
      ? null
      : ref
            .read(appVersionProvider.future)
            .then<String?>((v) => v, onError: (Object _) => null)
            .then((v) => appUserAgent(defaultTargetPlatform, v)),
);
