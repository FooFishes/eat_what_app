package you.v50to.eat.number_auth

import android.app.Activity
import android.content.Context
import android.content.pm.ActivityInfo
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.widget.ImageView
import android.widget.RelativeLayout
import com.mobile.auth.gatewayauth.AuthRegisterViewConfig
import com.mobile.auth.gatewayauth.AuthUIConfig
import com.mobile.auth.gatewayauth.PhoneNumberAuthHelper
import kotlin.math.ceil
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * 把授权页配成从底部升起的面板: 号码, 运营商标语, 登录按钮, 切换按钮, 运营商协议, 右上角一个关闭按钮.
 *
 * SDK 的尺寸参数都是 dp. 图片一律现画, 不放资源文件, 颜色才能跟着 App 的令牌走.
 * [activity] 是拉起授权页的页面, 用来量底部导航栏的高度. [onClose] 在用户点关闭按钮时调用.
 */
internal fun applyAuthPageStyle(
    activity: Activity,
    helper: PhoneNumberAuthHelper,
    style: AuthPageStyleMessage,
    onClose: () -> Unit,
) {
    val context: Context = activity
    val metrics = context.resources.displayMetrics
    val bottomInset = navigationBarInset(activity)
    val screenWidth = (metrics.widthPixels / metrics.density).toInt()
    val margin = style.margin.roundToInt()
    val radius = style.cornerRadius.roundToInt()
    val background = style.background.toInt()
    val primary = style.primary.toInt()
    val onPrimary = style.onPrimary.toInt()
    val secondary = style.secondary.toInt()
    val muted = style.muted.toInt()
    val scrim = Color.alpha(style.scrim.toInt()) / 255f
    val checkSize = (CHECK_SIZE * metrics.density).roundToInt()
    val alertWidth = screenWidth - ALERT_MARGIN * 2

    helper.removeAuthRegisterXmlConfig()
    helper.removeAuthRegisterViewConfig()
    helper.removePrivacyAuthRegisterViewConfig()
    helper.removePrivacyRegisterXmlConfig()
    helper.addAuthRegistViewConfig(
        CLOSE_VIEW,
        AuthRegisterViewConfig.Builder()
            .setView(closeButton(context, style))
            .setRootViewId(AuthRegisterViewConfig.RootViewId.ROOT_VIEW_ID_TITLE_BAR)
            .setCustomInterface { onClose() }
            .build(),
    )
    // 勾选框只有 18dp, 把协议文字前面一段也算进点击范围.
    helper.expandAuthPageCheckedScope(true)
    helper.setAuthUIConfig(
        AuthUIConfig.Builder()
            // 窗口: 贴底, 和屏幕等宽, 点面板外面关闭.
            .setDialogBottom(true)
            .setDialogWidth(screenWidth)
            .setDialogHeight(PANEL_HEIGHT + bottomInset)
            .setDialogAlpha(scrim)
            .setTapAuthPageMaskClosePage(true)
            .setPageBackgroundDrawable(panel(background, style.cornerRadius * metrics.density))
            .setAuthPageActIn("eat_number_auth_in", "eat_number_auth_stay")
            .setAuthPageActOut("eat_number_auth_stay", "eat_number_auth_out")
            .setScreenOrientation(ActivityInfo.SCREEN_ORIENTATION_BEHIND)
            .setLightColor(true)
            .setStatusBarColor(Color.TRANSPARENT)
            // 标题栏隐藏后 SDK 仍然留着它的 50dp, 面板顶上会空一截. 所以留着它, 做成透明的, 只放关闭按钮.
            .setNavHidden(false)
            .setNavColor(Color.TRANSPARENT)
            .setNavText("")
            .setNavReturnHidden(true)
            .setLogoHidden(true)
            // 号码和运营商标语, 内容由 SDK 填.
            .setNumberColor(primary)
            .setNumberSizeDp(28)
            .setNumberTypeface(Typeface.DEFAULT_BOLD)
            .setNumFieldOffsetY(NUMBER_TOP)
            .setSloganTextColor(muted)
            .setSloganTextSizeDp(12)
            .setSloganOffsetY(SLOGAN_TOP)
            // 登录按钮. 没勾协议时弹二次确认, 不用 SDK 自带的轻提示.
            .setLogBtnText(style.loginText)
            .setLogBtnTextColor(onPrimary)
            .setLogBtnTextSizeDp(16)
            .setLogBtnTypeface(Typeface.DEFAULT_BOLD)
            .setLogBtnHeight(style.buttonHeight.roundToInt())
            .setLogBtnMarginLeftAndRight(margin)
            .setLogBtnOffsetY(BUTTON_TOP)
            .setLogBtnBackgroundDrawable(pill(primary))
            .setLogBtnToastHidden(true)
            .setSwitchAccText(style.switchText)
            .setSwitchAccTextColor(secondary)
            .setSwitchAccTextSizeDp(14)
            .setSwitchOffsetY(SWITCH_TOP)
            // 运营商协议, 默认不勾.
            .setPrivacyState(false)
            .setUncheckedImgDrawable(CheckDrawable(false, muted, onPrimary, checkSize))
            .setCheckedImgDrawable(CheckDrawable(true, primary, onPrimary, checkSize))
            .setCheckBoxWidth(CHECK_SIZE)
            .setCheckBoxHeight(CHECK_SIZE)
            .setAppPrivacyColor(muted, secondary)
            .setPrivacyTextSizeDp(13)
            .setPrivacyBefore(style.privacyPrefix)
            .setPrivacyEnd("")
            .setVendorPrivacyPrefix("《")
            .setVendorPrivacySuffix("》")
            .setPrivacyMargin(margin)
            .setPrivacyOffsetY_B(PRIVACY_BOTTOM + bottomInset)
            // 没勾协议就点登录时的二次确认弹窗, 同意后直接登录.
            .setPrivacyAlertIsNeedShow(true)
            .setPrivacyAlertIsNeedAutoLogin(true)
            .setPrivacyAlertMaskIsNeedShow(true)
            .setPrivacyAlertMaskAlpha(scrim)
            .setTapPrivacyAlertMaskCloseAlert(true)
            .setPrivacyAlertCloseBtnShow(false)
            .setPrivacyAlertAlignment(Gravity.CENTER)
            .setPrivacyAlertWidth(alertWidth)
            .setPrivacyAlertHeight(ALERT_HEIGHT)
            .setPrivacyAlertCornerRadiusArray(intArrayOf(radius, radius, radius, radius))
            .setPrivacyAlertBackgroundColor(background)
            .setPrivacyAlertTitleContent(style.alertTitle)
            .setPrivacyAlertTitleColor(primary)
            .setPrivacyAlertTitleTextSize(17)
            .setPrivacyAlertTitleTypeface(Typeface.DEFAULT_BOLD)
            .setPrivacyAlertTitleOffsetY(ALERT_TITLE_TOP)
            .setPrivacyAlertBefore(style.alertPrefix)
            .setPrivacyAlertEnd("")
            .setPrivacyAlertContentBaseColor(muted)
            .setPrivacyAlertContentColor(secondary)
            .setPrivacyAlertContentTextSize(14)
            .setPrivacyAlertContentAlignment(Gravity.CENTER)
            .setPrivacyAlertContentHorizontalMargin(margin)
            .setPrivacyAlertBtnContent(style.alertButtonText)
            .setPrivacyAlertBtnTextColor(onPrimary)
            .setPrivacyAlertBtnTextSize(15)
            .setPrivacyAlertBtnTypeface(Typeface.DEFAULT_BOLD)
            .setPrivacyAlertBtnBackgroundImgDrawable(pill(primary))
            // 不给宽度时按钮只有文字那么宽.
            .setPrivacyAlertBtnWidth(alertWidth - margin * 2)
            .setPrivacyAlertBtnHeigth(ALERT_BUTTON_HEIGHT)
            .setPrivacyAlertBtnHorizontalMargin(margin)
            .create(),
    )
}

