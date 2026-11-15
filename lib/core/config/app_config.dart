import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// 编译期通过 `--dart-define-from-file=config/<环境>.json` 传入的环境配置.
///
/// 这些值会编入安装包, 只能存放可公开的值.
/// 未传入的项为空串. 不带配置文件也能启动, 但无法调用接口.
class const AppConfig({
  required final String envName,
  required final String apiBaseUrl,
  required final String webBaseUrl,
  required final String sentryDsn,
  required final String baiduMapAkAndroid,
  required final String baiduMapAkIos,
  required final String baiduMapAkWeb,
  required final String privacyUrl,
  required final String termsUrl,
  required final String crossBorderUrl,
}) {
  const AppConfig.fromEnvironment()
    : this(
        envName: const String.fromEnvironment('ENV_NAME', defaultValue: 'dev'),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        webBaseUrl: const String.fromEnvironment('WEB_BASE_URL'),
        sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
        baiduMapAkAndroid: const String.fromEnvironment('BAIDU_MAP_AK_ANDROID'),
        baiduMapAkIos: const String.fromEnvironment('BAIDU_MAP_AK_IOS'),
        baiduMapAkWeb: const String.fromEnvironment('BAIDU_MAP_AK_WEB'),
        privacyUrl: const String.fromEnvironment('PRIVACY_URL'),
        termsUrl: const String.fromEnvironment('TERMS_URL'),
        crossBorderUrl: const String.fromEnvironment('CROSS_BORDER_URL'),
      );
}

/// 当前构建的环境配置. 测试中用 `overrideWithValue` 替换.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => const AppConfig.fromEnvironment();
