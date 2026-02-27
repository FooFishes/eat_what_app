// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_bar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 导航栏状态管理
/// 用于管理自定义导航栏的索引值和是否显示

@ProviderFor(NavigationBar)
final navigationBarProvider = NavigationBarProvider._();

/// 导航栏状态管理
/// 用于管理自定义导航栏的索引值和是否显示
final class NavigationBarProvider
    extends $NotifierProvider<NavigationBar, NavigationBarState> {
  /// 导航栏状态管理
  /// 用于管理自定义导航栏的索引值和是否显示
  NavigationBarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationBarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationBarHash();

  @$internal
  @override
  NavigationBar create() => NavigationBar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationBarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationBarState>(value),
    );
  }
}

String _$navigationBarHash() => r'b03f0d7878e9901d7f582e66fef5c245922ade84';

/// 导航栏状态管理
/// 用于管理自定义导航栏的索引值和是否显示

abstract class _$NavigationBar extends $Notifier<NavigationBarState> {
  NavigationBarState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NavigationBarState, NavigationBarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NavigationBarState, NavigationBarState>,
              NavigationBarState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
