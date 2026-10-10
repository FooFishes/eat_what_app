import 'package:eat_what_app/shared/food/data/models/food_vo.dart';
import 'package:eat_what_app/features/restaurant/data/models/restaurant.dart';

class const BrowseHistoryItemResponse({
  required final String targetType,
  required final int targetId,
  required final int viewedAt,
  final Restaurant? restaurant,
  final FoodVO? food,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return BrowseHistoryItemResponse(
      targetType: json['targetType'] as String? ?? '',
      targetId: (json['targetId'] as num?)?.toInt() ?? 0,
      viewedAt: (json['viewedAt'] as num?)?.toInt() ?? 0,
      restaurant: json['restaurant'] is Map<String, dynamic>
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      food: json['food'] is Map<String, dynamic>
          ? FoodVO.fromJson(json['food'] as Map<String, dynamic>)
          : null,
    );
  }
}
