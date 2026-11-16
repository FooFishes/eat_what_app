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
