import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'api/exception/business_exception.dart';


Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://6a149b4959c7a65bc57fb7208653f119@sentry.foofish.work/2';
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
      
      // 添加 beforeSend 回调来调试事件发送
      options.beforeSend = (event, hint) async {
        print('✅ Sentry beforeSend 被调用');
        print('📤 事件 ID: ${event.eventId}');
        print('📋 事件类型: ${event.type}');
        print('🔍 DSN: ${options.dsn}');
        if (event.exceptions != null && event.exceptions!.isNotEmpty) {
          print('⚠️ 异常: ${event.exceptions!.first.type} - ${event.exceptions!.first.value}');
        }
        return event; // 返回 event 继续发送，返回 null 则取消发送
      };
      
      // 捕获所有未处理的异步错误
      options.considerInAppFramesByDefault = true;
    },
    appRunner: () => runApp(SentryWidget(child: const MainApp())),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(child: Scaffold(body: Center(child: Column(children: [
        Text('Hello World!'),
        TextButton(onPressed: () {
          throw BusinessException(code: 400, message: 'This is a sample exception.', uri: 'https://example.com', timestamp: DateTime.now().millisecondsSinceEpoch);
        }, child: Text('Throw Exception'))
      ],))),)
    );
  }
}
