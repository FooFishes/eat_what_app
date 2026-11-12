// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsentPolicyDto _$ConsentPolicyDtoFromJson(Map<String, dynamic> json) =>
    ConsentPolicyDto(version: json['version'] as String?);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(consentApi)
final consentApiProvider = ConsentApiProvider._();

final class ConsentApiProvider
    extends $FunctionalProvider<ConsentApi, ConsentApi, ConsentApi>
    with $Provider<ConsentApi> {
  ConsentApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentApiHash();

  @$internal
  @override
  $ProviderElement<ConsentApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConsentApi create(Ref ref) {
    return consentApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsentApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsentApi>(value),
    );
  }
}

String _$consentApiHash() => r'c50806fcb41dfa0d9be5c095a923ccf94a162013';
