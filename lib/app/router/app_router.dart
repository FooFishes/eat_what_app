import 'package:eat_what_app/app/router/route_paths.dart';
import 'package:eat_what_app/app/shell/app_shell_page.dart';
import 'package:eat_what_app/app/shell/widgets/animated_branch_container.dart';
import 'package:eat_what_app/features/auth/presentation/pages/auth_page.dart';
import 'package:eat_what_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:eat_what_app/features/auth/presentation/pages/login_page.dart';
import 'package:eat_what_app/features/auth/presentation/pages/webview_auth_page.dart';
import 'package:eat_what_app/features/auth/presentation/view_models/auth_session_view_model.dart';
import 'package:eat_what_app/features/foodie_map/presentation/pages/foodie_map_page.dart';
import 'package:eat_what_app/features/home/presentation/pages/home_page.dart';
import 'package:eat_what_app/features/map/presentation/pages/map_page.dart';
import 'package:eat_what_app/features/profile/presentation/pages/profile_history_page.dart';
import 'package:eat_what_app/features/profile/presentation/pages/profile_info_page.dart';
import 'package:eat_what_app/features/profile/presentation/pages/profile_page.dart';
import 'package:eat_what_app/features/profile/presentation/pages/profile_tag_library_page.dart';
import 'package:eat_what_app/features/restaurant/presentation/pages/restaurant_detail_page.dart';
import 'package:eat_what_app/features/restaurant/presentation/pages/restaurant_page.dart';
import 'package:eat_what_app/features/upload/presentation/pages/add_food_page.dart';
import 'package:eat_what_app/features/upload/presentation/pages/add_restaurant_page.dart';
import 'package:eat_what_app/features/upload/presentation/pages/upload_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: RoutePaths.webviewAuth,
        builder: (context, state) => const WebviewAuthPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginPage(initialIsLoginMode: true),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginPage(initialIsLoginMode: false),
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 220),
          child: const ForgotPasswordPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: RoutePaths.foodieMap,
        builder: (context, state) => const FoodieMapPage(),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RestaurantDetailPage(restaurantId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.uploadAddRestaurant,
        builder: (context, state) => const AddRestaurantPage(),
      ),
      GoRoute(
        path: '/upload/restaurant/:restaurantId/add-food',
        builder: (context, state) {
          final restaurantId = int.parse(state.pathParameters['restaurantId']!);
          return AddFoodPage(restaurantId: restaurantId);
        },
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return AppShellPage(
            navigationShell: navigationShell,
            currentLocation: state.matchedLocation,
          );
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.map,
                builder: (context, state) => const MapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.upload,
                builder: (context, state) => const UploadPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.restaurant,
                builder: (context, state) => const RestaurantPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfilePage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'info',
                    builder: (context, state) => const ProfileInfoPage(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const ProfileHistoryPage(),
                  ),
                  GoRoute(
                    path: 'tags',
                    builder: (context, state) => const ProfileTagLibraryPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authSessionViewModelProvider);
      final location = state.matchedLocation;
      final isAuthRoute =
          location == RoutePaths.login ||
          location == RoutePaths.register ||
          location == RoutePaths.forgotPassword;
      final isSplashRoute = location == RoutePaths.splash;

      if (authState.isLoading) {
        if (isSplashRoute || isAuthRoute) {
          return null;
        }
        return RoutePaths.splash;
      }

      final token = authState.value;
      final isLoggedIn = token != null && token.isNotEmpty;

      if (!isLoggedIn) {
        if (isAuthRoute) {
          return null;
        }
        return RoutePaths.login;
      }

      if (isSplashRoute || isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },
  );

  ref.listen<AsyncValue<String?>>(authSessionViewModelProvider, (_, _) {
    router.refresh();
  });
  ref.onDispose(router.dispose);

  return router;
}

class _SplashPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
