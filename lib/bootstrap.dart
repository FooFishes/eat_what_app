import 'package:eat/app.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/state/api_hooks.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 启动应用. 首帧前只读取本地数据, 不等待网络.
///
/// 首帧需要决定显示发现页还是登录页, 因此要等待本地登录态读取完成, 耗时约数十毫秒.
/// 向服务端核对登录态在首帧之后进行.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web 使用路径形式的地址 (/dishes/123) 而非 #/dishes/123, 与分享链接和 App Links 保持一致.
  usePathUrlStrategy();
  LicenseRegistry.addLicense(_fontLicenses);
  final container = ProviderContainer(
    overrides: stateOverrides,
    retry: retryOnNetworkFailure,
  );
  await container.read(sessionProvider.notifier).restore();
  // 崩溃上报要在首帧前启动, 才能收到启动过程中的错误. 本机没有同意记录时不启动.
  await container.read(consentedServicesProvider.notifier).start();
  // 导航的液态玻璃用自定义着色器绘制. 首帧前载入着色器, 避免导航先闪一帧白.
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: LiquidGlassWidgets.wrap(child: const EatApp()),
    ),
  );
}

/// 内置字体的 OFL 许可证. OFL 要求随字体分发许可证, 注册后显示在系统的许可证页中.
Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'Noto Sans SC': 'assets/fonts/OFL-NotoSansSC.txt',
    'Inter': 'assets/fonts/OFL-Inter.txt',
  };
  for (final MapEntry(key: font, value: path) in fonts.entries) {
    yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(path));
  }
}
