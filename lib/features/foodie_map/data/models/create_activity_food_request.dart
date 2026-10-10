class const CreateActivityFoodRequest({
  required final String foodName,
  required final String? description,
  required final int provinceId,
  required final int cityId,
  required final List<String> pictureUrl,
}) {
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
