import 'package:eat/app.dart';
import 'package:eat/core/network/api_client.dart';
import 'package:eat/state/analytics.dart';
import 'package:eat/state/api_hooks.dart';
import 'package:eat/state/consented_services.dart';
import 'package:eat/state/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// 启动应用. 首帧前只读取本地数据, 不等待网络.
///
/// 首帧需要决定显示发现页还是登录页, 因此要等待本地登录态读取完成, 耗时约数十毫秒.
/// 向服务端核对登录态在首帧之后进行.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web 使用路径形式的地址 (/dishes/123) 而非 #/dishes/123, 与分享链接和 App Links 保持一致.
  usePathUrlStrategy();
  LicenseRegistry.addLicense(_assetLicenses);
  final container = ProviderContainer(
    overrides: stateOverrides,
    retry: retryOnNetworkFailure,
  );
  await container.read(sessionProvider.notifier).restore();
  // 崩溃上报需在首帧前启动, 才能捕获启动过程中的错误. 若本机尚无同意记录则不启动.
  await container.read(consentedServicesProvider.notifier).start();
  // 记录冷启动, 并在回到前台和退到后台时记录与上报使用统计. 未同意隐私政策时不采集.
  container.read(analyticsProvider).observeLifecycle();
  // 导航的液态玻璃采用自定义着色器绘制. 首帧前预载着色器, 避免导航栏出现白屏闪烁.
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  runApp(
    UncontrolledProviderScope(
      container: container,
      // 液态玻璃默认跟随系统深浅色. 由于应用固定浅色主题, 此处改为读取应用主题亮度, 避免系统开启深色模式时玻璃变暗.
      child: LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: const EatApp(),
      ),
    ),
  );
}

/// 注册内置字体, 图标和 emoji 图片的许可证. OFL, Apache-2.0 和 CC BY 均要求随资源分发协议或署名, 注册后将展示在系统许可证页中.
Stream<LicenseEntry> _assetLicenses() async* {
  const assets = {
    'Inter': 'assets/fonts/OFL-Inter.txt',
    'MingCute': 'assets/LICENSE-MingCute.txt',
    'Twemoji': 'assets/emoji/LICENSE-Twemoji.txt',
  };
  for (final MapEntry(key: name, value: path) in assets.entries) {
    yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path));
  }
}
