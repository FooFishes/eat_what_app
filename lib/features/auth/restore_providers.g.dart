// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restore_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 撤销注销: 登录页发现账号正在注销时开始, 撤销注销页验证身份后撤销.
///
/// 跨越登录页和撤销注销页, 因此一直保留. 恢复凭据只放在内存和安全存储里, 不进入地址.

@ProviderFor(AccountRestore)
final accountRestoreProvider = AccountRestoreProvider._();

/// 撤销注销: 登录页发现账号正在注销时开始, 撤销注销页验证身份后撤销.
///
/// 跨越登录页和撤销注销页, 因此一直保留. 恢复凭据只放在内存和安全存储里, 不进入地址.
final class AccountRestoreProvider
    extends $NotifierProvider<AccountRestore, RestoreState> {
  /// 撤销注销: 登录页发现账号正在注销时开始, 撤销注销页验证身份后撤销.
  ///
  /// 跨越登录页和撤销注销页, 因此一直保留. 恢复凭据只放在内存和安全存储里, 不进入地址.
  AccountRestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountRestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountRestoreHash();

  @$internal
  @override
  AccountRestore create() => AccountRestore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreState>(value),
    );
  }
}

String _$accountRestoreHash() => r'1703084bc900bc7661e65c2ff8e161170213594a';

/// 撤销注销: 登录页发现账号正在注销时开始, 撤销注销页验证身份后撤销.
///
/// 跨越登录页和撤销注销页, 因此一直保留. 恢复凭据只放在内存和安全存储里, 不进入地址.

abstract class _$AccountRestore extends $Notifier<RestoreState> {
  RestoreState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RestoreState, RestoreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RestoreState, RestoreState>,
              RestoreState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
