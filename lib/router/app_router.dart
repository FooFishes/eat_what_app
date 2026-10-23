import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/features/kit/kit_page.dart';
import 'package:eat/features/nearby/nearby_page.dart';
import 'package:eat/features/profile/me_page.dart';
import 'package:eat/features/publish/publish_page.dart';
import 'package:eat/features/system/not_found_page.dart';
import 'package:eat/router/main_shell.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 路由表。
///
/// 三个主页面是 `StatefulShellRoute` 的三个分支，切换时各自的页面状态留着，导航悬浮在上面；
/// 其余页面都放在根导航器上，盖住导航（详情和流程页不显示导航）。
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // push 打开的页面（发布、以后的详情页）也写进 Web 的地址栏：地址栏就是当前页面，
  // 刷新或复制链接都回到同一页；默认只有 go 才改地址。
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final router = GoRouter(
    initialLocation: Paths.discover,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Paths.discover),
      StatefulShellRoute(
        builder: (context, state, shell) => MainShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            MainBranches(shell: shell, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.discover,
                builder: (_, _) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.nearby,
                builder: (_, _) => const NearbyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Paths.me, builder: (_, _) => const MePage()),
            ],
          ),
        ],
      ),
      GoRoute(path: Paths.publish, builder: (_, _) => const PublishPage()),
      if (kDebugMode)
        GoRoute(path: Paths.kit, builder: (_, _) => const KitPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
