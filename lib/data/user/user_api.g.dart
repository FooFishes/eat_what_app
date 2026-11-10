// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobileCommandDto _$MobileCommandDtoFromJson(Map<String, dynamic> json) =>
    MobileCommandDto(
      commandId: json['commandId'] as String?,
      oldProofRequired: json['oldProofRequired'] as bool?,
    );

MobileCommitDto _$MobileCommitDtoFromJson(Map<String, dynamic> json) =>
    MobileCommitDto(
      currentDevice: json['currentDevice'] as String?,
      replacement: json['replacement'] == null
          ? null
          : SessionOutcomeDto.fromJson(
              json['replacement'] as Map<String, dynamic>,
            ),
    );

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
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
      earnedLikes: (json['earnedLikes'] as num?)?.toInt(),
      fansCount: (json['fansCount'] as num?)?.toInt(),
      followingsCount: (json['followingsCount'] as num?)?.toInt(),
      fansVisible: json['fansVisible'] as bool?,
      followingsVisible: json['followingsVisible'] as bool?,
      isFollowingMe: json['isFollowingMe'] as bool?,
      isFollowingHim: json['isFollowingHim'] as bool?,
      uploadedFoodsCount: (json['uploadedFoodsCount'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
    );

UserInfoDto _$UserInfoDtoFromJson(Map<String, dynamic> json) => UserInfoDto(
  id: (json['id'] as num?)?.toInt(),
  displayName: json['displayName'] as String?,
  userName: json['userName'] as String?,
  hasUsername: json['hasUsername'] as bool?,
  avatar: json['avatar'] as String?,
  banned: json['banned'] as bool?,
  banReason: json['banReason'] as String?,
  bannedAt: (json['bannedAt'] as num?)?.toInt(),
  banUntil: (json['banUntil'] as num?)?.toInt(),
  phone: json['phone'] as String?,
  verified: json['verified'] as bool?,
  method: json['method'] as String?,
  verifiedEmail: json['verifiedEmail'] as String?,
  hasPassword: json['hasPassword'] as bool?,
  signature: json['signature'] as String?,
);

Map<String, dynamic> _$UserInfoDtoToJson(UserInfoDto instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'displayName': ?instance.displayName,
      'userName': ?instance.userName,
      'hasUsername': ?instance.hasUsername,
      'avatar': ?instance.avatar,
      'banned': ?instance.banned,
      'banReason': ?instance.banReason,
      'bannedAt': ?instance.bannedAt,
      'banUntil': ?instance.banUntil,
      'phone': ?instance.phone,
      'verified': ?instance.verified,
      'method': ?instance.method,
      'verifiedEmail': ?instance.verifiedEmail,
      'hasPassword': ?instance.hasPassword,
      'signature': ?instance.signature,
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
