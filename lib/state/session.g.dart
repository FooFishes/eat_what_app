// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局登录态管理, 路由守卫据此决定页面跳转.
///
/// 启动时恢复本地凭证, 并在登录, "先逛逛", 退出, 过期和刷新用户信息时更新.

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// 全局登录态管理, 路由守卫据此决定页面跳转.
///
/// 启动时恢复本地凭证, 并在登录, "先逛逛", 退出, 过期和刷新用户信息时更新.
final class SessionProvider extends $NotifierProvider<Session, SessionState> {
  /// 全局登录态管理, 路由守卫据此决定页面跳转.
  ///
  /// 启动时恢复本地凭证, 并在登录, "先逛逛", 退出, 过期和刷新用户信息时更新.
  SessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @$internal
  @override
  Session create() => Session();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionHash() => r'6b36f62c2803375e79dd9efebbb4f642ad4b251f';

/// 全局登录态管理, 路由守卫据此决定页面跳转.
///
/// 启动时恢复本地凭证, 并在登录, "先逛逛", 退出, 过期和刷新用户信息时更新.

abstract class _$Session extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 由当前登录态派生的账号状态, 用于判断哪些业务操作需要权限拦截.
///
/// 游客同样视为未登录状态, 游客可访问的页面范围由路由权限标记控制, 此处不做区分.

@ProviderFor(accountStatus)
final accountStatusProvider = AccountStatusProvider._();

/// 由当前登录态派生的账号状态, 用于判断哪些业务操作需要权限拦截.
///
/// 游客同样视为未登录状态, 游客可访问的页面范围由路由权限标记控制, 此处不做区分.

final class AccountStatusProvider
    extends $FunctionalProvider<AccountStatus, AccountStatus, AccountStatus>
    with $Provider<AccountStatus> {
  /// 由当前登录态派生的账号状态, 用于判断哪些业务操作需要权限拦截.
  ///
  /// 游客同样视为未登录状态, 游客可访问的页面范围由路由权限标记控制, 此处不做区分.
  AccountStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStatusHash();

  @$internal
  @override
  $ProviderElement<AccountStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountStatus create(Ref ref) {
    return accountStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountStatus>(value),
    );
  }
}

String _$accountStatusHash() => r'a18ee3b99f000767e04e8f7c876eefdf08cfb55f';
