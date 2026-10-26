import 'package:eat/app.dart';
import 'package:eat/core/network/auth_token.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';
import 'screen.dart';

/// 在 [env] 的假环境里启动整个 App，停在 [location]。
///
/// 关掉动画：登录页的转盘一直在转，开着动画 `pumpAndSettle` 永远等不到停。
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
    overrides: overrides,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EatApp()),
  );
  final router = container.read(appRouterProvider);
  if (location != null) router.go(location);
  await tester.pumpAndSettle();
  return (container, router);
}

/// 地址栏里的地址。
String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();
