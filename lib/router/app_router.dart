import 'package:eat/core/telemetry/crash_reporter.dart';
import 'package:eat/features/auth/login_page.dart';
import 'package:eat/features/auth/password_login_page.dart';
import 'package:eat/features/auth/phone_login_page.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/features/comments/comments_page.dart';
import 'package:eat/features/discover/discover_page.dart';
import 'package:eat/features/dish/dish_history_page.dart';
import 'package:eat/features/dish/dish_page.dart';
import 'package:eat/features/inbox/inbox_page.dart';
import 'package:eat/features/kit/kit_page.dart';
import 'package:eat/features/nearby/nearby_page.dart';
import 'package:eat/features/profile/edit_profile_page.dart';
import 'package:eat/features/profile/follows_page.dart';
import 'package:eat/features/profile/growth_page.dart';
import 'package:eat/features/profile/history_page.dart';
import 'package:eat/features/profile/me_page.dart';
import 'package:eat/features/profile/my_tags_page.dart';
import 'package:eat/features/profile/profile_providers.dart';
import 'package:eat/features/profile/tag_dishes_page.dart';
import 'package:eat/features/profile/user_page.dart';
import 'package:eat/features/publish/add_dish_page.dart';
import 'package:eat/features/publish/new_shop_page.dart';
import 'package:eat/features/publish/publish_page.dart';
import 'package:eat/features/search/search_page.dart';
import 'package:eat/features/settings/about_page.dart';
import 'package:eat/features/settings/open_source_page.dart';
import 'package:eat/features/shop/shop_edit_page.dart';
import 'package:eat/features/shop/shop_history_page.dart';
import 'package:eat/features/shop/shop_page.dart';
import 'package:eat/features/settings/account_page.dart';
import 'package:eat/features/settings/blocked_page.dart';
import 'package:eat/features/settings/delete_account_page.dart';
import 'package:eat/features/settings/devices_page.dart';
import 'package:eat/features/settings/feedback_page.dart';
import 'package:eat/features/settings/my_feedback_page.dart';
import 'package:eat/features/settings/notify_page.dart';
import 'package:eat/features/settings/password_page.dart';
import 'package:eat/features/settings/personalize_page.dart';
import 'package:eat/features/settings/phone_page.dart';
import 'package:eat/features/settings/preferences_page.dart';
import 'package:eat/features/settings/privacy_page.dart';
import 'package:eat/features/settings/settings_page.dart';
import 'package:eat/features/settings/username_page.dart';
import 'package:eat/features/system/blocking_pages.dart';
import 'package:eat/features/system/not_found_page.dart';
import 'package:eat/features/topic/topic_archive_page.dart';
import 'package:eat/features/topic/topic_page.dart';
import 'package:eat/features/verify/verify_email_page.dart';
import 'package:eat/features/verify/verify_page.dart';
import 'package:eat/router/deep_links.dart';
import 'package:eat/router/guard.dart';
import 'package:eat/router/main_shell.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/remote_config.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 应用路由配置.
///
/// - 三个主页面是 `StatefulShellRoute` 的三个分支, 切换分支时保留各自页面状态, 导航栏悬浮在页面上方.
/// - 其余页面挂载于根导航器之上并覆盖导航栏, 详情页和流程页不显示导航.
/// - 页面的访问权限标记在 `metadata` 上: 公开页面使用 [publicRoute], 游客可访问页面使用 [guestRoute],
///   其余默认仅限登录用户. 守卫 [resolveRedirect] 会将无权访问的请求重定向至登录页.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // push 打开的页面也写入 Web 地址栏, 使地址栏始终对应当前页面, 刷新或复制链接都回到同一页.
  // go_router 默认只有 go 会修改地址.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  // 登录态变化时让守卫重新判断当前地址: 登录后离开登录页, 过期或退出后进入登录页.
  final refresh = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => refresh.value = next);
  // 远程配置的强制更新和停服维护变化时同样重新判断: 进入或离开更新页和维护页.
  final gate = ValueNotifier<AppGate>(ref.read(appGateProvider));
  ref.listen(appGateProvider, (_, next) => gate.value = next);
  late final GoRouter router;
  router = GoRouter(
    initialLocation: Paths.discover,
    refreshListenable: Listenable.merge([refresh, gate]),
    observers: [CrashReporter.navigatorObserver()],
    redirect: (context, state) => resolveRedirect(
      location: state.uri,
      access: RouteAccess.of(state.metadata),
      session: ref.read(sessionProvider),
      canMatch: (uri) => router.configuration.findMatch(uri).isNotEmpty,
      forceUpdate: gate.value.forceUpdate,
      down: gate.value.down,
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
                metadata: guestRoute,
                builder: (_, _) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.nearby,
                metadata: guestRoute,
                builder: (_, _) => const NearbyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.me,
                metadata: guestRoute,
                builder: (_, _) => const MePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Paths.login,
        metadata: publicRoute,
        builder: (_, state) => LoginPage(
          query: _loginQuery(state),
          browseTarget: browseTarget(
            state.uri.queryParameters['from'],
            (uri) => _accessOf(router.configuration.findMatch(uri)),
          ),
        ),
        routes: [
          GoRoute(
            path: _child(Paths.loginPhone, Paths.login),
            builder: (_, state) => PhoneLoginPage(
              query: _loginQuery(state),
              revoking: state.uri.queryParameters['revoke'] == '1',
            ),
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
          sso: DeepLinks.ssoResultOf(state.uri.queryParameters),
        ),
      ),
      // 认证邮件中的验证链接. 该路由不作为认证页的子路由, 否则返回时会先退回认证页并触发页面刷新.
      GoRoute(
        path: Paths.verifyEmail,
        builder: (_, state) =>
            VerifyEmailPage(token: state.uri.queryParameters['token']),
      ),
      // Web 统一认证的回调地址, 由本路由重定向至认证页地址. 原生端回调由认证会话直接接收, 不经过路由.
      GoRoute(
        path: Paths.ssoCallback,
        redirect: (_, state) =>
            DeepLinks.ssoLocation(state.uri.queryParameters),
      ),
      // 游客访问设置页时仅可见 "个性化" 和 "关于". 由于子路由会继承父路由权限, 仅限登录用户的子页面需显式覆盖为 [signedInRoute].
      GoRoute(
        path: Paths.settings,
        metadata: guestRoute,
        builder: (_, _) => const SettingsPage(),
        routes: [
          GoRoute(
            path: _child(Paths.settingsAccount, Paths.settings),
            metadata: signedInRoute,
            builder: (_, _) => const AccountPage(),
            routes: [
              GoRoute(
                path: _child(Paths.settingsUsername, Paths.settingsAccount),
                builder: (_, _) => const UsernamePage(),
              ),
              GoRoute(
                path: _child(Paths.settingsPassword, Paths.settingsAccount),
                builder: (_, _) => const PasswordPage(),
              ),
              GoRoute(
                path: _child(Paths.settingsPhone, Paths.settingsAccount),
                builder: (_, _) => const PhonePage(),
              ),
              GoRoute(
                path: _child(Paths.settingsDevices, Paths.settingsAccount),
                builder: (_, _) => const DevicesPage(),
              ),
              GoRoute(
                path: _child(Paths.settingsDelete, Paths.settingsAccount),
                builder: (_, _) => const DeleteAccountPage(),
              ),
            ],
          ),
          GoRoute(
            path: _child(Paths.settingsPrivacy, Paths.settings),
            metadata: signedInRoute,
            builder: (_, _) => const PrivacyPage(),
            routes: [
              GoRoute(
                path: _child(Paths.settingsBlocked, Paths.settingsPrivacy),
                builder: (_, _) => const BlockedPage(),
              ),
              GoRoute(
                path: _child(Paths.settingsPreferences, Paths.settingsPrivacy),
                builder: (_, _) => const PreferencesPage(),
              ),
            ],
          ),
          GoRoute(
            path: _child(Paths.settingsNotify, Paths.settings),
            metadata: signedInRoute,
            builder: (_, _) => const NotifyPage(),
          ),
          GoRoute(
            path: _child(Paths.settingsPersonalize, Paths.settings),
            builder: (_, _) => const PersonalizePage(),
          ),
          GoRoute(
            path: _child(Paths.settingsAbout, Paths.settings),
            builder: (_, _) => const AboutPage(),
            routes: [
              GoRoute(
                path: _child(Paths.team, Paths.settingsAbout),
                builder: (_, _) => const TeamPage(),
              ),
              GoRoute(
                path: _child(Paths.licenses, Paths.settingsAbout),
                builder: (_, _) => const OpenSourcePage(),
                routes: [
                  GoRoute(
                    path: _child(Paths.licensePattern, Paths.licenses),
                    builder: (_, state) => LicenseTextPage(
                      name: state.pathParameters['name'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: _child(Paths.myFeedback, Paths.settingsAbout),
                metadata: signedInRoute,
                builder: (_, _) => const MyFeedbackPage(),
                routes: [
                  GoRoute(
                    path: _child(Paths.myFeedbackCasePattern, Paths.myFeedback),
                    builder: (_, state) => switch (_idOf(state, 'caseId')) {
                      final id? => FeedbackCasePage(caseId: id),
                      null => const NotFoundPage(),
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Paths.feedbackPattern,
        builder: (_, state) => FeedbackPage(
          dishId: int.tryParse(state.uri.queryParameters['dishId'] ?? ''),
          shopId: int.tryParse(state.uri.queryParameters['shopId'] ?? ''),
        ),
      ),
      // "我的" 的子页面覆盖导航, 因此放在根导航器上, 不放进 "我的" 分支.
      GoRoute(path: Paths.meEdit, builder: (_, _) => const EditProfilePage()),
      GoRoute(
        path: Paths.myTags,
        builder: (_, _) => const MyTagsPage(),
        routes: [
          GoRoute(
            path: _child(Paths.myTagPattern, Paths.myTags),
            builder: (_, state) => switch (_idOf(state, 'tagId')) {
              final id? => TagDishesPage(
                tagId: id,
                name: state.uri.queryParameters['name'] ?? '',
              ),
              null => const NotFoundPage(),
            },
          ),
        ],
      ),
      GoRoute(path: Paths.history, builder: (_, _) => const HistoryPage()),
      GoRoute(path: Paths.growth, builder: (_, _) => const GrowthPage()),
      GoRoute(
        path: Paths.userPattern,
        builder: (_, state) => switch (_idOf(state, 'userId')) {
          final id? => UserPage(userId: id),
          null => const NotFoundPage(),
        },
        routes: [
          GoRoute(
            path: _child(Paths.followsPattern, Paths.userPattern),
            builder: (_, state) => switch (_idOf(state, 'userId')) {
              final id? => FollowsPage(
                userId: id,
                initial: state.uri.queryParameters['tab'] == 'followings'
                    ? FollowListKind.followings
                    : FollowListKind.fans,
              ),
              null => const NotFoundPage(),
            },
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
      GoRoute(
        path: Paths.search,
        metadata: guestRoute,
        builder: (_, _) => const SearchPage(),
      ),
      GoRoute(path: Paths.inbox, builder: (_, _) => const InboxPage()),
      // 专题页不作为往期专题的子路由, 否则从菜品详情或消息进入时会多压入一层往期专题页, 导致返回路径多出一级.
      GoRoute(
        path: Paths.topics,
        metadata: guestRoute,
        builder: (_, _) => const TopicArchivePage(),
      ),
      GoRoute(
        path: Paths.topicPattern,
        metadata: guestRoute,
        builder: (_, state) => switch (_idOf(state, 'topicId')) {
          final id? => TopicPage(topicId: id),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.dishPattern,
        metadata: guestRoute,
        builder: (_, state) => switch (_idOf(state, 'dishId')) {
          final id? => DishPage(
            dishId: id,
            initial: state.extra is Dish ? state.extra! as Dish : null,
            focusComment: int.tryParse(
              state.uri.queryParameters['comment'] ?? '',
            ),
          ),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.commentsPattern,
        metadata: guestRoute,
        builder: (_, state) => switch (_idOf(state, 'dishId')) {
          final id? => CommentsPage(dishId: id),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.dishHistoryPattern,
        metadata: guestRoute,
        builder: (_, state) => switch (_idOf(state, 'dishId')) {
          final id? => DishHistoryPage(dishId: id),
          null => const NotFoundPage(),
        },
      ),
      // 编辑页复用加菜页. 详情页跳转时 extra 带上菜品, 刷新后 extra 丢失, 由页面按 id 读取.
      GoRoute(
        path: Paths.dishEditPattern,
        builder: (_, state) => switch (_idOf(state, 'dishId')) {
          final id? => AddDishPage.edit(
            dishId: id,
            initial: state.extra is Dish ? state.extra! as Dish : null,
          ),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.shopPattern,
        metadata: guestRoute,
        builder: (_, state) => switch (_idOf(state, 'shopId')) {
          final id? => ShopPage(shopId: id),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.shopEditPattern,
        builder: (_, state) => switch (_idOf(state, 'shopId')) {
          final id? => ShopEditPage(shopId: id),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.shopHistoryPattern,
        metadata: guestRoute,
        builder: (_, state) => switch (_idOf(state, 'shopId')) {
          final id? => ShopHistoryPage(shopId: id),
          null => const NotFoundPage(),
        },
      ),
      GoRoute(
        path: Paths.update,
        metadata: publicRoute,
        builder: (_, _) => const ForceUpdatePage(),
      ),
      GoRoute(
        path: Paths.maintenance,
        metadata: publicRoute,
        builder: (_, _) => const MaintenancePage(),
      ),
      if (kDebugMode)
        GoRoute(path: Paths.kit, builder: (_, _) => const KitPage()),
    ],
  );
  final links = DeepLinkHandler(router)
    ..listen(ref.read(linkSourceProvider).links);
  ref.onDispose(() {
    links.dispose();
    router.dispose();
    refresh.dispose();
    gate.dispose();
  });
  return router;
}

/// 解析匹配结果中页面的访问权限. 子路由继承父路由权限, 若子路由自身已显式声明则以其为准.
///
/// 若地址无法匹配路由表则返回 null.
RouteAccess? _accessOf(RouteMatchList match) {
  if (match.isEmpty || match.isError) return null;
  var metadata = <String, dynamic>{};
  void visit(List<RouteMatchBase> matches) {
    for (final m in matches) {
      metadata = {...metadata, ...?m.route.metadata};
      if (m is ShellRouteMatch) visit(m.matches);
    }
  }

  visit(match.matches);
  return RouteAccess.of(metadata);
}

/// 提取相对父路由的子路径, 例如将 `/login` 下的 `/login/phone` 转为 `phone`.
String _child(String path, String parent) => path.substring(parent.length + 1);

/// 解析路径参数中的数字 id. 若参数非有效数字 (如手动拼写的链接) 则返回 null, 由路由渲染 "页面不存在".
int? _idOf(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');

/// 提取登录流程各页面间需透传的查询参数.
Map<String, String> _loginQuery(GoRouterState state) => {
  for (final key in const ['from', 'expired'])
    key: ?state.uri.queryParameters[key],
};
