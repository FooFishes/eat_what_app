// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appearance.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 底部导航液态玻璃的透明度, 0 为不透明, 1 为完全透明. 在设置 → 个性化中调整.
///
/// 属于设备级偏好, 游客也能调整, 退出登录时不清除.

@ProviderFor(NavGlassTransparency)
final navGlassTransparencyProvider = NavGlassTransparencyProvider._();

/// 底部导航液态玻璃的透明度, 0 为不透明, 1 为完全透明. 在设置 → 个性化中调整.
///
/// 属于设备级偏好, 游客也能调整, 退出登录时不清除.
final class NavGlassTransparencyProvider
    extends $NotifierProvider<NavGlassTransparency, double> {
  /// 底部导航液态玻璃的透明度, 0 为不透明, 1 为完全透明. 在设置 → 个性化中调整.
  ///
  /// 属于设备级偏好, 游客也能调整, 退出登录时不清除.
  NavGlassTransparencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navGlassTransparencyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navGlassTransparencyHash();

  @$internal
  @override
  NavGlassTransparency create() => NavGlassTransparency();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$navGlassTransparencyHash() =>
    r'c7e643eb4681e7b447583233f47094f7963c9142';

/// 底部导航液态玻璃的透明度, 0 为不透明, 1 为完全透明. 在设置 → 个性化中调整.
///
/// 属于设备级偏好, 游客也能调整, 退出登录时不清除.

abstract class _$NavGlassTransparency extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 界面深浅色: 跟随系统, 或固定浅色, 深色. 默认跟随系统.
///
/// 和 [NavGlassTransparency] 一样是设备级偏好, 游客也能切换, 退出登录时不清除.
/// 启动时在首帧前调用 [restore] 读出, 避免先按系统深浅画一帧再跳.

@ProviderFor(AppearancePreference)
final appearancePreferenceProvider = AppearancePreferenceProvider._();

/// 界面深浅色: 跟随系统, 或固定浅色, 深色. 默认跟随系统.
///
/// 和 [NavGlassTransparency] 一样是设备级偏好, 游客也能切换, 退出登录时不清除.
/// 启动时在首帧前调用 [restore] 读出, 避免先按系统深浅画一帧再跳.
final class AppearancePreferenceProvider
    extends $NotifierProvider<AppearancePreference, Appearance> {
  /// 界面深浅色: 跟随系统, 或固定浅色, 深色. 默认跟随系统.
  ///
  /// 和 [NavGlassTransparency] 一样是设备级偏好, 游客也能切换, 退出登录时不清除.
  /// 启动时在首帧前调用 [restore] 读出, 避免先按系统深浅画一帧再跳.
  AppearancePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appearancePreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appearancePreferenceHash();

  @$internal
  @override
  AppearancePreference create() => AppearancePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Appearance value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Appearance>(value),
    );
  }
}

String _$appearancePreferenceHash() =>
    r'00c9a5833c16de3106c02e4e809bd3fbeb528865';

/// 界面深浅色: 跟随系统, 或固定浅色, 深色. 默认跟随系统.
///
/// 和 [NavGlassTransparency] 一样是设备级偏好, 游客也能切换, 退出登录时不清除.
/// 启动时在首帧前调用 [restore] 读出, 避免先按系统深浅画一帧再跳.

abstract class _$AppearancePreference extends $Notifier<Appearance> {
  Appearance build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Appearance, Appearance>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Appearance, Appearance>,
              Appearance,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
