import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// 编译期通过 `--dart-define-from-file=config/<环境>.json` 传入的环境配置。
///
/// 这些值会编进安装包，只能放公开的值。没传的项是空串，`fvm flutter run`
/// 不带配置文件也能启动，只是调不了接口。
class const AppConfig({
  required final String envName,
  required final String apiBaseUrl,
  required final String webBaseUrl,
  required final String assetBaseUrl,
  required final String sentryDsn,
  required final String tiandituKey,
  required final String privacyUrl,
  required final String termsUrl,
}) {
  const AppConfig.fromEnvironment()
    : this(
        envName: const String.fromEnvironment('ENV_NAME', defaultValue: 'dev'),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        webBaseUrl: const String.fromEnvironment('WEB_BASE_URL'),
        assetBaseUrl: const String.fromEnvironment('ASSET_BASE_URL'),
        sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
        tiandituKey: const String.fromEnvironment('TIANDITU_KEY'),
        privacyUrl: const String.fromEnvironment('PRIVACY_URL'),
        termsUrl: const String.fromEnvironment('TERMS_URL'),
      );
}

/// 当前构建的环境配置，测试里用 `overrideWithValue` 换掉。
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => const AppConfig.fromEnvironment();
