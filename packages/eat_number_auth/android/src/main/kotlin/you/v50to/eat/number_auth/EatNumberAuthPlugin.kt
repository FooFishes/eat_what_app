package you.v50to.eat.number_auth

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.mobile.auth.gatewayauth.PhoneNumberAuthHelper
import com.mobile.auth.gatewayauth.PreLoginResultListener
import com.mobile.auth.gatewayauth.ResultCode
import com.mobile.auth.gatewayauth.TokenResultListener
import com.mobile.auth.gatewayauth.model.TokenRet
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import kotlin.coroutines.resume
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull

/**
 * 运营商一键登录的原生桥, 包着阿里云号码认证 SDK.
 *
 * SDK 只在 Dart 调用 [prepare] 之后才创建. App 只有在用户同意隐私政策之后才会调用它.
 * SDK 的任何异常都转成失败的返回值, 由 App 改用验证码登录, 不向 Dart 抛出.
 */
class EatNumberAuthPlugin : FlutterPlugin, ActivityAware, NumberAuthHostApi {
    private lateinit var context: Context
    private lateinit var messenger: BinaryMessenger
    private val main = Handler(Looper.getMainLooper())
    private var activity: Activity? = null
    private var helper: PhoneNumberAuthHelper? = null
    private var secret: String? = null

