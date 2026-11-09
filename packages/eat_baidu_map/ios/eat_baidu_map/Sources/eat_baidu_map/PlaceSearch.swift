import BaiduMapAPI_Base
import BaiduMapAPI_Search
import CoreLocation

/// 百度地点的周边检索. 结果的坐标类型跟随全局坐标类型, 和地图一样是 GCJ-02. 公交站和地铁站不返回.
final class PlaceSearch: PlaceSearchHostApi {
  /// 检索中的请求. `BMKPoiSearch` 和它的代理要活到结果回来.
  private var pending = Set<PlaceSearchRequest>()

  @MainActor
  func searchNearby(keyword: String, center: LatLngMessage, radius: Int64, pageSize: Int64)
    async throws -> [PlaceMessage]
  {
    let option = BMKPOINearbySearchOption()
    option.keywords = [keyword]
    option.location = CLLocationCoordinate2D(latitude: center.lat, longitude: center.lng)
    option.radius = Int(radius)
    option.isRadiusLimit = true
    // 默认把结构化地址当门址检索, 这里只要地点.
    option.addressResult = false
    // 详细信息里才有分类, 用来去掉公交站和地铁站.
    option.scope = BMK_POI_SCOPE_DETAIL_INFORMATION
    option.pageIndex = 0
    option.pageSize = Int(pageSize)
    let request = PlaceSearchRequest()
    pending.insert(request)
    defer { pending.remove(request) }
    return try await request.run(option)
  }
}

private final class PlaceSearchRequest: NSObject, BMKPoiSearchDelegate {
  private let search = BMKPoiSearch()
  private var continuation: CheckedContinuation<[PlaceMessage], Error>?

  @MainActor
  func run(_ option: BMKPOINearbySearchOption) async throws -> [PlaceMessage] {
    try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      search.delegate = self
      if !search.poiSearchNear(by: option) {
        finish(.failure(PigeonError(code: "search-failed", message: "poiSearchNearBy 未发出", details: nil)))
      }
    }
  }

  func onGetPoiResult(
    _ searcher: BMKPoiSearch!, result poiResult: BMKPOISearchResult!, errorCode: BMKSearchErrorCode
  ) {
    if errorCode == BMK_SEARCH_NO_ERROR {
      let places = (poiResult?.poiInfoList ?? []).compactMap { poi -> PlaceMessage? in
        guard let uid = poi.UID, !uid.isEmpty else { return nil }
        if poi.detailInfo?.tag?.hasPrefix("交通设施") == true { return nil }
        return PlaceMessage(
          uid: uid,
          name: poi.name ?? "",
          address: poi.address ?? "",
          location: LatLngMessage(lat: poi.pt.latitude, lng: poi.pt.longitude))
      }
      finish(.success(places))
    } else if errorCode == BMK_SEARCH_RESULT_NOT_FOUND {
      finish(.success([]))
    } else {
      finish(
        .failure(
          PigeonError(code: "search-failed", message: "错误码 \(errorCode.rawValue)", details: nil)))
    }
  }

  private func finish(_ result: Result<[PlaceMessage], Error>) {
    search.delegate = nil
    continuation?.resume(with: result)
    continuation = nil
  }
}
