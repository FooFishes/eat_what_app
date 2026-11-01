import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'external_maps.g.dart';

/// "导航去店里" 可用的地图 App.
class const MapApp(final String name, final Uri uri);

/// 打开地图 App 规划到店的步行路线. 坐标均为 GCJ-02.
///
/// 列出所有已安装的地图 App. 均未安装或运行在 Web 上时, 使用高德地图网页版.
/// 检测安装状态需要声明这些 scheme: iOS 在 `Info.plist` 的 `LSApplicationQueriesSchemes` 中,
/// Android 在 `AndroidManifest.xml` 的 `<queries>` 中.
abstract interface class ExternalMaps {
  Future<List<MapApp>> available({
    required double lat,
    required double lng,
    required String name,
  });

  Future<bool> open(MapApp app);
}

class UrlLauncherExternalMaps implements ExternalMaps {
  static const _appName = '沙软今天吃什么';
  static const _appId = 'you.v50to.eat';

  @override
  Future<List<MapApp>> available({
    required double lat,
    required double lng,
    required String name,
  }) async {
    final web = MapApp(
      '高德地图网页版',
      Uri.https('uri.amap.com', '/navigation', {
        'to': '$lng,$lat,$name',
        'mode': 'walk',
        'coordinate': 'gaode',
        'callnative': '1',
      }),
    );
    if (kIsWeb) return [web];
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final candidates = [
      if (ios)
        MapApp('Apple 地图', Uri.parse('maps://?daddr=$lat,$lng&dirflg=w')),
      MapApp(
        '高德地图',
        Uri(
          scheme: ios ? 'iosamap' : 'androidamap',
          host: ios ? 'path' : 'route',
          queryParameters: {
            'sourceApplication': _appName,
            'dlat': '$lat',
            'dlon': '$lng',
            'dname': name,
            'dev': '0',
            't': '2',
          },
        ),
      ),
      MapApp(
        '百度地图',
        Uri(
          scheme: 'baidumap',
          host: 'map',
          path: '/direction',
          queryParameters: {
            'destination': 'latlng:$lat,$lng|name:$name',
            'coord_type': 'gcj02',
            'mode': 'walking',
            'src': _appId,
          },
        ),
      ),
      MapApp(
        '腾讯地图',
        Uri(
          scheme: 'qqmap',
          host: 'map',
          path: '/routeplan',
          queryParameters: {
            'type': 'walk',
            'to': name,
            'tocoord': '$lat,$lng',
            'referer': _appId,
          },
        ),
      ),
    ];
    final installed = <MapApp>[];
    for (final app in candidates) {
      // Apple 地图为系统内置, 不检测, 始终列出.
      if (app.uri.scheme == 'maps' || await _canOpen(app.uri)) {
        installed.add(app);
      }
    }
    return installed.isEmpty ? [web] : installed;
  }

  @override
  Future<bool> open(MapApp app) async {
    try {
      return await launchUrl(app.uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  static Future<bool> _canOpen(Uri uri) async {
    try {
      return await canLaunchUrl(uri);
    } on Object {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
ExternalMaps externalMaps(Ref ref) => UrlLauncherExternalMaps();
