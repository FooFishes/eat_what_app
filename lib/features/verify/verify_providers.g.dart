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

String _$verifyHash() => r'f7dca5bd39ab61d7858aa9856c17e56831489d83';

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
