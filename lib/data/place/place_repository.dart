import 'package:dio/dio.dart';
import 'package:eat/core/config/app_config.dart';
import 'package:eat/data/common/convert.dart';
import 'package:eat/data/place/place_api.dart';
import 'package:eat/data/place/place_dto.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/paged.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/geo_rules.dart';
import 'package:eat/domain/rules/publish_rules.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_repository.g.dart';

/// 校区、商圈和店：DTO 转成领域模型。坐标缺了的条目丢掉，没法放到地图上也算不了距离。
class PlaceRepository {
  PlaceRepository(this._api, this._assetBaseUrl);

  final PlaceApi _api;
  final String _assetBaseUrl;

  /// 已开放的校区，按运营给的顺序。
  Future<List<Campus>> campuses({CancelToken? cancelToken}) async {
    final list = await _api.campuses(cancelToken: cancelToken);
    final sorted = [...list]
      ..sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
    return [
      for (final dto in sorted)
        if (dto.id != null && dto.gcjLat != null && dto.gcjLng != null)
          Campus(
            id: dto.id!,
            name: dto.name ?? '',
            center: GcjPoint(dto.gcjLat!, dto.gcjLng!),
            isDefault: dto.isDefault ?? false,
          ),
    ];
  }

  /// 全部商圈。一个校区周边就十来个，一页拉完。
  Future<List<Hub>> hubs({CancelToken? cancelToken}) async {
    final page = await _api.hubs(cancelToken: cancelToken);
    return [for (final dto in page.items) ?_hub(dto)];
  }

  Future<Hub?> locateHub(GcjPoint point) async {
    final dto = await _api.locateHub(point.lat, point.lng);
    return dto == null ? null : _hub(dto);
  }

  /// 新建一家店，返回店的 id。[photoKey] 是门头照片上传后的 key。
  Future<int> createShop({
    required String name,
    required String address,
    required GcjPoint point,
    int? hubId,
    String? photoKey,
  }) => _api.createRestaurant(
    CreateRestaurantDto(
      name: name,
      address: address,
      gcjLng: point.lng,
      gcjLat: point.lat,
      hubId: hubId,
      pictureUrl: photoKey == null ? null : [photoKey],
    ),
  );

  /// [point] 附近 [radius] 米内和 [name] 同名的店，没有返回 null（产品 9.2）。
  Future<Shop?> sameNameNearby(
    String name,
    GcjPoint point, {
    int radius = 200,
    CancelToken? cancelToken,
  }) async {
    final key = PublishRules.compactName(name);
    if (key.isEmpty) return null;
    final page = await searchShops(
      keyword: name.trim(),
      near: point,
      radius: radius,
      cancelToken: cancelToken,
    );
    for (final shop in page.items) {
      if (PublishRules.compactName(shop.name) == key &&
          GeoRules.distance(point, shop.point) <= radius) {
        return shop;
      }
    }
    return null;
  }

  Future<Shop> shop(int id, {CancelToken? cancelToken}) async {
    final shop = _shop(await _api.restaurant(id, cancelToken: cancelToken));
    if (shop == null) {
      throw StateError('restaurant $id has no location');
    }
    return shop;
  }

  Future<Paged<Shop>> searchShops({
    String? keyword,
    int? hubId,
    GcjPoint? near,
    int? radius,
    int page = 1,
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async {
    final result = await _api.searchRestaurants(
      keyword: keyword,
      hubId: hubId,
      gcjLat: near?.lat,
      gcjLng: near?.lng,
      radius: radius,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
    return Paged(
      items: [for (final dto in result.items) ?_shop(dto)],
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  Shop? _shop(RestaurantDto dto) {
    if (dto.id == null || dto.gcjLat == null || dto.gcjLng == null) {
      return null;
    }
    return Shop(
      id: dto.id!,
      name: dto.name?.trim() ?? '',
      address: dto.address?.trim().isEmpty ?? true ? null : dto.address!.trim(),
      point: GcjPoint(dto.gcjLat!, dto.gcjLng!),
      hubId: dto.hubId,
      photos: [
        for (final url in dto.pictureUrl ?? const <String>[])
          ?resolveImageUrl(url, _assetBaseUrl),
      ],
    );
  }

  static Hub? _hub(HubDto dto) {
    if (dto.id == null || dto.gcjLat == null || dto.gcjLng == null) return null;
    return Hub(
      id: dto.id!,
      name: dto.name ?? '',
      center: GcjPoint(dto.gcjLat!, dto.gcjLng!),
      campusId: dto.campusId,
      boundary: _rings(dto.boundary),
    );
  }

  /// MultiPolygon 每个多边形的外环；形状不对时返回空，地图上不画范围。
  static List<List<WgsPoint>> _rings(GeoJsonDto? geometry) {
    if (geometry?.type != 'MultiPolygon') return const [];
    try {
      return [
        for (final polygon in geometry!.coordinates!)
          [
            for (final point
                in (polygon as List<dynamic>).first as List<dynamic>)
              WgsPoint(
                ((point as List<dynamic>)[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ),
          ],
      ];
    } on Object {
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
PlaceRepository placeRepository(Ref ref) => PlaceRepository(
  ref.watch(placeApiProvider),
  ref.watch(appConfigProvider).assetBaseUrl,
);
