import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init((options) {
    options.dsn =
        'https://6a149b4959c7a65bc57fb7208653f119@sentry.foofish.work/2';
    // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
    // We recommend adjusting this value in production.
    options.tracesSampleRate = 1.0;
    // The sampling rate for profiling is relative to tracesSampleRate
    // Setting to 1.0 will profile 100% of sampled transactions:
    options.profilesSampleRate = 1.0;
    options.replay.onErrorSampleRate = 1.0;
    options.replay.sessionSampleRate = 1.0;

    // 开启调试模式，查看详细的 SDK 诊断输出
    options.debug = true;
    // 设置诊断级别为最详细
    options.diagnosticLevel = SentryLevel.debug;
    // 捕获所有未处理的异步错误
    options.considerInAppFramesByDefault = true;
  }, appRunner: () => runApp(SentryWidget(child: const MainApp())));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Center(child: Column(children: [Text('Hello World!')])),
        ),
      ),
    );
  }
}
