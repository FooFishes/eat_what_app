// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 登录页的协议勾选状态.
///
/// 手机号登录和密码登录都要求先勾选. 登录成功后写入本机的同意记录.

@ProviderFor(LoginAgreement)
final loginAgreementProvider = LoginAgreementProvider._();

/// 登录页的协议勾选状态.
///
/// 手机号登录和密码登录都要求先勾选. 登录成功后写入本机的同意记录.
final class LoginAgreementProvider
    extends $NotifierProvider<LoginAgreement, bool> {
  /// 登录页的协议勾选状态.
  ///
  /// 手机号登录和密码登录都要求先勾选. 登录成功后写入本机的同意记录.
  LoginAgreementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginAgreementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginAgreementHash();

  @$internal
  @override
  LoginAgreement create() => LoginAgreement();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$loginAgreementHash() => r'7cc20187bd7bdd547dd4ef1c5856be844ee14ef8';

/// 登录页的协议勾选状态.
///
/// 手机号登录和密码登录都要求先勾选. 登录成功后写入本机的同意记录.

abstract class _$LoginAgreement extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PhoneLogin)
final phoneLoginProvider = PhoneLoginProvider._();

final class PhoneLoginProvider
    extends $NotifierProvider<PhoneLogin, PhoneLoginState> {
  PhoneLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneLoginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneLoginHash();

  @$internal
  @override
  PhoneLogin create() => PhoneLogin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneLoginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneLoginState>(value),
    );
  }
}

String _$phoneLoginHash() => r'f6c9abe156f22e2bf7932cb46a0c130621b3eac2';

abstract class _$PhoneLogin extends $Notifier<PhoneLoginState> {
  PhoneLoginState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneLoginState, PhoneLoginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PhoneLoginState, PhoneLoginState>,
              PhoneLoginState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PasswordLogin)
final passwordLoginProvider = PasswordLoginProvider._();

final class PasswordLoginProvider
    extends $NotifierProvider<PasswordLogin, PasswordLoginState> {
  PasswordLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordLoginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordLoginHash();

  @$internal
  @override
  PasswordLogin create() => PasswordLogin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordLoginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordLoginState>(value),
    );
  }
}

String _$passwordLoginHash() => r'255ded81971f7f70f06b8f50f521e8dea45de5eb';

abstract class _$PasswordLogin extends $Notifier<PasswordLoginState> {
  PasswordLoginState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PasswordLoginState, PasswordLoginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PasswordLoginState, PasswordLoginState>,
              PasswordLoginState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
