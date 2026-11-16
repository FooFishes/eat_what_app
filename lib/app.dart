import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/features/system/consent_dialog.dart';
import 'package:eat/features/system/notices.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/router/page_analytics.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 应用根组件. 固定浅色主题和中文界面, 并限制系统字号的最大缩放倍数.
class EatApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final pages = ref.watch(pageAnalyticsProvider);
    return MaterialApp.router(
      title: '沙软今天吃什么',
      debugShowCheckedModeBanner: false,
      theme: eatThemeData(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // 页面不使用 Material 的 Scaffold, 因此在此提供默认文字样式.
      // 缺少默认样式时, 未指定样式的文字会显示为 Flutter 的缺省样式 (红字加黄色下划线).
      builder: (context, child) {
        final eat = context.eat;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2,
          child: DefaultTextStyle(
            style: eat.text.body.copyWith(color: eat.colors.ink),
            child: ConsentHost(
              navigatorKey: router.routerDelegate.navigatorKey,
              child: RemoteConfigHost(
                navigatorKey: router.routerDelegate.navigatorKey,
                openPath: (location) => router.push(location),
                child: BackFallback(
                  fallback: () => router.go(Paths.discover),
                  child: LoadFailureObserver(
                    onShown: pages.loadFailed,
                    child: child!,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
