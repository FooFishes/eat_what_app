package you.v50to.eat.baidu_map

import com.baidu.mapapi.model.LatLng
import com.baidu.mapapi.search.core.SearchResult
import com.baidu.mapapi.search.poi.OnGetPoiSearchResultListener
import com.baidu.mapapi.search.poi.PoiDetailResult
import com.baidu.mapapi.search.poi.PoiDetailSearchResult
import com.baidu.mapapi.search.poi.PoiIndoorResult
import com.baidu.mapapi.search.poi.PoiNearbySearchOption
import com.baidu.mapapi.search.poi.PoiResult
import com.baidu.mapapi.search.poi.PoiSearch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * 百度地点的周边检索. 每次检索用一个新的 [PoiSearch], 结果回来后销毁. 公交站和地铁站不返回.
 *
 * 结果的坐标类型跟随 `SDKInitializer.setCoordType`, 和地图一样是 GCJ-02.
 */
class PlaceSearch : PlaceSearchHostApi {
    override suspend fun searchNearby(
        keyword: String,
        center: LatLngMessage,
        radius: Long,
        pageSize: Long,
    ): List<PlaceMessage> = suspendCancellableCoroutine { continuation ->
        val search = PoiSearch.newInstance()
        continuation.invokeOnCancellation { search.destroy() }
        search.setOnGetPoiSearchResultListener(object : OnGetPoiSearchResultListener {
            override fun onGetPoiResult(result: PoiResult?) {
                search.destroy()
                if (!continuation.isActive) return
                when (result?.error) {
                    SearchResult.ERRORNO.NO_ERROR -> continuation.resume(places(result))
                    SearchResult.ERRORNO.RESULT_NOT_FOUND -> continuation.resume(emptyList())
                    else -> continuation.resumeWithException(
                        FlutterError("search-failed", result?.error?.name, null),
                    )
                }
            }

            override fun onGetPoiDetailResult(result: PoiDetailResult?) {}

            override fun onGetPoiDetailResult(result: PoiDetailSearchResult?) {}

            override fun onGetPoiIndoorResult(result: PoiIndoorResult?) {}
        })
        val option = PoiNearbySearchOption()
            .keyword(keyword)
            .location(LatLng(center.lat, center.lng))
            .radius(radius.toInt())
            .radiusLimit(true)
            .pageNum(0)
            .pageCapacity(pageSize.toInt())
            // 2 是详细信息, 带分类.
            .scope(2)
        if (!search.searchNearby(option)) {
            search.destroy()
            continuation.resumeWithException(FlutterError("search-failed", "searchNearby 未发出", null))
        }
    }

    private fun places(result: PoiResult): List<PlaceMessage> =
        result.allPoi.orEmpty().mapNotNull { poi ->
            val location = poi.location ?: return@mapNotNull null
            val uid = poi.uid?.takeIf { it.isNotEmpty() } ?: return@mapNotNull null
            // 公交站和地铁站不会是店. 周边检索的 type 总是空的, 要看详细信息里的分类, 如 "交通设施;地铁站".
            if (poi.poiDetailInfo?.tag?.startsWith("交通设施") == true) return@mapNotNull null
            PlaceMessage(
                uid = uid,
                name = poi.name.orEmpty(),
                address = poi.address.orEmpty(),
                location = LatLngMessage(location.latitude, location.longitude),
            )
        }
}
