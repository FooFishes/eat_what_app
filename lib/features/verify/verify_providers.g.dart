// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Verify)
final verifyProvider = VerifyProvider._();

final class VerifyProvider extends $NotifierProvider<Verify, VerifyState> {
  VerifyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyHash();

  @$internal
  @override
  Verify create() => Verify();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyState>(value),
    );
  }
}

String _$verifyHash() => r'9b52746639dae885cce22734340989b2bd06d3c5';

abstract class _$Verify extends $Notifier<VerifyState> {
  VerifyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VerifyState, VerifyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VerifyState, VerifyState>,
              VerifyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 邮箱认证落地页的提交状态, null 表示尚未开始提交.

@ProviderFor(EmailVerification)
final emailVerificationProvider = EmailVerificationProvider._();

/// 邮箱认证落地页的提交状态, null 表示尚未开始提交.
final class EmailVerificationProvider
    extends $NotifierProvider<EmailVerification, AsyncValue<void>?> {
  /// 邮箱认证落地页的提交状态, null 表示尚未开始提交.
  EmailVerificationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emailVerificationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emailVerificationHash();

  @$internal
  @override
  EmailVerification create() => EmailVerification();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>?>(value),
    );
  }
}

String _$emailVerificationHash() => r'96d53ae6fce379870e0b1faa33348bafa1c6864b';

/// 邮箱认证落地页的提交状态, null 表示尚未开始提交.

abstract class _$EmailVerification extends $Notifier<AsyncValue<void>?> {
  AsyncValue<void>? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>?, AsyncValue<void>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>?, AsyncValue<void>?>,
              AsyncValue<void>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
