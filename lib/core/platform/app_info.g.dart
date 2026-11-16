// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 版本名, 取自 `pubspec.yaml` 的 `version`, 如 `0.1.0`. 显示在设置页和关于页.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// 版本名, 取自 `pubspec.yaml` 的 `version`, 如 `0.1.0`. 显示在设置页和关于页.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 版本名, 取自 `pubspec.yaml` 的 `version`, 如 `0.1.0`. 显示在设置页和关于页.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'59b58cc8214f60571dfe517b1f68cfc1aed29718';

/// 构建号, CI 中取工作流的运行序号. 更新检查基于该值比较, 而非版本名.

@ProviderFor(appBuildNumber)
final appBuildNumberProvider = AppBuildNumberProvider._();

/// 构建号, CI 中取工作流的运行序号. 更新检查基于该值比较, 而非版本名.

final class AppBuildNumberProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 构建号, CI 中取工作流的运行序号. 更新检查基于该值比较, 而非版本名.
  AppBuildNumberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appBuildNumberProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appBuildNumberHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appBuildNumber(ref);
  }
}

String _$appBuildNumberHash() => r'083c693c8eba190410e7b5b4c9a8b7ca71beecc7';
