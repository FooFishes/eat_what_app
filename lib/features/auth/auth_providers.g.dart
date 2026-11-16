// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 登录页的协议勾选状态.
///
/// 勾选即同时同意隐私政策, 用户协议和个人信息出境说明, 手机号登录和密码登录均要求先勾选.
/// 登录请求会携带服务端当前的政策版本, 登录成功后将同意记录写入本机.

@ProviderFor(LoginAgreement)
final loginAgreementProvider = LoginAgreementProvider._();

/// 登录页的协议勾选状态.
///
/// 勾选即同时同意隐私政策, 用户协议和个人信息出境说明, 手机号登录和密码登录均要求先勾选.
/// 登录请求会携带服务端当前的政策版本, 登录成功后将同意记录写入本机.
final class LoginAgreementProvider
    extends $NotifierProvider<LoginAgreement, bool> {
  /// 登录页的协议勾选状态.
  ///
  /// 勾选即同时同意隐私政策, 用户协议和个人信息出境说明, 手机号登录和密码登录均要求先勾选.
  /// 登录请求会携带服务端当前的政策版本, 登录成功后将同意记录写入本机.
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
/// 勾选即同时同意隐私政策, 用户协议和个人信息出境说明, 手机号登录和密码登录均要求先勾选.
/// 登录请求会携带服务端当前的政策版本, 登录成功后将同意记录写入本机.

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

String _$phoneLoginHash() => r'90ea0b5f51f56719eed05d715732d274ae484126';

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

String _$passwordLoginHash() => r'2e6796709d4472308e5599bb1a9dacd50e247865';

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

/// 运营商一键登录状态管理, 布尔状态表示登录流程是否正在进行, 登录页按钮据此显示加载状态.
///
/// 用户勾选协议后才在后台执行准备: 先向服务端查询开关状态, 再初始化号码认证 SDK 并预取号.
/// 由于 SDK 会联网并读取网络与 SIM 卡状态, 未勾选协议前不调用该 SDK.
///
/// 若一键登录不可用 (如 Web 端, 无 SIM 卡, 未开启蜂窝网络, 服务端未开启或获取凭证失败), 则不作错误提示, 直接转为验证码登录.

@ProviderFor(OneClickLogin)
final oneClickLoginProvider = OneClickLoginProvider._();

/// 运营商一键登录状态管理, 布尔状态表示登录流程是否正在进行, 登录页按钮据此显示加载状态.
///
/// 用户勾选协议后才在后台执行准备: 先向服务端查询开关状态, 再初始化号码认证 SDK 并预取号.
/// 由于 SDK 会联网并读取网络与 SIM 卡状态, 未勾选协议前不调用该 SDK.
///
/// 若一键登录不可用 (如 Web 端, 无 SIM 卡, 未开启蜂窝网络, 服务端未开启或获取凭证失败), 则不作错误提示, 直接转为验证码登录.
final class OneClickLoginProvider
    extends $NotifierProvider<OneClickLogin, bool> {
  /// 运营商一键登录状态管理, 布尔状态表示登录流程是否正在进行, 登录页按钮据此显示加载状态.
  ///
  /// 用户勾选协议后才在后台执行准备: 先向服务端查询开关状态, 再初始化号码认证 SDK 并预取号.
  /// 由于 SDK 会联网并读取网络与 SIM 卡状态, 未勾选协议前不调用该 SDK.
  ///
  /// 若一键登录不可用 (如 Web 端, 无 SIM 卡, 未开启蜂窝网络, 服务端未开启或获取凭证失败), 则不作错误提示, 直接转为验证码登录.
  OneClickLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneClickLoginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneClickLoginHash();

  @$internal
  @override
  OneClickLogin create() => OneClickLogin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$oneClickLoginHash() => r'cc97fc5dc8f18660afd4b87335fa85f21f157fb5';

/// 运营商一键登录状态管理, 布尔状态表示登录流程是否正在进行, 登录页按钮据此显示加载状态.
///
/// 用户勾选协议后才在后台执行准备: 先向服务端查询开关状态, 再初始化号码认证 SDK 并预取号.
/// 由于 SDK 会联网并读取网络与 SIM 卡状态, 未勾选协议前不调用该 SDK.
///
/// 若一键登录不可用 (如 Web 端, 无 SIM 卡, 未开启蜂窝网络, 服务端未开启或获取凭证失败), 则不作错误提示, 直接转为验证码登录.

abstract class _$OneClickLogin extends $Notifier<bool> {
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
