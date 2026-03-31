class UserProfileStatsResponse {
  final String userName;
  final String? avatar;
  final int earnedLikes;
  final int uploadedFoodsCount;
  final int fansCount;
  final int followingsCount;
  final bool fansVisible;
  final bool followingsVisible;
  final bool isFollowingMe;
  final bool isFollowingHim;

  const UserProfileStatsResponse({
    required this.userName,
    this.avatar,
    required this.earnedLikes,
    required this.uploadedFoodsCount,
    required this.fansCount,
    required this.followingsCount,
    required this.fansVisible,
    required this.followingsVisible,
    required this.isFollowingMe,
    required this.isFollowingHim,
  });

  factory UserProfileStatsResponse.fromJson(Map<String, dynamic> json) {
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
