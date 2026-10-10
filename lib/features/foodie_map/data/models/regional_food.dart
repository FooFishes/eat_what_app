import 'package:eat_what_app/features/foodie_map/data/models/activity_food_response.dart';

class const RegionalFood({
  required final int id,
  required final String foodName,
  required final String accountName,
  required final int accountId,
  required final String description,
  required final bool isLiked,
  required final String? url,
}) {
  new fromActivityFoodResponse(ActivityFoodResponse response)
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
