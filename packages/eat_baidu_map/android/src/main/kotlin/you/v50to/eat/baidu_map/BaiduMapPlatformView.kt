package you.v50to.eat.baidu_map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import android.util.Log
import android.view.View
import com.baidu.mapapi.map.BaiduMap
import com.baidu.mapapi.map.BaiduMapOptions
import com.baidu.mapapi.map.BitmapDescriptorFactory
import com.baidu.mapapi.map.MapStatus
import com.baidu.mapapi.map.MapStatusUpdate
import com.baidu.mapapi.map.MapStatusUpdateFactory
import com.baidu.mapapi.map.Marker
import com.baidu.mapapi.map.MarkerOptions
import com.baidu.mapapi.map.Overlay
import com.baidu.mapapi.map.PolygonOptions
import com.baidu.mapapi.map.PolylineDottedLineType
import com.baidu.mapapi.map.Stroke
import com.baidu.mapapi.map.TextureMapView
import com.baidu.mapapi.model.LatLng
import com.baidu.mapapi.model.LatLngBounds
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.IdentityHashMap
import kotlin.math.roundToInt
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class BaiduMapViewFactory(
    private val messenger: BinaryMessenger,
    private val scope: CoroutineScope,
    private val lifecycle: ViewLifecycle,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?> ?: emptyMap()
        return BaiduMapPlatformView(context, viewId, params, messenger, scope, lifecycle)
    }
}

/**
 * 一张百度地图. 用 `TextureMapView`: 基于 TextureView, Flutter 能用纹理合成叠加组件和裁切;
 * 普通 `MapView` 基于 SurfaceView, 会迫使 Flutter 退回更慢的合成方式.
 *
 * 浮层盖住的区域 ([setInsets]) 之外剩下的部分叫可见区域.
 * 相机的中心总是可见区域的中心: 移动时把 `targetScreen` 设成它, 读取时按屏幕点反算坐标.
 */
