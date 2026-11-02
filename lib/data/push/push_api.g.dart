// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushSettingDto _$PushSettingDtoFromJson(Map<String, dynamic> json) =>
    PushSettingDto(
      category: json['category'] as String?,
      enabled: json['enabled'] as bool?,
      revision: (json['revision'] as num?)?.toInt(),
      closeFrontier: json['closeFrontier'] as String?,
    );

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pushApi)
final pushApiProvider = PushApiProvider._();

final class PushApiProvider
    extends $FunctionalProvider<PushApi, PushApi, PushApi>
    with $Provider<PushApi> {
  PushApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushApiHash();

  @$internal
  @override
  $ProviderElement<PushApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PushApi create(Ref ref) {
    return pushApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushApi>(value),
    );
  }
}

String _$pushApiHash() => r'e430a59434ab80aed7dc2ac8ada36938f5e85799';
