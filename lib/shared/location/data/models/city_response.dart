class CityResponse {
  final int id;
  final int provinceId;
  final String name;

  const CityResponse({
    required this.id,
    required this.provinceId,
    required this.name,
  });

  factory CityResponse.fromJson(Map<String, dynamic> json) {
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
