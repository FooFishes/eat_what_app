// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancellationStatusDto _$CancellationStatusDtoFromJson(
  Map<String, dynamic> json,
) => CancellationStatusDto(
  requestId: json['requestId'] as String?,
  phase: json['phase'] as String?,
  deadline: json['deadline'] as String?,
  complete: json['complete'] as bool?,
);

RecoveryGrantDto _$RecoveryGrantDtoFromJson(Map<String, dynamic> json) =>
    RecoveryGrantDto(operationId: json['operationId'] as String?);

RecoveryChallengeDto _$RecoveryChallengeDtoFromJson(
  Map<String, dynamic> json,
) => RecoveryChallengeDto(expiresAt: json['expiresAt'] as String?);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cancellationApi)
final cancellationApiProvider = CancellationApiProvider._();

final class CancellationApiProvider
    extends
        $FunctionalProvider<CancellationApi, CancellationApi, CancellationApi>
    with $Provider<CancellationApi> {
  CancellationApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cancellationApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cancellationApiHash();

  @$internal
  @override
  $ProviderElement<CancellationApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CancellationApi create(Ref ref) {
    return cancellationApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CancellationApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CancellationApi>(value),
    );
  }
}

String _$cancellationApiHash() => r'f6699d474ebc209408780c08be87a5000dd11d56';
