import 'package:eat_what_app/model/activity/activity_food_dto.dart';

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

  RegionalFood.fromActivityFoodDto(ActivityFoodDto dto)
    : this(
        id: dto.id,
        foodName: dto.foodName,
        accountName: dto.uploaderName,
        accountId: dto.accountId,
        description: dto.description,
        isLiked: dto.isLiked,
        url: dto.pictureUrl.isNotEmpty ? dto.pictureUrl.first : null,
      );
}
