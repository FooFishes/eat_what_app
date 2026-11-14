// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FansDto _$FansDtoFromJson(Map<String, dynamic> json) => FansDto(
  id: (json['id'] as num?)?.toInt(),
  displayName: json['displayName'] as String?,
  avatar: json['avatar'] as String?,
  createdAt: (json['createdAt'] as num?)?.toInt(),
);

BlockedUserDto _$BlockedUserDtoFromJson(Map<String, dynamic> json) =>
    BlockedUserDto(
      userId: (json['userId'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
    );

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: (json['id'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
      signature: json['signature'] as String?,
      level: (json['level'] as num?)?.toInt(),
      earnedLikes: (json['earnedLikes'] as num?)?.toInt(),
      fansCount: (json['fansCount'] as num?)?.toInt(),
      followingsCount: (json['followingsCount'] as num?)?.toInt(),
      fansVisible: json['fansVisible'] as bool?,
      followingsVisible: json['followingsVisible'] as bool?,
      isFollowingMe: json['isFollowingMe'] as bool?,
      isFollowingHim: json['isFollowingHim'] as bool?,
      blocked: json['blocked'] as bool?,
    );

UserInfoDto _$UserInfoDtoFromJson(Map<String, dynamic> json) => UserInfoDto(
  id: (json['id'] as num?)?.toInt(),
  displayName: json['displayName'] as String?,
  userName: json['userName'] as String?,
  hasUsername: json['hasUsername'] as bool?,
  avatar: json['avatar'] as String?,
  phone: json['phone'] as String?,
  verified: json['verified'] as bool?,
  method: json['method'] as String?,
  verifiedEmail: json['verifiedEmail'] as String?,
  hasPassword: json['hasPassword'] as bool?,
  signature: json['signature'] as String?,
  level: (json['level'] as num?)?.toInt(),
  banned: json['banned'] as bool?,
  banReason: json['banReason'] as String?,
  banUntil: (json['banUntil'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserInfoDtoToJson(UserInfoDto instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'displayName': ?instance.displayName,
      'userName': ?instance.userName,
      'hasUsername': ?instance.hasUsername,
      'avatar': ?instance.avatar,
      'phone': ?instance.phone,
      'verified': ?instance.verified,
      'method': ?instance.method,
      'verifiedEmail': ?instance.verifiedEmail,
      'hasPassword': ?instance.hasPassword,
      'signature': ?instance.signature,
      'level': ?instance.level,
      'banned': ?instance.banned,
      'banReason': ?instance.banReason,
      'banUntil': ?instance.banUntil,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userApi)
final userApiProvider = UserApiProvider._();

final class UserApiProvider
    extends $FunctionalProvider<UserApi, UserApi, UserApi>
    with $Provider<UserApi> {
  UserApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userApiHash();

  @$internal
  @override
  $ProviderElement<UserApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserApi create(Ref ref) {
    return userApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserApi>(value),
    );
  }
}

String _$userApiHash() => r'23f185146d93445fd66b7da737968db3c665f211';
