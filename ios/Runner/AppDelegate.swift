import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    AppIconChannel.register(with: engineBridge.applicationRegistrar.messenger())
  }
}

/// 桌面图标切换, 对应 lib/core/platform/app_icon.dart.
///
/// 备选图标是资源目录里的 AppIcon-Bun, 由构建设置 ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES 打进包里.
/// 系统切换时会弹出提示, 这是 iOS 的固定行为.
enum AppIconChannel {
  /// 图标名到资源目录里的图标集名, 默认图标为 nil.
  private static let iconSets: [String: String?] = ["pig": nil, "bun": "AppIcon-Bun"]

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "you.v50to.eat/app_icon", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "get":
        let current = UIApplication.shared.alternateIconName
        let name = AppIconChannel.iconSets.first(where: { $0.value == current })?.key ?? "pig"
        result(name)
      case "set":
        guard let name = call.arguments as? String, let iconSet = AppIconChannel.iconSets[name] else {
          result(FlutterError(code: "invalid", message: "unknown icon", details: nil))
          return
        }
        guard UIApplication.shared.supportsAlternateIcons else {
          result(FlutterError(code: "unsupported", message: "alternate icons unsupported", details: nil))
          return
        }
        if UIApplication.shared.alternateIconName == iconSet {
          result(nil)
          return
        }
        UIApplication.shared.setAlternateIconName(iconSet) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
