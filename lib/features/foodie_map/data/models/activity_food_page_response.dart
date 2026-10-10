import 'package:eat_what_app/features/foodie_map/data/models/activity_food_response.dart';

class ActivityFoodPageResponse({
  required final int currentPage,
  required List<ActivityFoodResponse> items,
  required final int totalPages,
  required final int totalItems,
  required final bool hasNext,
}) {
  final List<ActivityFoodResponse> items;

  this : items = List<ActivityFoodResponse>.unmodifiable(items);

  factory fromJson(Map<String, dynamic> json) {
    return ActivityFoodPageResponse(
      currentPage: (json['currentPage'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map(
            (item) =>
                ActivityFoodResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalItems: (json['totalItems'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'items': items.map((item) => item.toJson()).toList(),
      'totalPages': totalPages,
      'totalItems': totalItems,
      'hasNext': hasNext,
    };
  }
}
