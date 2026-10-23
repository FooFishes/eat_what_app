// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 路由表。
///
/// 三个主页面是 `StatefulShellRoute` 的三个分支，切换时各自的页面状态留着，导航悬浮在上面；
/// 其余页面都放在根导航器上，盖住导航（详情和流程页不显示导航）。

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// 路由表。
///
/// 三个主页面是 `StatefulShellRoute` 的三个分支，切换时各自的页面状态留着，导航悬浮在上面；
/// 其余页面都放在根导航器上，盖住导航（详情和流程页不显示导航）。

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// 路由表。
  ///
  /// 三个主页面是 `StatefulShellRoute` 的三个分支，切换时各自的页面状态留着，导航悬浮在上面；
  /// 其余页面都放在根导航器上，盖住导航（详情和流程页不显示导航）。
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'bfc562e139f598403ce0348726046b9c2822091f';
