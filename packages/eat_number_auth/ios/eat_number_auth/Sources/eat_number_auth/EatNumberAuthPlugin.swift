import ATAuthSDK
import Flutter
import UIKit

/// 运营商一键登录的原生桥, 包着阿里云号码认证 SDK.
///
/// SDK 只在 Dart 调用 `prepare` 之后才设置密钥. App 只有在用户同意隐私政策之后才会调用它.
/// SDK 的失败都转成返回值, 由 App 改用验证码登录, 不向 Dart 抛出.
public final class EatNumberAuthPlugin: NSObject, FlutterPlugin, NumberAuthHostApi {
  private var secret: String?

  /// 正在等授权页结果的调用, 同一时刻最多一个.
  private var pending: CheckedContinuation<LoginTokenMessage, Never>?

  public static func register(with registrar: FlutterPluginRegistrar) {
    NumberAuthHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: EatNumberAuthPlugin())
  }

  @MainActor
  func prepare(secret: String, timeoutMs: Int64) async throws -> String? {
    let sdk = TXCommonHandler.sharedInstance()
    let timeout = TimeInterval(timeoutMs) / 1000
    if self.secret != secret {
      let code = await Self.code { done in sdk.setAuthSDKInfo(secret) { done($0) } }
      if code != Code.success { return code }
      self.secret = secret
    }
    // 有没有 SIM 卡, 蜂窝网络开没开.
    let environment = await Self.code { done in
      sdk.checkEnvAvailable(with: .loginToken) { done($0) }
    }
    if environment != Code.success { return environment }
    // 预取号: 提前向运营商要脱敏号码, 授权页才能立刻弹出.
    let preload = await Self.code { done in
      sdk.accelerateLoginPage(withTimeout: timeout) { done($0) }
    }
    return preload == Code.success ? nil : preload
  }

  @MainActor
  func requestLoginToken(style: AuthPageStyleMessage, timeoutMs: Int64) async throws
    -> LoginTokenMessage
  {
    guard secret != nil, pending == nil, let controller = Self.topController() else {
      return Self.failed(Code.notReady)
    }
    let bottomInset = controller.view.window?.safeAreaInsets.bottom ?? 0
    let model = authPageModel(style, bottomInset: bottomInset) { [weak self] in
      self?.close()
      self?.finish(LoginTokenMessage(status: .cancelled))
    }
    return await withCheckedContinuation { continuation in
      pending = continuation
      TXCommonHandler.sharedInstance().getLoginToken(
        withTimeout: TimeInterval(timeoutMs) / 1000, controller: controller, model: model
      ) { [weak self] result in
        DispatchQueue.main.async { self?.onAuthEvent(result) }
      }
    }
  }

  func closeAuthPage() throws {
    close()
    finish(LoginTokenMessage(status: .cancelled))
  }

  /// 授权页的回调. 同一个回调会被调用多次: 页面拉起, 各种点击, 最后才是凭证或失败.
  private func onAuthEvent(_ result: [AnyHashable: Any]) {
    let code = Self.code(of: result)
    switch code {
    case Code.success:
      if let token = result["token"] as? String, !token.isEmpty {
        // 授权页留着并继续显示加载, 等 App 向服务端登录完再关.
        finish(LoginTokenMessage(status: .granted, token: token))
      } else {
        close()
        finish(Self.failed(Code.error))
      }
    case Code.cancelled, Code.interrupted, Code.destroyed:
      close()
      finish(LoginTokenMessage(status: .cancelled))
    case Code.switched:
      // 点切换按钮时 SDK 不关授权页.
      close()
      finish(LoginTokenMessage(status: .switched))
    case Code.pageShown:
      break
    default:
      // 7 开头的其余返回码都是界面事件 (点登录, 点勾选框, 点协议, 二次确认弹窗的开关), 不是结果.
      if code.hasPrefix("7") { break }
      close()
      finish(Self.failed(code))
    }
  }

  private func finish(_ message: LoginTokenMessage) {
    let continuation = pending
    pending = nil
    continuation?.resume(returning: message)
  }

  private func close() {
    let sdk = TXCommonHandler.sharedInstance()
    sdk.hideLoginLoading()
    sdk.cancelLoginVC(animated: true, complete: nil)
  }

  /// 调用 SDK 的一个带回调的方法, 取回返回码. SDK 的回调不一定在主线程, 也不保证只调用一次.
  @MainActor
  private static func code(
    _ call: (@escaping ([AnyHashable: Any]?) -> Void) -> Void
  ) async -> String {
    await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
      let once = Once()
      call { result in
        DispatchQueue.main.async {
          if once.done { return }
          once.done = true
          continuation.resume(returning: Self.code(of: result))
        }
      }
    }
  }

  /// 记录回调是否已经处理过. 只在主线程读写.
  private final class Once {
    var done = false
  }

  private static func code(of result: [AnyHashable: Any]?) -> String {
    if let code = result?["resultCode"] as? String, !code.isEmpty { return code }
    return Code.error
  }

  private static func failed(_ code: String) -> LoginTokenMessage {
    LoginTokenMessage(status: .failed, code: code)
  }

  /// 当前最上层的页面, 授权页从它上面弹出.
  @MainActor
  private static func topController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap { $0.windows }
    let window = windows.first { $0.isKeyWindow } ?? windows.first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}

/// SDK 的返回码 (六位数字) 和插件自己的返回码.
private enum Code {
  static let success = "600000"
  static let pageShown = "600001"
  static let cancelled = "700000"
  static let switched = "700001"
  static let interrupted = "700010"
  static let destroyed = "700020"
  static let notReady = "not-ready"
  static let error = "error"
}
