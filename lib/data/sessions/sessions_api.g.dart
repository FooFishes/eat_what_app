// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceSessionPageDto _$DeviceSessionPageDtoFromJson(
  Map<String, dynamic> json,
) => DeviceSessionPageDto(
  devices: (json['devices'] as List<dynamic>?)
      ?.map((e) => DeviceSessionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

DeviceSessionDto _$DeviceSessionDtoFromJson(Map<String, dynamic> json) =>
    DeviceSessionDto(
      sessionId: json['sessionId'] as String?,
      device: json['device'] as String?,
      issuedAt: json['issuedAt'] as String?,
      lastSeenAt: json['lastSeenAt'] as String?,
      current: json['current'] as bool?,
    );

SessionOutcomeDto _$SessionOutcomeDtoFromJson(Map<String, dynamic> json) =>
    SessionOutcomeDto(
      status: json['status'] as String?,
      tokenName: json['tokenName'] as String?,
      tokenValue: json['tokenValue'] as String?,
      restricted: json['restricted'] as bool?,
    );

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionsApi)
final sessionsApiProvider = SessionsApiProvider._();

final class SessionsApiProvider
    extends $FunctionalProvider<SessionsApi, SessionsApi, SessionsApi>
    with $Provider<SessionsApi> {
  SessionsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionsApiHash();

  @$internal
  @override
  $ProviderElement<SessionsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionsApi create(Ref ref) {
    return sessionsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionsApi>(value),
    );
  }
}

String _$sessionsApiHash() => r'01aa7df2e0b892331b60b45dad2daf8d7ca60ede';
