import 'package:eat/app.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'analytics.dart';
import 'fakes.dart';
import 'screen.dart';

/// 在 [env] 的模拟环境中启动完整 App, 并导航到 [location].
///
/// 启动前关闭动画. 登录页的转盘持续旋转, 开启动画时 `pumpAndSettle` 无法结束.
///
/// 使用统计默认换成只记在内存里的 [RecordingAnalytics]: 真实实现攒批时会起 30 秒的定时器,
/// 测试中途同意隐私政策后开始采集, 没有调用 [unmountApp] 的测试结束时定时器仍未触发.
/// 上报本身由 `test/state/analytics_test.dart` 覆盖.
Future<(ProviderContainer, GoRouter)> pumpApp(
  WidgetTester tester,
  TestEnv env, {
  SessionState? session,
  AuthToken? token,
  String? location,
  Size size = const Size(390, 844),
  List<Override> overrides = const [],
}) async {
  useScreen(tester, size);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final container = await env.container(
    session: session,
    token: token,
    overrides: overrides.contains(recordAnalytics)
        ? overrides
        : [...overrides, recordAnalytics],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EatApp()),
  );
  final router = container.read(appRouterProvider);
  if (location != null) router.go(location);
  await tester.pumpAndSettle();
  return (container, router);
}

/// 当前路由地址, 对应 Web 地址栏中的内容.
String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

/// 卸载 App 并释放 Provider.
///
/// 详情页的 Provider 在失去监听者后仍由 `cacheFor` 的定时器保留一段时间.
/// 测试结束前不释放, 测试框架会报告未完成的定时器.
Future<void> unmountApp(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  // 容器释放时取消的请求仍有 dio 的零时长定时器未触发. 推进一帧使该定时器到期.
  await tester.pump();
}
