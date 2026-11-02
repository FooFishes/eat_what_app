import 'package:flutter/foundation.dart';

/// 请求地图瓦片时附带的请求头.
///
/// 天地图拒绝不以 `Mozilla/5.0` 开头的 User-Agent, flutter_map 和 Dart 的默认值都会得到 403.
/// Web 上的 User-Agent 由浏览器决定, 自定义该头还会触发跨域预检, 因此不设置.
/// 每次返回新的可修改 Map, flutter_map 会往里补充默认头.
Map<String, String> mapTileHeaders() => kIsWeb
    ? {}
    : {'User-Agent': 'Mozilla/5.0 (compatible; EatWhat; you.v50to.eat)'};
