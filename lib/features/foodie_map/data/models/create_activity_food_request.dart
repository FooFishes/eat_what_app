class CreateActivityFoodRequest {
  final String foodName;
  final String? description;
  final int provinceId;
  final int cityId;
  final List<String> pictureUrl;

  const CreateActivityFoodRequest({
    required this.foodName,
    required this.description,
    required this.provinceId,
    required this.cityId,
    required this.pictureUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'description': description,
      'provinceId': provinceId,
      'cityId': cityId,
      'pictureUrl': pictureUrl,
    };
  }
}
