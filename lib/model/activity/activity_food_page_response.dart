import 'package:eat_what_app/model/activity/activity_food_response.dart';

class ActivityFoodPageResponse {
  final int currentPage;
  final List<ActivityFoodResponse> items;
  final int totalPages;
  final int totalItems;
  final bool hasNext;

  ActivityFoodPageResponse({
    required this.currentPage,
    required List<ActivityFoodResponse> items,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
  }) : items = List<ActivityFoodResponse>.unmodifiable(items);

  factory ActivityFoodPageResponse.fromJson(Map<String, dynamic> json) {
    return ActivityFoodPageResponse(
      currentPage: (json['currentPage'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map(
            (item) => ActivityFoodResponse.fromJson(
              item as Map<String, dynamic>,
            ),
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
