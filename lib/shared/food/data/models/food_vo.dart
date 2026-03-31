import 'package:eat_what_app/shared/food/data/models/food_system_tag_vo.dart';
import 'package:eat_what_app/shared/food/data/models/food_tag_summary_vo.dart';

class FoodVO {
  final int id;
  final int? accountId;
  final String uploaderName;
  final int restaurantId;
  final String name;
  final String description;
  final double? price;
  final String? category;
  final List<String> pictureUrl;
  final List<FoodSystemTagVO> systemTags;
  final List<FoodTagSummaryVO> myCustomTags;
  final bool isFavorite;
  final int likesCount;
  final int? createdAt;
  final int? updatedAt;

  FoodVO({
    required this.id,
    required this.accountId,
    required this.uploaderName,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required List<String> pictureUrl,
    required List<FoodSystemTagVO> systemTags,
    required List<FoodTagSummaryVO> myCustomTags,
    required this.isFavorite,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
  }) : pictureUrl = List<String>.unmodifiable(pictureUrl),
       systemTags = List<FoodSystemTagVO>.unmodifiable(systemTags),
       myCustomTags = List<FoodTagSummaryVO>.unmodifiable(myCustomTags);

  factory FoodVO.fromJson(Map<String, dynamic> json) {
    return FoodVO(
      id: _parseInt(json['id']) ?? 0,
      accountId: _parseInt(json['accountId']),
      uploaderName: (json['uploaderName'] as String?)?.trim() ?? '',
      restaurantId: _parseInt(json['restaurantId']) ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      price: _parseDouble(json['price']),
      category: (json['category'] as String?)?.trim(),
      pictureUrl: (json['pictureUrl'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      systemTags: (json['systemTags'] as List<dynamic>? ?? const [])
          .map((item) => FoodSystemTagVO.fromJson(item as Map<String, dynamic>))
          .toList(),
      myCustomTags: (json['myCustomTags'] as List<dynamic>? ?? const [])
          .map(
            (item) => FoodTagSummaryVO.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      likesCount: _parseInt(json['likesCount']) ?? 0,
      createdAt: _parseInt(json['createdAt']),
      updatedAt: _parseInt(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'uploaderName': uploaderName,
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'pictureUrl': pictureUrl,
      'systemTags': systemTags.map((item) => item.toJson()).toList(),
      'myCustomTags': myCustomTags.map((item) => item.toJson()).toList(),
      'isFavorite': isFavorite,
      'likesCount': likesCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static int? _parseInt(Object? value) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      _ => null,
    };
  }

  static double? _parseDouble(Object? value) {
    return switch (value) {
      double v => v,
      num v => v.toDouble(),
      _ => null,
    };
  }
}
