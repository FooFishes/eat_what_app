// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(telemetryApi)
final telemetryApiProvider = TelemetryApiProvider._();

final class TelemetryApiProvider
    extends $FunctionalProvider<TelemetryApi, TelemetryApi, TelemetryApi>
    with $Provider<TelemetryApi> {
  TelemetryApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'telemetryApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$telemetryApiHash();

  @$internal
  @override
  $ProviderElement<TelemetryApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TelemetryApi create(Ref ref) {
    return telemetryApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryApi>(value),
    );
  }
}

String _$telemetryApiHash() => r'2cef5b2d21d2099366c97c04ed8935dbb8f579e6';
