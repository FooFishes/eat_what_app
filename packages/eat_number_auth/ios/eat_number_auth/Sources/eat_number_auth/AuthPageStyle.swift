import ATAuthSDK
import UIKit

/// 把授权页配成从底部升起的面板: 号码, 运营商标语, 登录按钮, 切换按钮, 运营商协议, 右上角一个关闭按钮.
///
/// 图片一律现画, 不用 SDK 自带的 ATAuthSDK.bundle (它得另外拷进 App 才找得到), 颜色才能跟着 App 的令牌走.
/// `bottomInset` 是底部安全区的高度. `onClose` 在用户点关闭按钮时调用.
func authPageModel(
  _ style: AuthPageStyleMessage, bottomInset: CGFloat, onClose: @escaping () -> Void
) -> TXCustomModel {
  let model = TXCustomModel()
  let background = UIColor(argb: style.background)
  let scrim = UIColor(argb: style.scrim)
  let primary = UIColor(argb: style.primary)
  let onPrimary = UIColor(argb: style.onPrimary)
  let secondary = UIColor(argb: style.secondary)
  let muted = UIColor(argb: style.muted)
  let margin = CGFloat(style.margin)
  let radius = NSNumber(value: style.cornerRadius)
  let buttonHeight = CGFloat(style.buttonHeight)
  let buttonImage = pill(primary, height: buttonHeight)
  let pressedImage = pill(primary.withAlphaComponent(0.85), height: buttonHeight)

  // 面板: 贴底, 和屏幕等宽, 顶部两个圆角, 点面板外面关闭. 不要标题栏, 关闭按钮自己加.
  model.contentViewFrameBlock = { screenSize, _, _ in
    let height = Layout.panelHeight + bottomInset
    return CGRect(x: 0, y: screenSize.height - height, width: screenSize.width, height: height)
  }
  model.alertBlurViewColor = scrim.withAlphaComponent(1)
  model.alertBlurViewAlpha = scrim.cgColor.alpha
  model.alertContentViewColor = background
  model.alertCornerRadiusArray = [radius, 0, 0, radius]
  model.alertBarIsHidden = true
  model.tapAuthPageMaskClosePage = true
  model.logoIsHidden = true
  model.customViewBlock = { superview in
    let button = UIButton(type: .custom, primaryAction: UIAction { _ in onClose() })
    button.setImage(closeImage(muted), for: .normal)
    button.accessibilityLabel = style.closeLabel
    button.frame = CGRect(
      x: superview.bounds.width - Layout.closeTouch - 8, y: Layout.closeTop,
      width: Layout.closeTouch, height: Layout.closeTouch)
    button.autoresizingMask = [.flexibleLeftMargin]
    superview.addSubview(button)
  }

  // 号码和运营商标语, 内容由 SDK 填.
  model.numberColor = primary
  model.numberFont = .systemFont(ofSize: 28, weight: .bold)
  model.numberFrameBlock = { _, superViewSize, frame in
    CGRect(
      x: (superViewSize.width - frame.width) / 2, y: Layout.numberTop,
      width: frame.width, height: frame.height)
  }
  model.sloganFrameBlock = { _, superViewSize, frame in
    CGRect(x: 0, y: Layout.sloganTop, width: superViewSize.width, height: frame.height)
  }

  // 登录按钮. 拿到凭证后继续显示加载, 等 App 向服务端登录完再关授权页.
  model.loginBtnText = NSAttributedString(
    string: style.loginText,
    attributes: [
      .foregroundColor: onPrimary,
      .font: UIFont.systemFont(ofSize: 16, weight: .bold),
    ])
  model.loginBtnBgImgs = [buttonImage, buttonImage, pressedImage]
  model.loginBtnFrameBlock = { _, superViewSize, _ in
    CGRect(
      x: margin, y: Layout.buttonTop, width: superViewSize.width - margin * 2, height: buttonHeight)
  }
  model.autoHideLoginLoading = false
  model.changeBtnTitle = NSAttributedString(
    string: style.switchText,
    attributes: [
      .foregroundColor: secondary,
      .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
    ])
  model.changeBtnFrameBlock = { _, superViewSize, _ in
    CGRect(
      x: margin, y: Layout.switchTop, width: superViewSize.width - margin * 2,
      height: Layout.switchHeight)
  }

  // 运营商协议, 默认不勾.
  model.checkBoxIsChecked = false
  model.checkBoxImages = [checkImage(false, muted, onPrimary), checkImage(true, primary, onPrimary)]
  model.checkBoxWH = Layout.checkSize
  model.expandAuthPageCheckedScope = true
  model.privacyColors = [muted, secondary]
  model.privacyFont = .systemFont(ofSize: 13)
  model.privacyAlignment = .center
  model.privacyPreText = style.privacyPrefix
  model.privacySufText = ""
  model.privacyOperatorPreText = "《"
  model.privacyOperatorSufText = "》"
  model.privacyFrameBlock = { _, superViewSize, frame in
    CGRect(
      x: margin, y: Layout.privacyTop, width: superViewSize.width - margin * 2,
      height: frame.height)
  }
  // 协议网页的返回按钮.
  if let back = UIImage(systemName: "chevron.left")?
    .withTintColor(primary, renderingMode: .alwaysOriginal)
  {
    model.privacyNavBackImage = back
  }
  model.privacyNavColor = background
  model.privacyNavTitleColor = primary

  // 没勾协议就点登录时的二次确认弹窗, 同意后直接登录.
  model.privacyAlertIsNeedShow = true
  model.privacyAlertIsNeedAutoLogin = true
  model.privacyAlertMaskIsNeedShow = true
  model.privacyAlertMaskColor = scrim.withAlphaComponent(1)
  model.privacyAlertMaskAlpha = scrim.cgColor.alpha
  model.tapPrivacyAlertMaskCloseAlert = true
  model.privacyAlertCloseButtonIsNeedShow = false
  model.privacyAlertBackgroundColor = background
  model.privacyAlertCornerRadiusArray = [radius, radius, radius, radius]
  model.privacyAlertTitleContent = style.alertTitle
  model.privacyAlertTitleFont = .systemFont(ofSize: 17, weight: .bold)
  model.privacyAlertTitleColor = primary
  model.privacyAlertPreText = style.alertPrefix
  model.privacyAlertSufText = ""
  model.privacyAlertContentFont = .systemFont(ofSize: 14)
  model.privacyAlertContentColors = [muted, secondary]
  model.privacyAlertContentAlignment = .center
  model.privacyAlertBtnContent = style.alertButtonText
  model.privacyAlertButtonFont = .systemFont(ofSize: 15, weight: .bold)
  model.privacyAlertButtonTextColors = [onPrimary, onPrimary]
  let alertButton = pill(primary, height: Layout.alertButtonHeight)
  model.privacyAlertBtnBackgroundImages = [alertButton, alertButton]
  model.privacyAlertFrameBlock = { screenSize, _, _ in
    let width = screenSize.width - Layout.alertMargin * 2
    return CGRect(
      x: Layout.alertMargin, y: (screenSize.height - Layout.alertHeight) / 2,
      width: width, height: Layout.alertHeight)
  }
  model.privacyAlertTitleFrameBlock = { _, superViewSize, frame in
    CGRect(x: 0, y: 26, width: superViewSize.width, height: frame.height)
  }
  model.privacyAlertPrivacyContentFrameBlock = { _, superViewSize, frame in
    CGRect(x: margin, y: 70, width: superViewSize.width - margin * 2, height: frame.height)
  }
  model.privacyAlertButtonFrameBlock = { _, superViewSize, _ in
    CGRect(
      x: margin, y: superViewSize.height - Layout.alertButtonHeight - 24,
      width: superViewSize.width - margin * 2, height: Layout.alertButtonHeight)
  }
  return model
}

