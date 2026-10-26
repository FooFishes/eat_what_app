// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 登录态：启动时恢复，登录、退出、过期、刷新用户信息时更新。路由守卫跟着它跳转。

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// 登录态：启动时恢复，登录、退出、过期、刷新用户信息时更新。路由守卫跟着它跳转。
final class SessionProvider extends $NotifierProvider<Session, SessionState> {
  /// 登录态：启动时恢复，登录、退出、过期、刷新用户信息时更新。路由守卫跟着它跳转。
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

String _$sessionHash() => r'f20c55811b407ef9a5332e603c3b21783e23806f';

/// 登录态：启动时恢复，登录、退出、过期、刷新用户信息时更新。路由守卫跟着它跳转。

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

/// 当前账号能做什么，由登录态派生（技术架构 8.1）。

@ProviderFor(accountStatus)
final accountStatusProvider = AccountStatusProvider._();

/// 当前账号能做什么，由登录态派生（技术架构 8.1）。

final class AccountStatusProvider
    extends $FunctionalProvider<AccountStatus, AccountStatus, AccountStatus>
    with $Provider<AccountStatus> {
  /// 当前账号能做什么，由登录态派生（技术架构 8.1）。
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

String _$accountStatusHash() => r'1441df1f89aebc7a90ae374c214d18d7e1558445';
