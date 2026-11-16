import 'package:clock/clock.dart';
import 'package:eat/core/failure/app_failure.dart';
import 'package:eat/core/telemetry/analytics_event.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'page_analytics.g.dart';

/// 按路由统一记录页面停留 (`page_view`) 和加载失败 (`load_failed`), 页面里不各自记录.
///
/// - 路由地址 (不含查询参数) 变化时结束上一个页面的计时并记一条 `page_view`, 带停留时长.
/// - 退到后台时同样结束当前页面的计时, 回到前台重新开始.
/// - 底部面板和对话框不改变路由, 计入下面的页面.
class PageAnalytics {
  PageAnalytics(this._router, this._track) {
    _router.routerDelegate.addListener(_onRouteChanged);
    _lifecycle = AppLifecycleListener(onHide: _pause, onShow: _resume);
    _onRouteChanged();
  }

  final GoRouter _router;
  final void Function(AnalyticsEvent event) _track;
  late final AppLifecycleListener _lifecycle;

  String? _location;
  AnalyticsPage? _page;

  /// 当前页面开始计时的时间. 在后台或还没有页面时为 null.
  DateTime? _since;
  var _hidden = false;

  /// 当前显示的页面分类, 还没有页面时为 null.
  AnalyticsPage? get page => _page;

  void _onRouteChanged() {
    // push 打开的页面不改变外层的地址和模板, 要取最上面一层 push 的匹配结果.
    var match = _router.routerDelegate.currentConfiguration;
    while (match.lastOrNull is ImperativeRouteMatch) {
      match = (match.last as ImperativeRouteMatch).matches;
    }
    if (match.isEmpty && !match.isError) return;
    final location = match.uri.path;
    if (location == _location) return;
    _end();
    _location = location;
    _page = match.isError
        ? AnalyticsPage.other
        : analyticsPageOf(match.fullPath);
    if (!_hidden) _since = clock.now();
  }

  void _pause() {
    _hidden = true;
    _end();
  }

  void _resume() {
    _hidden = false;
    if (_page != null) _since = clock.now();
  }

  void _end() {
    final page = _page;
    final since = _since;
    _since = null;
    if (page == null || since == null) return;
    final elapsed = clock.now().difference(since);
    _track(
      PageViewEvent(
        page,
        duration: elapsed.isNegative ? Duration.zero : elapsed,
      ),
    );
  }

  /// 记一条加载失败. 页面取失败状态所在的路由, 在底部面板等不属于路由的位置时取当前页面.
  void loadFailed(BuildContext context, Object? error) {
    AnalyticsPage? page;
    try {
      page = analyticsPageOf(GoRouterState.of(context).fullPath);
    } on GoError {
      page = _page;
    }
    final code = switch (error) {
      AppFailure(code: final num code) => code.toInt(),
      _ => null,
    };
    _track(LoadFailedEvent(page ?? AnalyticsPage.other, code: code));
  }

  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    _lifecycle.dispose();
  }
}

/// 路由模板 (如 `/dishes/:dishId`) 对应的统计页面分类.
///
/// 菜品和店铺下的子页面 (评论, 修改记录, 编辑) 归入菜品和店铺. 附近, 设置, 发布, 登录等归入其他.
AnalyticsPage analyticsPageOf(String? fullPath) {
  bool under(String prefix) =>
      fullPath == prefix || (fullPath?.startsWith('$prefix/') ?? false);
  if (fullPath == Paths.discover) return AnalyticsPage.home;
  if (under(Paths.topics)) return AnalyticsPage.recommend;
  if (under(Paths.search)) return AnalyticsPage.search;
  if (under(Paths.shopPattern)) return AnalyticsPage.restaurant;
  if (under(Paths.dishPattern)) return AnalyticsPage.food;
  if (under(Paths.inbox)) return AnalyticsPage.message;
  if (under(Paths.me) || under(Paths.userPattern)) return AnalyticsPage.profile;
  return AnalyticsPage.other;
}

@Riverpod(keepAlive: true)
PageAnalytics pageAnalytics(Ref ref) {
  final analytics = PageAnalytics(
    ref.watch(appRouterProvider),
    (event) => ref.read(analyticsProvider).track(event),
  );
  ref.onDispose(analytics.dispose);
  return analytics;
}
