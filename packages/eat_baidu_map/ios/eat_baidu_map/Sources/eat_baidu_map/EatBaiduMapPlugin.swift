import BaiduMapAPI_Base
import Flutter
import UIKit

/// 百度地图原生桥的入口: 注册 SDK 接口和地图平台视图.
///
/// SDK 只在 Dart 调用 `initialize` 之后才启动. 百度要求先 `setAgreePrivacy` 再 `start`,
/// 而 App 只有在用户同意隐私政策之后才会打开地图.
public final class EatBaiduMapPlugin: NSObject, FlutterPlugin, SdkHostApi, BMKGeneralDelegate {
  private let sdkEvents: SdkFlutterApi
  private var manager: BMKMapManager?

  init(messenger: FlutterBinaryMessenger) {
    sdkEvents = SdkFlutterApi(binaryMessenger: messenger)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let plugin = EatBaiduMapPlugin(messenger: messenger)
    SdkHostApiSetup.setUp(binaryMessenger: messenger, api: plugin)
    registrar.register(BaiduMapViewFactory(messenger: messenger), withId: "you.v50to.eat/baidu_map")
  }

  func initialize(apiKey: String) throws {
    if manager != nil { return }
    BMKMapManager.setAgreePrivacy(true)
    BMKMapManager.setCoordinateTypeUsedInBaiduMapSDK(BMK_COORDTYPE_COMMON)
    let manager = BMKMapManager()
    self.manager = manager
    if !manager.start(apiKey, generalDelegate: self) {
      throw PigeonError(code: "init-failed", message: "BMKMapManager start 失败", details: nil)
    }
  }

  public func onGetPermissionState(_ iError: Int32) {
    let events = sdkEvents
    Task { @MainActor in
      try? await events.onAuthResult(code: Int64(iError), message: "")
    }
  }
}
