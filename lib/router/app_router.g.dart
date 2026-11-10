// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 路由表.
///
/// - 三个主页面是 `StatefulShellRoute` 的三个分支. 切换分支时各自的页面状态保留, 导航悬浮在页面上方.
/// - 其余页面放在根导航器上, 覆盖导航. 详情页和流程页不显示导航.
/// - 页面的开放程度标在 `metadata` 上: 谁都能进的标 [publicRoute], 游客能进的标 [guestRoute], 其余不标.
///   守卫 [resolveRedirect] 把进不去的人导向登录页.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// 路由表.
///
/// - 三个主页面是 `StatefulShellRoute` 的三个分支. 切换分支时各自的页面状态保留, 导航悬浮在页面上方.
/// - 其余页面放在根导航器上, 覆盖导航. 详情页和流程页不显示导航.
/// - 页面的开放程度标在 `metadata` 上: 谁都能进的标 [publicRoute], 游客能进的标 [guestRoute], 其余不标.
///   守卫 [resolveRedirect] 把进不去的人导向登录页.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// 路由表.
  ///
  /// - 三个主页面是 `StatefulShellRoute` 的三个分支. 切换分支时各自的页面状态保留, 导航悬浮在页面上方.
  /// - 其余页面放在根导航器上, 覆盖导航. 详情页和流程页不显示导航.
  /// - 页面的开放程度标在 `metadata` 上: 谁都能进的标 [publicRoute], 游客能进的标 [guestRoute], 其余不标.
  ///   守卫 [resolveRedirect] 把进不去的人导向登录页.
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

String _$appRouterHash() => r'e7a7e6ca533a0f03d811253e3bba498767af14ca';