private const val CLOSE_VIEW = "eat_close"

/**
 * 面板的高度和各个控件的位置, 单位 dp. 面板顶上 50dp 是 SDK 的标题栏, 控件的位置从标题栏下沿算起,
 * 协议栏从面板底部算起. 面板的高度和协议栏的位置还要加上底部导航栏的高度.
 */
private const val PANEL_HEIGHT = 324
private const val NUMBER_TOP = 10
private const val SLOGAN_TOP = 56
private const val BUTTON_TOP = 96
private const val SWITCH_TOP = 168
private const val PRIVACY_BOTTOM = 28
private const val CHECK_SIZE = 20

/** 二次确认弹窗, 单位 dp. */
private const val ALERT_MARGIN = 32
private const val ALERT_HEIGHT = 196
private const val ALERT_BUTTON_HEIGHT = 48
private const val ALERT_TITLE_TOP = 8

/** 关闭按钮的点击区域和图标大小, 单位 dp. */
private const val CLOSE_TOUCH = 44
private const val CLOSE_ICON = 18

private fun closeButton(context: Context, style: AuthPageStyleMessage): View {
    val density = context.resources.displayMetrics.density
    val touch = (CLOSE_TOUCH * density).roundToInt()
    return ImageView(context).apply {
        layoutParams = RelativeLayout.LayoutParams(touch, touch).apply {
            addRule(RelativeLayout.ALIGN_PARENT_END)
            addRule(RelativeLayout.CENTER_VERTICAL)
            marginEnd = (8 * density).roundToInt()
        }
        scaleType = ImageView.ScaleType.CENTER
        setImageDrawable(
            CloseDrawable(style.muted.toInt(), (CLOSE_ICON * density).roundToInt()),
        )
        contentDescription = style.closeLabel
    }
}

