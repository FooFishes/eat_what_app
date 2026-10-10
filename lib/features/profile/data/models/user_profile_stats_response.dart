class const UserProfileStatsResponse({
  required final String userName,
  final String? avatar,
  required final int earnedLikes,
  required final int uploadedFoodsCount,
  required final int fansCount,
  required final int followingsCount,
  required final bool fansVisible,
  required final bool followingsVisible,
  required final bool isFollowingMe,
  required final bool isFollowingHim,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return UserProfileStatsResponse(
      userName: json['userName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      earnedLikes: (json['earnedLikes'] as num?)?.toInt() ?? 0,
      uploadedFoodsCount: (json['uploadedFoodsCount'] as num?)?.toInt() ?? 0,
      fansCount: (json['fansCount'] as num?)?.toInt() ?? 0,
      followingsCount: (json['followingsCount'] as num?)?.toInt() ?? 0,
      fansVisible: json['fansVisible'] as bool? ?? false,
      followingsVisible: json['followingsVisible'] as bool? ?? false,
      isFollowingMe: json['isFollowingMe'] as bool? ?? false,
      isFollowingHim: json['isFollowingHim'] as bool? ?? false,
    );
  }
}
