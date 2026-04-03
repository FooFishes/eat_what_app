import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let bundlePath = Bundle.main.path(forResource: "mapapi", ofType: "bundle") {
      NSLog("Baidu map resources found at %@", bundlePath)
    } else {
      NSLog("Baidu map resources missing: mapapi.bundle is not in the app bundle")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
