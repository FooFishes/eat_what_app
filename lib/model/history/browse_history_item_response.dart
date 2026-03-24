import 'package:eat_what_app/model/food/food_vo.dart';
import 'package:eat_what_app/model/restaurant/restaurant.dart';

class BrowseHistoryItemResponse {
  final String targetType;
  final int targetId;
  final int viewedAt;
  final Restaurant? restaurant;
  final FoodVO? food;

  const BrowseHistoryItemResponse({
    required this.targetType,
    required this.targetId,
    required this.viewedAt,
    this.restaurant,
    this.food,
  });

  factory BrowseHistoryItemResponse.fromJson(Map<String, dynamic> json) {
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
