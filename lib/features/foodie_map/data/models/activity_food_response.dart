class ActivityFoodResponse({
  required final int id,
  required final int accountId,
  required final String foodName,
  required final String description,
  required final int provinceId,
  required final int cityId,
  required List<String> pictureUrl,
  required final int likesCount,
  required final bool isLiked,
  required final int createdAt,
  required final int updatedAt,
  required final String uploaderName,
}) {
  final List<String> pictureUrl;

  this : pictureUrl = List<String>.unmodifiable(pictureUrl);

  factory fromJson(Map<String, dynamic> json) {
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