    /** 正在等授权页结果的调用, 同一时刻最多一个. */
    private var pending: CancellableContinuation<LoginTokenMessage>? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        messenger = binding.binaryMessenger
        NumberAuthHostApi.setUp(messenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NumberAuthHostApi.setUp(messenger, null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override suspend fun prepare(secret: String, timeoutMs: Long): String? {
        // SDK 的原生库没有 x86_64 版本, 在这种设备 (主要是模拟器) 上加载会失败, 不去碰它.
        if (Build.SUPPORTED_ABIS.firstOrNull() !in SDK_ABIS) return CODE_UNSUPPORTED
        return try {
            val helper = helperFor(secret)
            // SDK 自己按 timeoutMs 超时, 这里多等一会儿只是防止它不回调.
            val code = withTimeoutOrNull(timeoutMs * 2 + 1000) {
                checkEnvironment(helper) ?: preload(helper, timeoutMs.toInt()) ?: CODE_OK
            }
            (code ?: CODE_TIMEOUT).takeUnless { it == CODE_OK }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            Log.w(TAG, "prepare failed", e)
            CODE_ERROR
        }
    }

    override suspend fun requestLoginToken(
        style: AuthPageStyleMessage,
        timeoutMs: Long,
    ): LoginTokenMessage {
        val helper = helper
        val activity = activity
        if (helper == null || activity == null || pending != null) return failed(CODE_NOT_READY)
        return try {
            suspendCancellableCoroutine { continuation ->
                pending = continuation
                helper.setAuthListener(object : TokenResultListener {
                    override fun onTokenSuccess(result: String?) {
                        main.post { onAuthSuccess(result) }
                    }

                    override fun onTokenFailed(result: String?) {
                        main.post { onAuthFailure(result) }
                    }
                })
                applyAuthPageStyle(context, helper, style) {
                    main.post {
                        close()
                        finish(LoginTokenMessage(LoginTokenStatus.CANCELLED))
                    }
                }
                helper.getLoginToken(activity, timeoutMs.toInt())
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            Log.w(TAG, "requestLoginToken failed", e)
            pending = null
            close()
            failed(CODE_ERROR)
        }
    }

    override fun closeAuthPage() {
        close()
        finish(LoginTokenMessage(LoginTokenStatus.CANCELLED))
    }

    private fun helperFor(secret: String): PhoneNumberAuthHelper {
        val current = helper
            ?: PhoneNumberAuthHelper.getInstance(context, IgnoredResults).also { helper = it }
        if (this.secret != secret) {
            current.setAuthSDKInfo(secret)
            this.secret = secret
        }
        return current
    }

    /** 检查当前环境能否一键登录: 有没有 SIM 卡, 蜂窝网络开没开, 方案密钥对不对. 返回 null 表示可以. */
    private suspend fun checkEnvironment(helper: PhoneNumberAuthHelper): String? =
        suspendCancellableCoroutine { continuation ->
            fun finish(code: String?) {
                main.post { if (continuation.isActive) continuation.resume(code) }
            }
            helper.setAuthListener(object : TokenResultListener {
                override fun onTokenSuccess(result: String?) {
                    val code = codeOf(result)
                    finish(code.takeUnless { it == ResultCode.CODE_ERROR_ENV_CHECK_SUCCESS })
                }

                override fun onTokenFailed(result: String?) {
                    finish(codeOf(result))
                }
            })
            helper.checkEnvAvailable(PhoneNumberAuthHelper.SERVICE_TYPE_LOGIN)
        }

    /** 预取号: 提前向运营商要脱敏号码, 授权页才能立刻弹出. 返回 null 表示成功. */
    private suspend fun preload(helper: PhoneNumberAuthHelper, timeoutMs: Int): String? =
        suspendCancellableCoroutine { continuation ->
            fun finish(code: String?) {
                main.post { if (continuation.isActive) continuation.resume(code) }
            }
            helper.accelerateLoginPage(timeoutMs, object : PreLoginResultListener {
                override fun onTokenSuccess(vendor: String?) {
                    finish(null)
                }

                override fun onTokenFailed(vendor: String?, result: String?) {
                    finish(codeOf(result))
                }
            })
        }

    private fun onAuthSuccess(result: String?) {
        val ret = parse(result)
        when (ret?.code) {
            // 授权页已拉起, 接着等用户操作.
            ResultCode.CODE_START_AUTHPAGE_SUCCESS -> return
            ResultCode.CODE_SUCCESS -> {
                val token = ret.token
                if (token.isNullOrEmpty()) {
                    close()
                    finish(failed(CODE_ERROR))
                } else {
                    // 授权页留着并继续显示加载, 等 App 向服务端登录完再关.
                    finish(LoginTokenMessage(LoginTokenStatus.GRANTED, token = token))
                }
            }
        }
    }

    private fun onAuthFailure(result: String?) {
        val code = codeOf(result)
        close()
        finish(
            when (code) {
                ResultCode.CODE_ERROR_USER_CANCEL -> LoginTokenMessage(LoginTokenStatus.CANCELLED)
                ResultCode.CODE_ERROR_USER_SWITCH -> LoginTokenMessage(LoginTokenStatus.SWITCHED)
                else -> failed(code)
            },
        )
    }

    private fun finish(message: LoginTokenMessage) {
        val continuation = pending ?: return
        pending = null
        if (continuation.isActive) continuation.resume(message)
    }

    private fun close() {
        val helper = helper ?: return
        runCatching {
            helper.hideLoginLoading()
            helper.quitLoginPage()
        }.onFailure { Log.w(TAG, "close failed", it) }
    }

    private fun failed(code: String) = LoginTokenMessage(LoginTokenStatus.FAILED, code = code)

    private fun parse(result: String?): TokenRet? =
        runCatching { TokenRet.fromJson(result) }.getOrNull()

    private fun codeOf(result: String?): String =
        parse(result)?.code?.takeIf { it.isNotEmpty() } ?: CODE_ERROR

    /** 创建 SDK 实例时必须给一个监听, 实际的监听在每次调用前另设. */
    private object IgnoredResults : TokenResultListener {
        override fun onTokenSuccess(result: String?) {}

        override fun onTokenFailed(result: String?) {}
    }

    private companion object {
        const val TAG = "EatNumberAuth"

        /** SDK 的 aar 里带了原生库的 ABI. */
        val SDK_ABIS = setOf("arm64-v8a", "armeabi-v7a", "x86")

        /** 插件自己的返回码, 和 SDK 的六位数字码区分开. */
        const val CODE_OK = "ok"
        const val CODE_UNSUPPORTED = "unsupported"
        const val CODE_TIMEOUT = "timeout"
        const val CODE_NOT_READY = "not-ready"
        const val CODE_ERROR = "error"
    }
}
