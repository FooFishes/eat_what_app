import BaiduMapAPI_Base
import BaiduMapAPI_Map
import Flutter
import UIKit

final class BaiduMapViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    BaiduMapPlatformView(
      frame: frame,
      viewId: viewId,
      params: args as? [String: Any] ?? [:],
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

/// 一个标记. 记下 id 和图片, 在 `viewFor annotation` 里生成视图.
final class MarkerAnnotation: BMKPointAnnotation {
  var id = ""
  var image: UIImage?
  var anchor = CGPoint(x: 0.5, y: 0.5)
}

/// 把 Pigeon 的调用转给地图视图, 但不持有它. 视图随 Flutter 释放, 释放时注销通道.
private final class WeakHostApi: MapViewHostApi {
  weak var target: BaiduMapPlatformView?

  init(_ target: BaiduMapPlatformView) {
    self.target = target
  }

  func updateMarkers(upserts: [MarkerMessage], removedIds: [String]) throws {
    target?.updateMarkers(upserts: upserts, removedIds: removedIds)
  }

  func setPolygons(polygons: [PolygonMessage]) throws {
    target?.setPolygons(polygons)
  }

  func setInsets(insets: InsetsMessage) throws {
    target?.setInsets(insets)
  }

  func moveCamera(center: LatLngMessage, zoom: Double?, animated: Bool) throws {
    target?.moveCamera(center: center, zoom: zoom, animated: animated)
  }

  func fitPoints(points: [LatLngMessage], margin: InsetsMessage, animated: Bool) throws {
    target?.fitPoints(points, margin: margin, animated: animated)
  }

  func getCamera() throws -> CameraMessage {
    guard let target else { throw PigeonError(code: "disposed", message: nil, details: nil) }
    return target.camera()
  }

  func isLoaded() throws -> Bool {
    target?.loaded ?? false
  }

  func setCustomStyle(asset: String?) throws {
    target?.setCustomStyle(asset)
  }
}

/// 一张百度地图.
///
/// 浮层盖住的区域 (`setInsets`) 设成 `mapPadding`: logo 和比例尺移进剩下的可见区域,
/// 地图中心 (`targetScreenPt`) 也跟着移到可见区域中心.
final class BaiduMapPlatformView: NSObject, FlutterPlatformView, BMKMapViewDelegate {
  private let mapView: BMKMapView
  private let events: MapViewFlutterApi
  private let messenger: FlutterBinaryMessenger
  private let suffix: String
  private var markers: [String: MarkerAnnotation] = [:]
  private var polygons: [BMKPolygon] = []
  private var polygonStyles: [ObjectIdentifier: PolygonMessage] = [:]
  private var insets = UIEdgeInsets.zero
  private var movingByGesture = false
  private(set) var loaded = false

  init(frame: CGRect, viewId: Int64, params: [String: Any], messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    suffix = String(viewId)
    events = MapViewFlutterApi(binaryMessenger: messenger, messageChannelSuffix: suffix)
    mapView = BMKMapView(frame: frame)
    super.init()
    setCustomStyle(params["customStyle"] as? String)
    mapView.delegate = self
    mapView.isRotateEnabled = false
    mapView.isOverlookEnabled = false
    mapView.showMapScaleBar = true
    mapView.updateTargetScreenPtWhenMapPaddingChanged = true
    mapView.minZoomLevel = Float(params.double("minZoom"))
    mapView.maxZoomLevel = Float(params.double("maxZoom"))
    mapView.zoomLevel = Float(params.double("zoom"))
    mapView.centerCoordinate = CLLocationCoordinate2D(
      latitude: params.double("lat"),
      longitude: params.double("lng")
    )
    MapViewHostApiSetup.setUp(binaryMessenger: messenger, api: WeakHostApi(self), messageChannelSuffix: suffix)
    mapView.viewWillAppear()
  }

  deinit {
    MapViewHostApiSetup.setUp(binaryMessenger: messenger, api: nil, messageChannelSuffix: suffix)
    mapView.viewWillDisappear()
    mapView.delegate = nil
  }

  func view() -> UIView { mapView }

  // MARK: Dart 调用

  func updateMarkers(upserts: [MarkerMessage], removedIds: [String]) {
    for id in removedIds {
      if let annotation = markers.removeValue(forKey: id) {
        mapView.removeAnnotation(annotation)
      }
    }
    // 更新时整个删掉重加: 标注视图的图片在 viewFor annotation 里才设置.
    // 按 zIndex 从低到高加, 后加的画在上面.
    for m in upserts.sorted(by: { $0.zIndex < $1.zIndex }) {
      if let old = markers.removeValue(forKey: m.id) {
        mapView.removeAnnotation(old)
      }
      let annotation = MarkerAnnotation()
      annotation.id = m.id
      annotation.coordinate = m.position.coordinate
      annotation.image = UIImage(data: m.icon.data, scale: CGFloat(m.iconScale))
      annotation.anchor = CGPoint(x: m.anchorX, y: m.anchorY)
      markers[m.id] = annotation
      mapView.addAnnotation(annotation)
    }
  }

  func setPolygons(_ messages: [PolygonMessage]) {
    mapView.removeOverlays(polygons)
    polygons.removeAll()
    polygonStyles.removeAll()
    for p in messages where p.points.count >= 3 {
      var coordinates = p.points.map(\.coordinate)
      guard let polygon = BMKPolygon(coordinates: &coordinates, count: UInt(coordinates.count)) else {
        continue
      }
      polygonStyles[ObjectIdentifier(polygon)] = p
      polygons.append(polygon)
    }
    mapView.addOverlays(polygons)
  }

  func setInsets(_ message: InsetsMessage) {
    insets = message.edgeInsets
    mapView.mapPadding = insets
  }

  func moveCamera(center: LatLngMessage, zoom: Double?, animated: Bool) {
    let status = mapView.getMapStatus()
    status.targetGeoPt = center.coordinate
    if let point = visibleCenter { status.targetScreenPt = point }
    if let zoom { status.fLevel = Float(zoom) }
    mapView.setMapStatus(status, withAnimation: animated)
  }

  func fitPoints(_ points: [LatLngMessage], margin: InsetsMessage, animated: Bool) {
    guard let first = points.first else { return }
    var minLat = first.lat, maxLat = first.lat, minLng = first.lng, maxLng = first.lng
    for p in points {
      minLat = min(minLat, p.lat)
      maxLat = max(maxLat, p.lat)
      minLng = min(minLng, p.lng)
      maxLng = max(maxLng, p.lng)
    }
    let region = BMKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
      span: BMKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLng - minLng)
    )
    let m = margin.edgeInsets
    let padding = UIEdgeInsets(
      top: insets.top + m.top,
      left: insets.left + m.left,
      bottom: insets.bottom + m.bottom,
      right: insets.right + m.right
    )
    let status = mapView.getMapStatus(from: region, edgePadding: padding)
    mapView.setMapStatus(status, withAnimation: animated)
  }

  /// SDK 只认文件路径; Flutter 资源在 App 包里就是普通文件, 直接给包内路径.
  func setCustomStyle(_ asset: String?) {
    guard let asset,
      let path = Bundle.main.path(forResource: FlutterDartProject.lookupKey(forAsset: asset), ofType: nil)
    else {
      mapView.setCustomMapStyleEnable(false)
      return
    }
    mapView.setCustomMapStylePath(path)
    mapView.setCustomMapStyleEnable(true)
  }

  /// 地图没加载完或视图还没有尺寸时, 屏幕坐标换算不可靠 (Flutter 以零尺寸创建平台视图,
  /// 这时换算出来接近 (0, 0)), 改用地图状态里的中心点.
  func camera() -> CameraMessage {
    let center: CLLocationCoordinate2D
    if loaded, let point = visibleCenter {
      center = mapView.convert(point, toCoordinateFrom: mapView)
    } else {
      center = mapView.getMapStatus().targetGeoPt
    }
    return CameraMessage(
      center: LatLngMessage(lat: center.latitude, lng: center.longitude),
      zoom: Double(mapView.zoomLevel)
    )
  }

  /// 可见区域中心在地图视图里的位置. 视图还没有尺寸时为 nil.
  private var visibleCenter: CGPoint? {
    let b = mapView.bounds
    if b.width == 0 || b.height == 0 { return nil }
    return CGPoint(
      x: insets.left + (b.width - insets.left - insets.right) / 2,
      y: insets.top + (b.height - insets.top - insets.bottom) / 2
    )
  }

  // MARK: 地图事件

  func mapViewDidFinishLoading(_ mapView: BMKMapView) {
    loaded = true
    send { try await $0.onLoaded() }
  }

  func mapView(_ mapView: BMKMapView, regionWillChangeAnimated animated: Bool, reason: BMKRegionChangeReason) {
    movingByGesture = reason == BMKRegionChangeReasonGesture
  }

  func mapView(_ mapView: BMKMapView, regionDidChangeAnimated animated: Bool, reason: BMKRegionChangeReason) {
    let byGesture = movingByGesture
    movingByGesture = false
    let camera = camera()
    send { try await $0.onCameraIdle(camera: camera, byGesture: byGesture) }
  }

  func mapView(_ mapView: BMKMapView, viewFor annotation: BMKAnnotation) -> BMKAnnotationView? {
    guard let marker = annotation as? MarkerAnnotation else { return nil }
    let view = BMKAnnotationView(annotation: marker, reuseIdentifier: "eat-marker")
    if let image = marker.image {
      view?.image = image
      // 标注视图默认以图片中心对准坐标, 用 centerOffset 换成锚点.
      view?.centerOffset = CGPoint(
        x: image.size.width * (0.5 - marker.anchor.x),
        y: image.size.height * (0.5 - marker.anchor.y)
      )
    }
    view?.isForceDisplay = true
    return view
  }

  func mapView(_ mapView: BMKMapView, didSelect view: BMKAnnotationView) {
    guard let marker = view.annotation as? MarkerAnnotation else { return }
    // 立刻取消选中, 否则再点同一个标记不会再回调.
    mapView.deselectAnnotation(marker, animated: false)
    let id = marker.id
    send { try await $0.onMarkerTap(id: id) }
  }

  func mapView(_ mapView: BMKMapView, viewFor overlay: BMKOverlay) -> BMKOverlayView? {
    guard let polygon = overlay as? BMKPolygon,
      let style = polygonStyles[ObjectIdentifier(polygon)],
      let view = BMKPolygonView(polygon: polygon)
    else { return nil }
    view.fillColor = UIColor(argb: style.fillColor)
    view.strokeColor = UIColor(argb: style.strokeColor)
    view.lineWidth = CGFloat(style.strokeWidth)
    view.lineDashType = style.dashed ? kBMKLineDashTypeSquare : kBMKLineDashTypeNone
    return view
  }

  private func send(_ call: @escaping @MainActor (MapViewFlutterApi) async throws -> Void) {
    let events = events
    Task { @MainActor in try? await call(events) }
  }
}

extension LatLngMessage {
  fileprivate var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
}

extension InsetsMessage {
  fileprivate var edgeInsets: UIEdgeInsets {
    UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
  }
}

extension UIColor {
  fileprivate convenience init(argb: Int64) {
    let v = UInt32(truncatingIfNeeded: argb)
    self.init(
      red: CGFloat((v >> 16) & 0xFF) / 255,
      green: CGFloat((v >> 8) & 0xFF) / 255,
      blue: CGFloat(v & 0xFF) / 255,
      alpha: CGFloat((v >> 24) & 0xFF) / 255
    )
  }
}

extension Dictionary where Key == String, Value == Any {
  fileprivate func double(_ key: String) -> Double {
    (self[key] as? NSNumber)?.doubleValue ?? 0
  }
}
