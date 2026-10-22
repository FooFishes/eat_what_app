import 'package:eat/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('不传配置文件时环境是 dev，其余各项为空', () {
    const config = AppConfig.fromEnvironment();

    expect(config.envName, 'dev');
    expect(config.apiBaseUrl, isEmpty);
    expect(config.webBaseUrl, isEmpty);
  });

  test('appConfigProvider 可以在测试里换掉', () {
    const fake = AppConfig(
      envName: 'staging',
      apiBaseUrl: 'https://example.com/api',
      webBaseUrl: 'https://example.com',
      assetBaseUrl: '',
      sentryDsn: '',
      tiandituKey: '',
      captchaAppId: '',
    );
    final container = ProviderContainer.test(
      overrides: [appConfigProvider.overrideWithValue(fake)],
    );

    expect(container.read(appConfigProvider).envName, 'staging');
  });
}
