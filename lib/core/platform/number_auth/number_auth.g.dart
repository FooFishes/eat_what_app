// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'number_auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(numberAuth)
final numberAuthProvider = NumberAuthProvider._();

final class NumberAuthProvider
    extends $FunctionalProvider<NumberAuth, NumberAuth, NumberAuth>
    with $Provider<NumberAuth> {
  NumberAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'numberAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$numberAuthHash();

  @$internal
  @override
  $ProviderElement<NumberAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NumberAuth create(Ref ref) {
    return numberAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NumberAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NumberAuth>(value),
    );
  }
}

String _$numberAuthHash() => r'ecd552a6968ae29c52093d1b53ad08d80058dbe3';
