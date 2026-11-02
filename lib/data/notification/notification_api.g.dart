// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoticeCardDto _$NoticeCardDtoFromJson(Map<String, dynamic> json) =>
    NoticeCardDto(
      id: json['id'] as String?,
      column: json['column'] as String?,
      kind: json['kind'] as String?,
      target: json['target'] == null
          ? null
          : NoticeTargetDto.fromJson(json['target'] as Map<String, dynamic>),
      memberCount: (json['memberCount'] as num?)?.toInt(),
      unreadMemberCount: (json['unreadMemberCount'] as num?)?.toInt(),
      latestAt: (json['latestAt'] as num?)?.toInt(),
      actors: (json['actors'] as List<dynamic>?)
          ?.map((e) => NoticeActorDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      data: json['data'] == null
          ? null
          : NoticeDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );

NoticeTargetDto _$NoticeTargetDtoFromJson(Map<String, dynamic> json) =>
    NoticeTargetDto(
      domain: json['domain'] as String?,
      id: (json['id'] as num?)?.toInt(),
      unavailable: json['unavailable'] as bool?,
    );

NoticeActorDto _$NoticeActorDtoFromJson(Map<String, dynamic> json) =>
    NoticeActorDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
    );

NoticeDataDto _$NoticeDataDtoFromJson(Map<String, dynamic> json) =>
    NoticeDataDto(detail: json['detail'] as Map<String, dynamic>?);

UnreadDto _$UnreadDtoFromJson(Map<String, dynamic> json) => UnreadDto(
  cards: (json['cards'] as num?)?.toInt(),
  members: (json['members'] as num?)?.toInt(),
);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationApi)
final notificationApiProvider = NotificationApiProvider._();

final class NotificationApiProvider
    extends
        $FunctionalProvider<NotificationApi, NotificationApi, NotificationApi>
    with $Provider<NotificationApi> {
  NotificationApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationApiHash();

  @$internal
  @override
  $ProviderElement<NotificationApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotificationApi create(Ref ref) {
    return notificationApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationApi>(value),
    );
  }
}

String _$notificationApiHash() => r'5f2a9fc2f46a9ace12c18b6876e804a41047e1fe';

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

final class NotificationRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationRepository,
          NotificationRepository,
          NotificationRepository
        >
    with $Provider<NotificationRepository> {
  NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'13ef3b682c1d1e5ec5d79594aef649e4b3571d30';
