import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'external_maps.g.dart';

/// 「导航去店里」能用的一个地图 App。
class const MapApp(final String name, final Uri uri);

/// 打开手机上的地图 App 走路去店里（技术架构 14.5）。坐标都是 GCJ-02。
///
/// 装了几个列几个；一个都没有、或者在 Web 上，就用高德网页版。检测是否安装要在 iOS 的
/// `Info.plist`（`LSApplicationQueriesSchemes`）和安卓的 `<queries>` 里声明这些 scheme。
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
      // Apple 地图是系统自带的，总是列出。
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
