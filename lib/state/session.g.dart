// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 登录态. 路由守卫根据它决定跳转.
///
/// 启动时恢复. 登录, "先逛逛", 退出, 过期和刷新用户信息时更新.

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// 登录态. 路由守卫根据它决定跳转.
///
/// 启动时恢复. 登录, "先逛逛", 退出, 过期和刷新用户信息时更新.
final class SessionProvider extends $NotifierProvider<Session, SessionState> {
  /// 登录态. 路由守卫根据它决定跳转.
  ///
  /// 启动时恢复. 登录, "先逛逛", 退出, 过期和刷新用户信息时更新.
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

String _$sessionHash() => r'ca004eb5d00340f2e85735a644e29e74f2a8e0b4';

/// 登录态. 路由守卫根据它决定跳转.
///
/// 启动时恢复. 登录, "先逛逛", 退出, 过期和刷新用户信息时更新.

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

/// 当前账号状态, 由登录态派生. 决定哪些操作需要拦截.
///
/// 游客也是未登录. 游客能进哪些页面由路由的标记决定, 这里不区分.

@ProviderFor(accountStatus)
final accountStatusProvider = AccountStatusProvider._();

/// 当前账号状态, 由登录态派生. 决定哪些操作需要拦截.
///
/// 游客也是未登录. 游客能进哪些页面由路由的标记决定, 这里不区分.

final class AccountStatusProvider
    extends $FunctionalProvider<AccountStatus, AccountStatus, AccountStatus>
    with $Provider<AccountStatus> {
  /// 当前账号状态, 由登录态派生. 决定哪些操作需要拦截.
  ///
  /// 游客也是未登录. 游客能进哪些页面由路由的标记决定, 这里不区分.
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
