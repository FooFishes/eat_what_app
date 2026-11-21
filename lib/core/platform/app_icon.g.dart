// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_icon.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appIcon)
final appIconProvider = AppIconProvider._();

final class AppIconProvider
    extends $FunctionalProvider<AppIcon, AppIcon, AppIcon>
    with $Provider<AppIcon> {
  AppIconProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appIconProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appIconHash();

  @$internal
  @override
  $ProviderElement<AppIcon> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppIcon create(Ref ref) {
    return appIcon(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppIcon value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppIcon>(value),
    );
  }
}

String _$appIconHash() => r'd4e039e3ef4bee1f834e282ba96004b75a964b16';

/// 当前的桌面图标, 个性化页面用. 不支持换图标时为 null.

@ProviderFor(launcherIcon)
final launcherIconProvider = LauncherIconProvider._();

/// 当前的桌面图标, 个性化页面用. 不支持换图标时为 null.

final class LauncherIconProvider
    extends
        $FunctionalProvider<
          AsyncValue<LauncherIcon?>,
          LauncherIcon?,
          FutureOr<LauncherIcon?>
        >
    with $FutureModifier<LauncherIcon?>, $FutureProvider<LauncherIcon?> {
  /// 当前的桌面图标, 个性化页面用. 不支持换图标时为 null.
  LauncherIconProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launcherIconProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launcherIconHash();

  @$internal
  @override
  $FutureProviderElement<LauncherIcon?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LauncherIcon?> create(Ref ref) {
    return launcherIcon(ref);
  }
}

String _$launcherIconHash() => r'37198f9d7f8f3f7ffd4c4376779214f59be6a114';
