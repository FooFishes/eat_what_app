class const CityResponse({
  required final int id,
  required final int provinceId,
  required final String name,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return CityResponse(
      id: (json['id'] as num).toInt(),
      provinceId: (json['provinceId'] as num).toInt(),
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'provinceId': provinceId, 'name': name};
  }
}
