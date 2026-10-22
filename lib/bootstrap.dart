import 'package:eat/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 启动应用：先准备好首帧要用的本地数据，再挂上界面。首帧不等网络。
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EatApp()));
}
