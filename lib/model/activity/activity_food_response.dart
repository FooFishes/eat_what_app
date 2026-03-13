class ActivityFoodResponse {
  final int id;
  final int accountId;
  final String foodName;
  final String description;
  final int provinceId;
  final int cityId;
  final List<String> pictureUrl;
  final int likesCount;
  final bool isLiked;
  final int createdAt;
  final int updatedAt;
  final String uploaderName;

  ActivityFoodResponse({
    required this.id,
    required this.accountId,
    required this.foodName,
    required this.description,
    required this.provinceId,
    required this.cityId,
    required List<String> pictureUrl,
    required this.likesCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
    required this.uploaderName,
  }) : pictureUrl = List<String>.unmodifiable(pictureUrl);

  factory ActivityFoodResponse.fromJson(Map<String, dynamic> json) {
    return ActivityFoodResponse(
      id: (json['id'] as num).toInt(),
      accountId: (json['accountId'] as num).toInt(),
      foodName: json['foodName'] as String,
      description: json['description'] as String,
      provinceId: (json['provinceId'] as num).toInt(),
      cityId: (json['cityId'] as num).toInt(),
      pictureUrl: (json['pictureUrl'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      likesCount: (json['likesCount'] as num).toInt(),
      isLiked: json['isLiked'] as bool,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      uploaderName: json['uploaderName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'foodName': foodName,
      'description': description,
      'provinceId': provinceId,
      'cityId': cityId,
      'pictureUrl': pictureUrl,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'uploaderName': uploaderName,
    };
  }
}