/**
 * 底部导航栏 (手势条或三个按键) 的高度, 单位 dp.
 *
 * 目标版本 35 起, 在 Android 15 及以上窗口强制铺到屏幕边缘, 面板的最下面一段压在导航栏底下,
 * 协议栏要让出这一段. 更早的系统上面板本来就在导航栏上方, 不用让.
 */
private fun navigationBarInset(activity: Activity): Int {
    if (Build.VERSION.SDK_INT < 35 || activity.applicationInfo.targetSdkVersion < 35) return 0
    val insets = activity.window.decorView.rootWindowInsets ?: return 0
    val bottom = insets.getInsets(WindowInsets.Type.navigationBars()).bottom
    return ceil(bottom / activity.resources.displayMetrics.density).toInt()
}

/** 面板的底: 只有顶部两个角是圆角. */
private fun panel(color: Int, radius: Double): Drawable {
    val r = radius.toFloat()
    return GradientDrawable().apply {
        setColor(color)
        cornerRadii = floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f)
    }
}

/** 胶囊形的按钮底. 圆角给一个足够大的值, 系统会收到高度的一半. */
private fun pill(color: Int): Drawable =
    GradientDrawable().apply {
        setColor(color)
        cornerRadius = 10000f
    }

/** 协议勾选框: 没勾是一个圆圈, 勾上是实心圆里一个对勾. */
private class CheckDrawable(
    private val checked: Boolean,
    private val color: Int,
    private val markColor: Int,
    private val size: Int,
) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val mark = Path()

    override fun draw(canvas: Canvas) {
        val side = min(bounds.width(), bounds.height()).toFloat()
        val cx = bounds.exactCenterX()
        val cy = bounds.exactCenterY()
        val stroke = side / 12
        if (!checked) {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = stroke
            paint.color = color
            canvas.drawCircle(cx, cy, (side - stroke) / 2, paint)
            return
        }
        paint.style = Paint.Style.FILL
        paint.color = color
        canvas.drawCircle(cx, cy, side / 2, paint)
        mark.rewind()
        mark.moveTo(cx - side * 0.22f, cy + side * 0.02f)
        mark.lineTo(cx - side * 0.06f, cy + side * 0.18f)
        mark.lineTo(cx + side * 0.24f, cy - side * 0.14f)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = stroke * 1.4f
        paint.color = markColor
        canvas.drawPath(mark, paint)
    }

    override fun getIntrinsicWidth() = size

    override fun getIntrinsicHeight() = size

    override fun setAlpha(alpha: Int) {
        paint.alpha = alpha
    }

    override fun setColorFilter(colorFilter: ColorFilter?) {
        paint.colorFilter = colorFilter
    }

    @Deprecated("Deprecated in Java")
    override fun getOpacity() = PixelFormat.TRANSLUCENT
}

/** 关闭按钮的叉. */
private class CloseDrawable(color: Int, private val size: Int) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        this.color = color
    }

    override fun draw(canvas: Canvas) {
        val half = min(bounds.width(), bounds.height()) * 0.36f
        val cx = bounds.exactCenterX()
        val cy = bounds.exactCenterY()
        paint.strokeWidth = half / 4.5f
        canvas.drawLine(cx - half, cy - half, cx + half, cy + half, paint)
        canvas.drawLine(cx - half, cy + half, cx + half, cy - half, paint)
    }

    override fun getIntrinsicWidth() = size

    override fun getIntrinsicHeight() = size

    override fun setAlpha(alpha: Int) {
        paint.alpha = alpha
    }

    override fun setColorFilter(colorFilter: ColorFilter?) {
        paint.colorFilter = colorFilter
    }

    @Deprecated("Deprecated in Java")
    override fun getOpacity() = PixelFormat.TRANSLUCENT
}
