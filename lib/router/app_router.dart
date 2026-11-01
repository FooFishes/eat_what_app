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

/// 路由表。
///
/// 三个主页面是 `StatefulShellRoute` 的三个分支，切换时各自的页面状态留着，导航悬浮在上面；
/// 其余页面都放在根导航器上，盖住导航（详情和流程页不显示导航）。没登录能进的页面在 `metadata`
/// 上标 [publicRoute]，其余页面由守卫送去登录（[resolveRedirect]）。
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // push 打开的页面（发布、以后的详情页）也写进 Web 的地址栏：地址栏就是当前页面，
  // 刷新或复制链接都回到同一页；默认只有 go 才改地址。
  GoRouter.optionURLReflectsImperativeAPIs = true;
  // 登录态一变就让守卫重新判断当前地址：登录后离开登录页，过期、退出后去登录页。
  final refresh = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => refresh.value = next);
  late final GoRouter router;
  router = GoRouter(
    initialLocation: Paths.discover,
    refreshListenable: refresh,
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
      // 发布流程的三页都写成顶层的完整路径：发布成功后按路径前缀退出整个流程（加菜页的 _finish）。
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
        // 没带店（手拼的地址）时回到选店。
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

/// 子路由写相对路径：`/login/phone` 在 `/login` 下面是 `phone`。
String _child(String path, String parent) => path.substring(parent.length + 1);

/// 地址里的数字 id；不是数字（手拼的链接）时为 null，显示「页面不存在」。
int? _idOf(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');

/// 登录各页之间原样传递的参数。
Map<String, String> _loginQuery(GoRouterState state) => {
  for (final key in const ['from', 'expired'])
    key: ?state.uri.queryParameters[key],
};
