class const ProvinceResponse({
  required final int id,
  required final String name,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return ProvinceResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
