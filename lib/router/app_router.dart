import 'package:eat_what_app/page/forgot_password_page.dart';
import 'package:eat_what_app/page/home_page.dart';
import 'package:eat_what_app/page/login_page.dart';
import 'package:eat_what_app/page/main_page.dart';
import 'package:eat_what_app/page/map_page.dart';
import 'package:eat_what_app/page/profile_page.dart';
import 'package:eat_what_app/page/restaurant_page.dart';
import 'package:eat_what_app/page/upload_page.dart';
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
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 220),
            child: const ForgotPasswordPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
      StatefulShellRoute(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return MainPage(navigationShell: navigationShell);
            },
        navigatorContainerBuilder:
            (
              BuildContext context,
              StatefulNavigationShell navigationShell,
              List<Widget> children,
            ) {
              return _AnimatedBranchContainer(
                currentIndex: navigationShell.currentIndex,
                children: children,
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomePage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/map',
                builder: (BuildContext context, GoRouterState state) {
                  return const MapPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/upload',
                builder: (BuildContext context, GoRouterState state) {
                  return const UploadPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/restaurant',
                builder: (BuildContext context, GoRouterState state) {
                  return const RestaurantPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) {
                  return const ProfilePage();
                },
              ),
            ],
          ),
        ],
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

  ref.listen<AsyncValue<String?>>(authProvider, (_, _) {
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

class _AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeInOutCubic;

  late final AnimationController _controller;
  late final Animation<double> _inOpacity;
  late final Animation<double> _outOpacity;

  int _previousIndex = 0;
  bool _movingForward = true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1,
    );
    _inOpacity = CurvedAnimation(parent: _controller, curve: _curve);
    _outOpacity = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: _curve));
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _movingForward = widget.currentIndex > oldWidget.currentIndex;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnimating = _controller.isAnimating;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          fit: StackFit.expand,
          children: List<Widget>.generate(widget.children.length, (int index) {
            final bool isCurrent = index == widget.currentIndex;
            final bool isPrevious = index == _previousIndex;
            final bool shouldPaint = isCurrent || (isAnimating && isPrevious);

            if (!shouldPaint) {
              return Offstage(
                offstage: true,
                child: TickerMode(
                  enabled: false,
                  child: widget.children[index],
                ),
              );
            }

            final Animation<double> opacity = isCurrent
                ? _inOpacity
                : _outOpacity;
            final Animation<Offset> offset = isCurrent
                ? Tween<Offset>(
                    begin: Offset(_movingForward ? 1 : -1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: _controller, curve: _curve))
                : Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(_movingForward ? -1 : 1, 0),
                  ).animate(
                    CurvedAnimation(parent: _controller, curve: _curve),
                  );

            return Offstage(
              offstage: false,
              child: TickerMode(
                enabled: isCurrent,
                child: IgnorePointer(
                  ignoring: !isCurrent,
                  child: SlideTransition(
                    position: offset,
                    child: FadeTransition(
                      opacity: opacity,
                      child: widget.children[index],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
