// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captcha_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(captchaGate)
final captchaGateProvider = CaptchaGateProvider._();

final class CaptchaGateProvider
    extends $FunctionalProvider<CaptchaGate, CaptchaGate, CaptchaGate>
    with $Provider<CaptchaGate> {
  CaptchaGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captchaGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captchaGateHash();

  @$internal
  @override
  $ProviderElement<CaptchaGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CaptchaGate create(Ref ref) {
    return captchaGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptchaGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptchaGate>(value),
    );
  }
}

String _$captchaGateHash() => r'0b914b78d54cb977edd0c32ec88c5e1e3aadc3cd';
