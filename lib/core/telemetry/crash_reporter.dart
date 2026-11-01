import 'package:eat/core/config/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'crash_reporter.g.dart';

/// 崩溃上报, 由 Sentry 实现.
///
/// 同意隐私政策后调用 [start] 才开始上报. 之前和 `SENTRY_DSN` 为空时, 所有调用都不上报.
/// 只上报堆栈, 设备与版本信息和账号 id. 不截屏, 不录制会话, 不记录请求参数和响应体.
class CrashReporter {
  CrashReporter(this._config);

  final AppConfig _config;
  var _started = false;

  bool get enabled => _config.sentryDsn.isNotEmpty;

  /// 启动上报. 重复调用只生效一次.
  ///
  /// [patch] 是热更新的补丁号, 作为 Sentry 的 `dist`, 用于区分同一版本的不同补丁.
  Future<void> start({int? patch}) async {
    if (_started || !enabled) return;
    _started = true;
    final info = await PackageInfo.fromPlatform();
    await SentryFlutter.init((o) {
      o.dsn = _config.sentryDsn;
      o.environment = _config.envName;
      o.release = releaseName(info.version, info.buildNumber);
      o.dist = patch?.toString();
      o.debug = false;
      o.sendDefaultPii = false;
      o.attachScreenshot = false;
      o.attachViewHierarchy = false;
      o.enableUserInteractionBreadcrumbs = false;
      o.enableUserInteractionTracing = false;
      o.enableAutoPerformanceTracing = false;
      o.tracesSampleRate = null;
      o.replay.sessionSampleRate = 0;
      o.replay.onErrorSampleRate = 0;
      o.beforeSend = scrubEvent;
      o.beforeBreadcrumb = scrubBreadcrumb;
    });
  }

  /// 设置当前账号. 未登录时传 null. 只上报账号 id.
  Future<void> setUser(int? id) async {
    if (!_started) return;
    await Sentry.configureScope(
      (scope) => scope.setUser(id == null ? null : SentryUser(id: '$id')),
    );
  }

  /// 记录一条网络请求失败的面包屑. 只含方法, 路径和业务码, 不含参数.
  static void recordRequestFailure(String method, String path, Object? code) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'api',
        type: 'http',
        level: SentryLevel.warning,
        data: {'method': method, 'path': path, 'code': '$code'},
      ),
    );
  }

  /// 记录路由跳转的面包屑, 挂在根导航器上.
  ///
  /// 不开启自动性能追踪.
  static NavigatorObserver navigatorObserver() =>
      SentryNavigatorObserver(enableAutoTransactions: false);

  /// Sentry 的 `release`, 如 `eat@0.3.0+30`. CI 上传符号表时使用同一格式.
  @visibleForTesting
  static String releaseName(String version, String buildNumber) =>
      'eat@$version+$buildNumber';

  /// 上报前去掉事件中可能包含个人信息的部分.
  ///
  /// - 请求: 只保留方法和不带查询参数的地址. 去掉请求头, Cookie, 请求体和查询参数.
  /// - 账号: 只保留 id.
  @visibleForTesting
  static SentryEvent scrubEvent(SentryEvent event, Hint hint) {
    if (event.request case final request?) {
      event.request = SentryRequest(
        method: request.method,
        url: _stripQuery(request.url),
      );
    }
    if (event.user case SentryUser(:final id)) {
      event.user = id == null ? null : SentryUser(id: id);
    }
    event.breadcrumbs = event.breadcrumbs
        ?.map((b) => scrubBreadcrumb(b, hint))
        .nonNulls
        .toList();
    return event;
  }

  /// 去掉面包屑中的查询参数和路由参数.
  ///
  /// 查询参数和路由参数可能包含搜索词等用户输入.
  @visibleForTesting
  static Breadcrumb? scrubBreadcrumb(Breadcrumb? crumb, Hint hint) {
    if (crumb == null) return null;
    final data = crumb.data;
    if (data == null) return crumb;
    crumb.data = {
      for (final MapEntry(:key, :value) in data.entries)
        if (!key.contains('arguments') &&
            key != 'http.query' &&
            key != 'http.fragment')
          key: key == 'url' && value is String ? _stripQuery(value) : value,
    };
    return crumb;
  }

  static String? _stripQuery(String? url) {
    if (url == null) return null;
    final end = url.indexOf(RegExp('[?#]'));
    return end < 0 ? url : url.substring(0, end);
  }
}

@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) =>
    CrashReporter(ref.watch(appConfigProvider));
