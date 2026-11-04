import 'package:eat/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('不传配置文件时环境是 dev，其余各项为空', () {
    const config = AppConfig.fromEnvironment();

    expect(config.envName, 'dev');
    expect(config.apiBaseUrl, isEmpty);
    expect(config.webBaseUrl, isEmpty);
  });
}
