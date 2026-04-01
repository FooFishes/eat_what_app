class Restaurant {
  final int id;
  final String name;
  final String address;
  final int? cityId;
  final double? gcjLng;
  final double? gcjLat;
  final int? hubId;
  final String? poi;
  final List<String> pictureUrl;
  final int? createdAt;
  final int? updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.gcjLng,
    required this.gcjLat,
    required this.hubId,
    required this.poi,
    required List<String> pictureUrl,
    required this.createdAt,
    required this.updatedAt,
  }) : pictureUrl = List<String>.unmodifiable(pictureUrl);

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: _parseInt(json['id']) ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      cityId: _parseInt(json['cityId']),
      gcjLng: _parseDouble(json['gcjLng']),
      gcjLat: _parseDouble(json['gcjLat']),
      hubId: _parseInt(json['hubId']),
      poi: (json['POI'] as String?)?.trim(),
      pictureUrl: (json['pictureUrl'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      createdAt: _parseInt(json['createdAt']),
      updatedAt: _parseInt(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'cityId': cityId,
      'gcjLng': gcjLng,
      'gcjLat': gcjLat,
      'hubId': hubId,
      'POI': poi,
      'pictureUrl': pictureUrl,
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
