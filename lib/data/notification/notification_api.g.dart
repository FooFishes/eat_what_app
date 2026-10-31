// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    NotificationDto(
      id: (json['id'] as num?)?.toInt(),
      actorId: (json['actorId'] as num?)?.toInt(),
      actorName: json['actorName'] as String?,
      actorAvatar: json['actorAvatar'] as String?,
      type: json['type'] as String?,
      targetType: json['targetType'] as String?,
      targetId: (json['targetId'] as num?)?.toInt(),
      data: json['data'] as String?,
      read: json['read'] as bool?,
      createdAt: (json['createdAt'] as num?)?.toInt(),
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
    r'b2a459190a9b47237ece8dacbc3d54899d7ee30e';
