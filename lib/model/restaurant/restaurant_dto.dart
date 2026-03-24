class RestaurantDTO {
  final String name;
  final String address;
  final int? cityId;
  final double gcjLng;
  final double gcjLat;
  final int? hubId;
  final String? poi;
  final List<String> pictureUrl;

  const RestaurantDTO({
    required this.name,
    required this.address,
    required this.cityId,
    required this.gcjLng,
    required this.gcjLat,
    required this.hubId,
    required this.poi,
    required this.pictureUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'cityId': cityId,
      'gcjLng': gcjLng,
      'gcjLat': gcjLat,
      'hubId': hubId,
      'POI': poi,
      'pictureUrl': pictureUrl,
    };
  }
}
