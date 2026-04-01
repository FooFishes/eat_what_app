import 'package:eat_what_app/features/foodie_map/data/models/activity_food_response.dart';

class RegionalFood {
  final int id;
  final String foodName;
  final String accountName;
  final int accountId;
  final String description;
  final String? url;
  final bool isLiked;

  const RegionalFood({
    required this.id,
    required this.foodName,
    required this.accountName,
    required this.accountId,
    required this.description,
    required this.isLiked,
    required this.url,
  });

  RegionalFood.fromActivityFoodResponse(ActivityFoodResponse response)
    : this(
        id: response.id,
        foodName: response.foodName,
        accountName: response.uploaderName,
        accountId: response.accountId,
        description: response.description,
        isLiked: response.isLiked,
        url: response.pictureUrl.isNotEmpty ? response.pictureUrl.first : null,
      );

  RegionalFood copyWith({
    int? id,
    String? foodName,
    String? accountName,
    int? accountId,
    String? description,
    String? url,
    bool? isLiked,
  }) {
    return RegionalFood(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      accountName: accountName ?? this.accountName,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      isLiked: isLiked ?? this.isLiked,
      url: url ?? this.url,
    );
  }
}
