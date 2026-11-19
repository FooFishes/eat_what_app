// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用路由配置.
///
/// - 三个主页面是 `StatefulShellRoute` 的三个分支, 切换分支时保留各自页面状态, 导航栏悬浮在页面上方.
/// - 其余页面挂载于根导航器之上并覆盖导航栏, 详情页和流程页不显示导航.
/// - 页面的访问权限标记在 `metadata` 上: 公开页面使用 [publicRoute], 游客可访问页面使用 [guestRoute],
///   其余默认仅限登录用户. 守卫 [resolveRedirect] 会将无权访问的请求重定向至登录页.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// 应用路由配置.
///
/// - 三个主页面是 `StatefulShellRoute` 的三个分支, 切换分支时保留各自页面状态, 导航栏悬浮在页面上方.
/// - 其余页面挂载于根导航器之上并覆盖导航栏, 详情页和流程页不显示导航.
/// - 页面的访问权限标记在 `metadata` 上: 公开页面使用 [publicRoute], 游客可访问页面使用 [guestRoute],
///   其余默认仅限登录用户. 守卫 [resolveRedirect] 会将无权访问的请求重定向至登录页.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// 应用路由配置.
  ///
  /// - 三个主页面是 `StatefulShellRoute` 的三个分支, 切换分支时保留各自页面状态, 导航栏悬浮在页面上方.
  /// - 其余页面挂载于根导航器之上并覆盖导航栏, 详情页和流程页不显示导航.
  /// - 页面的访问权限标记在 `metadata` 上: 公开页面使用 [publicRoute], 游客可访问页面使用 [guestRoute],
  ///   其余默认仅限登录用户. 守卫 [resolveRedirect] 会将无权访问的请求重定向至登录页.
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

String _$appRouterHash() => r'27d07a663d483a3ebd95706ccbff8429566c4a59';
