package you.v50to.eat

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** 换过但还没生效的图标名, 离开前台时生效. */
    private var pendingIcon: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_ICON_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "get" -> result.success(pendingIcon ?: enabledIcon())
                    "set" -> {
                        val name = call.arguments as? String
                        if (name == null || name !in LAUNCHERS) {
                            result.error("invalid", "unknown icon $name", null)
                        } else {
                            pendingIcon = if (name == enabledIcon()) null else name
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 从桌面图标启动时, [getComponentName] 是图标对应的 activity-alias, 而 Flutter 从它读 meta-data.
     * 别名上没有这些 meta-data, 改为读本 Activity 的, 免得启动主题和关闭 Flutter 深链的设置失效.
     */
    override fun getMetaData(): Bundle? =
        packageManager.getActivityInfo(
            ComponentName(this, MainActivity::class.java),
            PackageManager.GET_META_DATA,
        ).metaData

    /**
     * 停用正在运行的那个启动入口时, 有些厂商系统会结束 App 或清掉任务, 所以等离开前台再换.
     */
    override fun onStop() {
        super.onStop()
        val icon = pendingIcon ?: return
        pendingIcon = null
        for ((name, alias) in LAUNCHERS.entries.sortedBy { it.key != icon }) {
            packageManager.setComponentEnabledSetting(
                ComponentName(this, alias),
                if (name == icon) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                },
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    /** 当前启用的图标. 没换过时以清单里的默认为准, 即猪猪. */
    private fun enabledIcon(): String {
        val state = packageManager.getComponentEnabledSetting(
            ComponentName(this, LAUNCHERS.getValue(BUN)),
        )
        return if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) BUN else PIG
    }

    private companion object {
        const val APP_ICON_CHANNEL = "you.v50to.eat/app_icon"
        const val PIG = "pig"
        const val BUN = "bun"

        /** 图标名到 AndroidManifest.xml 里 activity-alias 的类名. */
        val LAUNCHERS = mapOf(
            PIG to "you.v50to.eat.PigLauncher",
            BUN to "you.v50to.eat.BunLauncher",
        )
    }
}
