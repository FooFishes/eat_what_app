import 'package:eat_what_app/core/theme/app_theme.dart';
import 'package:eat_what_app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://0247296817d5b39d78805706e0c88c70@sentry.orbithy.com/3';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      options.replay.onErrorSampleRate = 1.0;
      options.replay.sessionSampleRate = 1.0;

      // 开启调试模式，查看详细的 SDK 诊断输出
      options.debug = false;
      // 设置诊断级别为最详细
      options.diagnosticLevel = SentryLevel.debug;
      // 捕获所有未处理的异步错误
      options.considerInAppFramesByDefault = true;
    },
    appRunner: () =>
        runApp(ProviderScope(child: SentryWidget(child: MainApp()))),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(routerConfig: router, theme: AppTheme.light);
  }
}
