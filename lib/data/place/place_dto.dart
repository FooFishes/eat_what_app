import 'package:json_annotation/json_annotation.dart';

part 'place_dto.g.dart';

/// `/campus/list` 的一项。
@JsonSerializable(createToJson: false)
class const CampusDto({
  final int? id,
  final String? name,
  final double? gcjLng,
  final double? gcjLat,
  final bool? isDefault,
  final int? sort,
}) {
  factory CampusDto.fromJson(Map<String, dynamic> json) =>
      _$CampusDtoFromJson(json);
}

/// 商圈（`HubVO`）。[boundary] 是 GeoJSON，坐标按 WGS-84 读（技术架构待确认 A3）。
@JsonSerializable(createToJson: false)
class const HubDto({
  final int? id,
  final String? name,
  final double? gcjLng,
  final double? gcjLat,
  final int? campusId,
  final GeoJsonDto? boundary,
}) {
  factory HubDto.fromJson(Map<String, dynamic> json) => _$HubDtoFromJson(json);
}

/// GeoJSON 几何：`Point` 的坐标是 `[经度, 纬度]`，`MultiPolygon` 按多边形、环、点三层嵌套。
@JsonSerializable(createToJson: false)
class const GeoJsonDto({final String? type, final List<dynamic>? coordinates}) {
  factory GeoJsonDto.fromJson(Map<String, dynamic> json) =>
      _$GeoJsonDtoFromJson(json);
}

/// 餐厅（`RestaurantVO`）。
@JsonSerializable(createToJson: false)
class const RestaurantDto({
  final int? id,
  final String? name,
  final String? address,
  final double? gcjLng,
  final double? gcjLat,
  final int? hubId,
  final List<String>? pictureUrl,
}) {
  factory RestaurantDto.fromJson(Map<String, dynamic> json) =>
      _$RestaurantDtoFromJson(json);
}
