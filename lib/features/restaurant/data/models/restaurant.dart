class Restaurant({
  required final int id,
  required final String name,
  required final String address,
  required final int? cityId,
  required final double? gcjLng,
  required final double? gcjLat,
  required final int? hubId,
  required final String? poi,
  required List<String> pictureUrl,
  required final int? createdAt,
  required final int? updatedAt,
}) {
  final List<String> pictureUrl;

  this : pictureUrl = List<String>.unmodifiable(pictureUrl);

  factory fromJson(Map<String, dynamic> json) {
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
