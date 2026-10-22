import 'package:eat/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 启动应用：先准备好首帧要用的本地数据，再挂上界面。首帧不等网络。
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const ProviderScope(child: EatApp()));
}

/// 内置字体的 OFL 许可证。OFL 要求随字体分发许可证，登记后出现在系统的许可证页里。
Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'Noto Sans SC': 'assets/fonts/OFL-NotoSansSC.txt',
    'Bricolage Grotesque': 'assets/fonts/OFL-BricolageGrotesque.txt',
  };
  for (final MapEntry(key: font, value: path) in fonts.entries) {
    yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(path));
  }
}
