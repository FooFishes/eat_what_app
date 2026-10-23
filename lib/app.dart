import 'package:eat/design/theme/eat_theme.dart';
import 'package:eat/design/widgets/navigation.dart';
import 'package:eat/router/app_router.dart';
import 'package:eat/router/paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 应用根组件：主题固定浅色，中文界面，系统字号最多跟到 2 倍。
class EatApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '沙软今天吃什么',
      theme: eatThemeData(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // 页面不套 Material 的 Scaffold，默认文字样式在这里给；不给的话没写样式的文字会显示成
      // Flutter 的兜底样子（红字加黄色下划线）。
      builder: (context, child) {
        final eat = context.eat;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2,
          child: DefaultTextStyle(
            style: eat.text.body.copyWith(color: eat.colors.ink),
            child: BackFallback(
              fallback: () => router.go(Paths.discover),
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