class BaiduMapPlatformView(
    context: Context,
    viewId: Int,
    params: Map<String, Any?>,
    private val messenger: BinaryMessenger,
    private val scope: CoroutineScope,
    private val lifecycle: ViewLifecycle,
) : PlatformView, MapViewHostApi {
    private val suffix = viewId.toString()
    private val events = MapViewFlutterApi(messenger, suffix)
    private val density = context.resources.displayMetrics.density
    private val mapView: TextureMapView
    private val map: BaiduMap
    private val markers = HashMap<String, Marker>()
    private val markerIds = IdentityHashMap<Marker, String>()
    private val polygons = mutableListOf<Overlay>()

    /** 被浮层盖住的宽度, 单位为物理像素. */
    private var insetLeft = 0
    private var insetTop = 0
    private var insetRight = 0
    private var insetBottom = 0

    /** 这次移动是否由手势触发. 移动开始时记下, 停下时报给 Dart. */
    private var movingByGesture = false
    private var loaded = false

    init {
        val center = LatLng(params.double("lat"), params.double("lng"))
        val options = BaiduMapOptions()
            .mapStatus(MapStatus.Builder().target(center).zoom(params.double("zoom").toFloat()).build())
            .rotateGesturesEnabled(false)
            .overlookingGesturesEnabled(false)
            .compassEnabled(false)
            .zoomControlsEnabled(false)
            .scaleControlEnabled(true)
        mapView = TextureMapView(context, options)
        map = mapView.map
        map.setMaxAndMinZoomLevel(params.double("maxZoom").toFloat(), params.double("minZoom").toFloat())
        map.uiSettings.apply {
            isRotateGesturesEnabled = false
            isOverlookingGesturesEnabled = false
            isCompassEnabled = false
        }
        listen()
        mapView.addOnLayoutChangeListener { _, l, t, r, b, ol, ot, or, ob ->
            if (r - l != or - ol || b - t != ob - ot) applyTargetScreen()
        }
        MapViewHostApi.setUp(messenger, this, suffix)
        lifecycle.add(this)
    }

    override fun getView(): View = mapView

    override fun dispose() {
        MapViewHostApi.setUp(messenger, null, suffix)
        lifecycle.remove(this)
        markers.clear()
        markerIds.clear()
        polygons.clear()
        mapView.onDestroy()
    }

    fun onResume() = mapView.onResume()

    fun onPause() = mapView.onPause()

    private fun listen() {
        map.setOnMapLoadedCallback {
            loaded = true
            send { events.onLoaded() }
        }
        map.setOnMapRenderValidDataListener { valid, code, message ->
            if (!valid) send { events.onError(code.toLong(), message ?: "") }
        }
        map.setOnMarkerClickListener { marker ->
            markerIds[marker]?.let { id -> send { events.onMarkerTap(id) } }
            true
        }
        map.setOnMapStatusChangeListener(object : BaiduMap.OnMapStatusChangeListener {
            override fun onMapStatusChangeStart(status: MapStatus) {}

            override fun onMapStatusChangeStart(status: MapStatus, reason: Int) {
                movingByGesture = reason == BaiduMap.OnMapStatusChangeListener.REASON_GESTURE
            }

            override fun onMapStatusChange(status: MapStatus) {}

            override fun onMapStatusChangeFinish(status: MapStatus) {
                val byGesture = movingByGesture
                movingByGesture = false
                val camera = camera(status)
                send { events.onCameraIdle(camera, byGesture) }
            }
        })
    }

    override fun updateMarkers(upserts: List<MarkerMessage>, removedIds: List<String>) {
        for (id in removedIds) {
            markers.remove(id)?.let {
                markerIds.remove(it)
                it.remove()
            }
        }
        for (m in upserts) {
            val icon = BitmapDescriptorFactory.fromBitmap(bitmap(m.icon, m.iconScale))
            val position = m.position.toLatLng()
            val existing = markers[m.id]
            if (existing != null) {
                existing.position = position
                existing.icon = icon
                existing.setAnchor(m.anchorX.toFloat(), m.anchorY.toFloat())
                existing.setZIndex(m.zIndex.toInt())
                continue
            }
            val options = MarkerOptions()
                .position(position)
                .icon(icon)
                .anchor(m.anchorX.toFloat(), m.anchorY.toFloat())
                .zIndex(m.zIndex.toInt())
                .isForceDisPlay(true)
                .poiCollided(true)
            val marker = map.addOverlay(options) as Marker
            markers[m.id] = marker
            markerIds[marker] = m.id
        }
    }

    override fun setPolygons(polygons: List<PolygonMessage>) {
        this.polygons.forEach { it.remove() }
        this.polygons.clear()
        for (p in polygons) {
            if (p.points.size < 3) continue
            val options = PolygonOptions()
                .points(p.points.map { it.toLatLng() })
                .fillColor(p.fillColor.toInt())
                .stroke(Stroke(px(p.strokeWidth).coerceAtLeast(1).toFloat(), p.strokeColor.toInt()))
                .dottedStroke(p.dashed)
                .dottedStrokeType(PolylineDottedLineType.DOTTED_LINE_SQUARE)
                .zIndex(0)
            this.polygons += map.addOverlay(options)
        }
    }

    override fun setInsets(insets: InsetsMessage) {
        insetLeft = px(insets.left)
        insetTop = px(insets.top)
        insetRight = px(insets.right)
        insetBottom = px(insets.bottom)
        map.setPadding(insetLeft, insetTop, insetRight, insetBottom)
        applyTargetScreen()
    }

    override fun moveCamera(center: LatLngMessage, zoom: Double?, animated: Boolean) {
        val builder = MapStatus.Builder(map.mapStatus).target(center.toLatLng())
        visibleCenter()?.let { builder.targetScreen(it) }
        zoom?.let { builder.zoom(it.toFloat()) }
        update(MapStatusUpdateFactory.newMapStatus(builder.build()), animated)
    }

    override fun fitPoints(points: List<LatLngMessage>, margin: InsetsMessage, animated: Boolean) {
        if (points.isEmpty()) return
        val bounds = LatLngBounds.Builder().apply { points.forEach { include(it.toLatLng()) } }.build()
        val update = MapStatusUpdateFactory.newLatLngBounds(
            bounds,
            insetLeft + px(margin.left),
            insetTop + px(margin.top),
            insetRight + px(margin.right),
            insetBottom + px(margin.bottom),
        )
        update(update, animated)
    }

    override fun getCamera(): CameraMessage = camera(map.mapStatus)

    override fun isLoaded(): Boolean = loaded

    private fun update(update: MapStatusUpdate, animated: Boolean) {
        if (animated) map.animateMapStatus(update) else map.setMapStatus(update)
    }

    /** 让地图中心落在可见区域中心, 坐标不变. */
    private fun applyTargetScreen() {
        val point = visibleCenter() ?: return
        map.setMapStatus(
            MapStatusUpdateFactory.newMapStatus(MapStatus.Builder(map.mapStatus).targetScreen(point).build()),
        )
    }

    /** 可见区域中心在地图视图里的位置. 视图还没有尺寸时为 null. */
    private fun visibleCenter(): Point? {
        val w = mapView.width
        val h = mapView.height
        if (w == 0 || h == 0) return null
        return Point(
            insetLeft + (w - insetLeft - insetRight) / 2,
            insetTop + (h - insetTop - insetBottom) / 2,
        )
    }

    private fun camera(status: MapStatus): CameraMessage {
        val center = visibleCenter()?.let { map.projection?.fromScreenLocation(it) } ?: status.target
        return CameraMessage(LatLngMessage(center.latitude, center.longitude), status.zoom.toDouble())
    }

    private fun bitmap(bytes: ByteArray, scale: Double): Bitmap {
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        val ratio = density / scale
        if (ratio in 0.99..1.01) return decoded
        return Bitmap.createScaledBitmap(
            decoded,
            (decoded.width * ratio).roundToInt().coerceAtLeast(1),
            (decoded.height * ratio).roundToInt().coerceAtLeast(1),
            true,
        )
    }

    private fun px(logical: Double): Int = (logical * density).roundToInt()

    private fun send(block: suspend () -> Unit) {
        scope.launch {
            runCatching { block() }.onFailure { Log.w(EatBaiduMapPlugin.TAG, "event not delivered", it) }
        }
    }
}

private fun LatLngMessage.toLatLng() = LatLng(lat, lng)

private fun Map<String, Any?>.double(key: String): Double = (this[key] as Number).toDouble()
