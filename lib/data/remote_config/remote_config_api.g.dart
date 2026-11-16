// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlagDto _$FlagDtoFromJson(Map<String, dynamic> json) =>
    FlagDto(on: json['on'] as bool?, reason: json['reason'] as String?);

MaintenanceDto _$MaintenanceDtoFromJson(Map<String, dynamic> json) =>
    MaintenanceDto(
      mode: json['mode'] as String?,
      message: json['message'] as String?,
      until: (json['until'] as num?)?.toInt(),
    );

AnnouncementDto _$AnnouncementDtoFromJson(Map<String, dynamic> json) =>
    AnnouncementDto(
      id: (json['id'] as num).toInt(),
      level: json['level'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      linkUrl: json['linkUrl'] as String?,
      startsAt: (json['startsAt'] as num?)?.toInt(),
      endsAt: (json['endsAt'] as num?)?.toInt(),
    );

VersionDto _$VersionDtoFromJson(Map<String, dynamic> json) => VersionDto(
  minBuild: (json['minBuild'] as num?)?.toInt(),
  latestBuild: (json['latestBuild'] as num?)?.toInt(),
  latestVersionName: json['latestVersionName'] as String?,
  storeUrl: json['storeUrl'] as String?,
  releaseNotes: json['releaseNotes'] as String?,
);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(remoteConfigApi)
final remoteConfigApiProvider = RemoteConfigApiProvider._();

final class RemoteConfigApiProvider
    extends
        $FunctionalProvider<RemoteConfigApi, RemoteConfigApi, RemoteConfigApi>
    with $Provider<RemoteConfigApi> {
  RemoteConfigApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteConfigApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteConfigApiHash();

  @$internal
  @override
  $ProviderElement<RemoteConfigApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RemoteConfigApi create(Ref ref) {
    return remoteConfigApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteConfigApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteConfigApi>(value),
    );
  }
}

String _$remoteConfigApiHash() => r'c497ea27bb115c53de32acc4848d7cff9731940d';
