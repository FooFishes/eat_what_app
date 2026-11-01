import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:eat/features/auth/login_page.dart';
import 'package:eat/features/auth/password_login_page.dart';
import 'package:eat/features/auth/phone_login_page.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/inbox/inbox_page.dart';
import 'package:eat/features/kit/kit_page.dart';
import 'package:eat/features/nearby/nearby_page.dart';
import 'package:eat/features/profile/me_page.dart';
import 'package:eat/features/publish/add_dish_page.dart';
import 'package:eat/features/publish/new_shop_page.dart';
import 'package:eat/features/publish/publish_page.dart';
import 'package:eat/features/search/search_page.dart';
import 'package:eat/features/settings/about_page.dart';
import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/features/settings/account_page.dart';
import 'package:eat/features/settings/settings_page.dart';
import 'package:eat/features/system/not_found_page.dart';
import 'package:eat/features/verify/verify_page.dart';
import 'package:eat/router/guard.dart';
import 'package:eat/router/main_shell.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 路由表.
///
/// - 三个主页面是 `StatefulShellRoute` 的三个分支. 切换分支时各自的页面状态保留, 导航悬浮在页面上方.
/// - 其余页面放在根导航器上, 覆盖导航. 详情页和流程页不显示导航.
/// - 未登录可访问的页面在 `metadata` 上标记 [publicRoute]. 其余页面由守卫 [resolveRedirect] 导向登录页.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // push 打开的页面也写入 Web 地址栏, 使地址栏始终对应当前页面, 刷新或复制链接都回到同一页.
  // go_router 默认只有 go 会修改地址.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  // 登录态变化时让守卫重新判断当前地址: 登录后离开登录页, 过期或退出后进入登录页.
  final refresh = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => refresh.value = next);
  late final GoRouter router;
  router = GoRouter(
    initialLocation: Paths.discover,
    refreshListenable: refresh,
    observers: [CrashReporter.navigatorObserver()],
    redirect: (context, state) => resolveRedirect(
      location: state.uri,
      isPublic: state.metadata['public'] == true,
      session: ref.read(sessionProvider),
      canMatch: (uri) => router.configuration.findMatch(uri).isNotEmpty,
    ),
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
      GoRoute(
        path: Paths.login,
        metadata: publicRoute,
        builder: (_, state) => LoginPage(query: _loginQuery(state)),
        routes: [
          GoRoute(
            path: _child(Paths.loginPhone, Paths.login),
            builder: (_, state) => PhoneLoginPage(query: _loginQuery(state)),
          ),
          GoRoute(
            path: _child(Paths.loginPassword, Paths.login),
            builder: (_, state) => PasswordLoginPage(query: _loginQuery(state)),
          ),
        ],
      ),
      GoRoute(
        path: Paths.verify,
        builder: (_, state) => VerifyPage(
          onboarding: state.uri.queryParameters['onboarding'] == '1',
          from: safeReturnPath(
            state.uri.queryParameters['from'],
            (uri) => router.configuration.findMatch(uri).isNotEmpty,
          ),
        ),
      ),
      GoRoute(
        path: Paths.settings,
        builder: (_, _) => const SettingsPage(),
        routes: [
          GoRoute(
            path: _child(Paths.settingsAccount, Paths.settings),
            builder: (_, _) => const AccountPage(),
          ),
          GoRoute(
            path: _child(Paths.settingsAbout, Paths.settings),
            builder: (_, _) => const AboutPage(),
          ),
        ],
      ),
      // 发布流程的三个页面都使用顶层完整路径.
      // 发布成功后, 加菜页的 `_finish` 按路径前缀退出整个流程.
      GoRoute(
        path: Paths.publish,
        builder: (_, state) =>
            PublishPage(changing: state.uri.queryParameters['change'] == '1'),
      ),
      GoRoute(
        path: Paths.publishShopPattern,
        builder: (_, state) => NewShopPage(
          initialName: state.uri.queryParameters['name'] ?? '',
          returnShop: state.uri.queryParameters['return'] == '1',
        ),
      ),
      GoRoute(
        path: Paths.publishDishPattern,
        // 地址缺少有效的 shopId 时 (如手动拼写的地址) 重定向到选店.
        redirect: (_, state) =>
            int.tryParse(state.uri.queryParameters['shopId'] ?? '') == null
            ? Paths.publish
            : null,
        builder: (_, state) => AddDishPage(
          shopId: int.parse(state.uri.queryParameters['shopId']!),
        ),
      ),
      GoRoute(path: Paths.search, builder: (_, _) => const SearchPage()),
      GoRoute(path: Paths.inbox, builder: (_, _) => const InboxPage()),
      GoRoute(
        path: Paths.dishPattern,
        builder: (_, state) => switch (_idOf(state, 'dishId')) {
          final id? => DishPage(
            dishId: id,
            initial: state.extra is Dish ? state.extra! as Dish : null,
          ),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.shopPattern,
        builder: (_, state) => switch (_idOf(state, 'shopId')) {
          final id? => ShopPage(shopId: id),
          null => const NotFoundPage(),
        },
      ),
      if (kDebugMode)
        GoRoute(path: Paths.kit, builder: (_, _) => const KitPage()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}

/// 子路由使用相对路径: `/login` 下的 `/login/phone` 写作 `phone`.
String _child(String path, String parent) => path.substring(parent.length + 1);

/// 地址中的数字 id. 不是数字时 (如手动拼写的链接) 为 null, 页面显示 "页面不存在".
int? _idOf(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');

/// 登录各页之间原样传递的查询参数.
Map<String, String> _loginQuery(GoRouterState state) => {
  for (final key in const ['from', 'expired'])
    key: ?state.uri.queryParameters[key],
};