/// 面板的高度和各个控件的位置, 从面板顶部算起. 面板实际还要加上底部安全区.
private enum Layout {
  static let panelHeight: CGFloat = 324
  static let closeTop: CGFloat = 3
  static let numberTop: CGFloat = 60
  static let sloganTop: CGFloat = 106
  static let buttonTop: CGFloat = 146
  static let switchTop: CGFloat = 206
  static let switchHeight: CGFloat = 44
  static let privacyTop: CGFloat = 274
  static let checkSize: CGFloat = 20
  static let closeTouch: CGFloat = 44
  static let closeIcon: CGFloat = 18
  static let alertMargin: CGFloat = 32
  static let alertHeight: CGFloat = 184
  static let alertButtonHeight: CGFloat = 48
}

/// 胶囊形的按钮底, 可以横向拉伸.
private func pill(_ color: UIColor, height: CGFloat) -> UIImage {
  let size = CGSize(width: height + 2, height: height)
  let image = UIGraphicsImageRenderer(size: size).image { _ in
    color.setFill()
    UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: height / 2).fill()
  }
  return image.resizableImage(
    withCapInsets: UIEdgeInsets(top: 0, left: height / 2, bottom: 0, right: height / 2))
}

/// 协议勾选框: 没勾是一个圆圈, 勾上是实心圆里一个对勾.
private func checkImage(_ checked: Bool, _ color: UIColor, _ markColor: UIColor) -> UIImage {
  let side = Layout.checkSize
  let stroke = side / 12
  return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
    if !checked {
      let ring = UIBezierPath(
        ovalIn: CGRect(x: 0, y: 0, width: side, height: side).insetBy(dx: stroke / 2, dy: stroke / 2))
      ring.lineWidth = stroke
      color.setStroke()
      ring.stroke()
      return
    }
    color.setFill()
    UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: side, height: side)).fill()
    let center = side / 2
    let mark = UIBezierPath()
    mark.move(to: CGPoint(x: center - side * 0.22, y: center + side * 0.02))
    mark.addLine(to: CGPoint(x: center - side * 0.06, y: center + side * 0.18))
    mark.addLine(to: CGPoint(x: center + side * 0.24, y: center - side * 0.14))
    mark.lineWidth = stroke * 1.4
    mark.lineCapStyle = .round
    mark.lineJoinStyle = .round
    markColor.setStroke()
    mark.stroke()
  }
}

/// 关闭按钮的叉.
private func closeImage(_ color: UIColor) -> UIImage {
  let side = Layout.closeIcon
  return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
    let inset = side * 0.14
    let cross = UIBezierPath()
    cross.move(to: CGPoint(x: inset, y: inset))
    cross.addLine(to: CGPoint(x: side - inset, y: side - inset))
    cross.move(to: CGPoint(x: inset, y: side - inset))
    cross.addLine(to: CGPoint(x: side - inset, y: inset))
    cross.lineWidth = side / 12
    cross.lineCapStyle = .round
    color.setStroke()
    cross.stroke()
  }
}

extension UIColor {
  fileprivate convenience init(argb: Int64) {
    let v = UInt32(truncatingIfNeeded: argb)
    self.init(
      red: CGFloat((v >> 16) & 0xFF) / 255,
      green: CGFloat((v >> 8) & 0xFF) / 255,
      blue: CGFloat(v & 0xFF) / 255,
      alpha: CGFloat((v >> 24) & 0xFF) / 255)
  }
}
