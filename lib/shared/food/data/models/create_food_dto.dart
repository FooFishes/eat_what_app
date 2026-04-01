class CreateFoodDTO {
  final int restaurantId;
  final String name;
  final String? description;
  final double? price;
  final String? category;
  final List<String> pictureUrl;

  const CreateFoodDTO({
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.pictureUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'pictureUrl': pictureUrl,
    };
  }
}
