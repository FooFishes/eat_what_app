// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'human_verifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(humanVerifier)
final humanVerifierProvider = HumanVerifierProvider._();

final class HumanVerifierProvider
    extends $FunctionalProvider<HumanVerifier, HumanVerifier, HumanVerifier>
    with $Provider<HumanVerifier> {
  HumanVerifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'humanVerifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$humanVerifierHash();

  @$internal
  @override
  $ProviderElement<HumanVerifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HumanVerifier create(Ref ref) {
    return humanVerifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HumanVerifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HumanVerifier>(value),
    );
  }
}

String _$humanVerifierHash() => r'33ed5fe4426836d3e26bde7ad54e7c33ce9bf6cf';
