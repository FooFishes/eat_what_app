import 'package:eat_what_app/page/forgot_password_page.dart';
import 'package:eat_what_app/page/home_page.dart';
import 'package:eat_what_app/page/login_page.dart';
import 'package:eat_what_app/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const _SplashPage();
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: const LoginPage(initialIsLoginMode: true),
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: const LoginPage(initialIsLoginMode: false),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordPage();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<String?> authState = ref.read(authProvider);
      final String location = state.matchedLocation;
      final bool isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final bool isSplashRoute = location == '/splash';

      if (authState.isLoading) {
        // Keep auth pages visible during login/register submit so error toast
        // can be shown on the current page instead of jumping to splash.
        if (isSplashRoute || isAuthRoute) {
          return null;
        }
        return '/splash';
      }

      final String? token = authState.value;
      final bool isLoggedIn = token != null && token.isNotEmpty;

      if (!isLoggedIn) {
        if (isAuthRoute) {
          return null;
        }
        return '/login';
      }

      if (isSplashRoute || isAuthRoute) {
        return '/home';
      }

      return null;
    },
  );

  ref.listen<AsyncValue<String?>>(authProvider, (_, __) {
    router.refresh();
  });
  ref.onDispose(router.dispose);

  return router;
});

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
