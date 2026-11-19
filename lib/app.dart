import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/load_states.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/design/widgets/theme_cross_fade.dart';
import 'package:eat/features/system/consent_dialog.dart';
import 'package:eat/features/system/notices.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/router/page_analytics.dart';
import 'package:eat/router/paths.dart';
import 'package:eat/state/appearance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 应用根组件. 主题按个性化里的选择跟随系统或固定深浅色, 界面固定中文, 并限制系统字号的最大缩放倍数.
class EatApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final pages = ref.watch(pageAnalyticsProvider);
    final appearance = ref.watch(appearancePreferenceProvider);
    return MaterialApp.router(
      title: '沙软今天吃什么',
      debugShowCheckedModeBanner: false,
      theme: eatThemeData(),
      darkTheme: eatThemeData(Brightness.dark),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      // 不用 MaterialApp 自带的主题渐变: 它在 200ms 里每帧重建整棵树, 换深浅色时明显卡顿. 过渡改由下面的 [ThemeCrossFade] 用截图淡出.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // 页面不使用 Material 的 Scaffold, 因此在此提供默认文字样式.
      // 缺少默认样式时, 未指定样式的文字会显示为 Flutter 的缺省样式 (红字加黄色下划线).
      builder: (context, child) {
        final eat = context.eat;
        // 整个 App 底下铺一层 `paper`. iOS 26 的键盘是半透明的圆角面板, 页面没画到的地方会透出原生视图的黑底.
        return ThemeCrossFade(
          followsSystem: appearance == Appearance.system,
          child: ColoredBox(
            color: eat.colors.paper,
            child: MediaQuery.withClampedTextScaling(
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
            ),
          ),
        );
      },
    );
  }
}
