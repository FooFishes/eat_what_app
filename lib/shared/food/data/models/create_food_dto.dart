class const CreateFoodDTO({
  required final int restaurantId,
  required final String name,
  required final String? description,
  required final double? price,
  required final String? category,
  required final List<String> pictureUrl,
}) {
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
