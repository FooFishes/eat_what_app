package you.v50to.eat.baidu_map

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.util.Log
import com.baidu.mapapi.CoordType
import com.baidu.mapapi.RequestAuthResultListener
import com.baidu.mapapi.SDKInitializer
import com.baidu.mapapi.common.BaiduMapSDKException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * 百度地图原生桥的入口: 注册 SDK 接口、地点检索和地图平台视图.
 *
 * SDK 只在 Dart 调用 [initialize] 之后才启动. 百度要求先 `setAgreePrivacy(true)` 再 `initialize`,
 * 而 App 只有在用户同意隐私政策之后才会打开地图.
 */
class EatBaiduMapPlugin : FlutterPlugin, ActivityAware, SdkHostApi {
    private lateinit var context: Context
    private lateinit var messenger: BinaryMessenger
    private lateinit var sdkEvents: SdkFlutterApi
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val views = ViewLifecycle()
    private var activity: Activity? = null
    private var authListener: RequestAuthResultListener? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        messenger = binding.binaryMessenger
        sdkEvents = SdkFlutterApi(messenger)
        SdkHostApi.setUp(messenger, this)
        PlaceSearchHostApi.setUp(messenger, PlaceSearch())
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            BaiduMapViewFactory(messenger, scope, views),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SdkHostApi.setUp(messenger, null)
        PlaceSearchHostApi.setUp(messenger, null)
        authListener?.let { SDKInitializer.removeAuthResultListener(it) }
        scope.cancel()
    }

    override fun initialize(apiKey: String) {
        if (SDKInitializer.isInitialized()) return
        val listener = RequestAuthResultListener { code, message ->
            scope.launch {
                runCatching { sdkEvents.onAuthResult(code.toLong(), message ?: "") }
                    .onFailure { Log.w(TAG, "onAuthResult not delivered", it) }
            }
        }
        authListener = listener
        try {
            SDKInitializer.setAgreePrivacy(context, true)
            SDKInitializer.setApiKey(apiKey)
            SDKInitializer.setCoordType(CoordType.GCJ02)
            SDKInitializer.addAuthResultListener(listener)
            SDKInitializer.initialize(context)
        } catch (e: BaiduMapSDKException) {
            throw FlutterError("init-failed", e.message, null)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding.activity)

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        attach(binding.activity)

    override fun onDetachedFromActivityForConfigChanges() = detach()

    override fun onDetachedFromActivity() = detach()

    private fun attach(activity: Activity) {
        this.activity = activity
        activity.application.registerActivityLifecycleCallbacks(views)
        views.activity = activity
    }

    private fun detach() {
        activity?.application?.unregisterActivityLifecycleCallbacks(views)
        views.activity = null
        activity = null
    }

    companion object {
        const val VIEW_TYPE = "you.v50to.eat/baidu_map"
        const val TAG = "EatBaiduMap"
    }
}

/**
 * 把宿主 Activity 的前后台切换转给所有地图. `MapView` 要随 Activity 调 `onResume` 和 `onPause`.
 */
class ViewLifecycle : Application.ActivityLifecycleCallbacks {
    var activity: Activity? = null
    private val views = mutableSetOf<BaiduMapPlatformView>()

    fun add(view: BaiduMapPlatformView) = views.add(view)

    fun remove(view: BaiduMapPlatformView) = views.remove(view)

    override fun onActivityResumed(activity: Activity) {
        if (activity == this.activity) views.forEach { it.onResume() }
    }

    override fun onActivityPaused(activity: Activity) {
        if (activity == this.activity) views.forEach { it.onPause() }
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityStarted(activity: Activity) {}

    override fun onActivityStopped(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {}
}
