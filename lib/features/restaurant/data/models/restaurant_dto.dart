class const RestaurantDTO({
  required final String name,
  required final String address,
  required final int? cityId,
  required final double gcjLng,
  required final double gcjLat,
  required final int? hubId,
  required final String? poi,
  required final List<String> pictureUrl,
}) {
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
