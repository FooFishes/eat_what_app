import 'package:eat/core/platform/map_tiles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App 上的瓦片请求带浏览器式的 User-Agent，天地图才不拒绝', () {
    final headers = mapTileHeaders();

    expect(headers['User-Agent'], startsWith('Mozilla/5.0'));
    expect(headers['User-Agent'], contains('you.v50to.eat'));
  });

  test('每次返回新的可修改 Map，flutter_map 往里补默认头不会抛错', () {
    final headers = mapTileHeaders()..putIfAbsent('Accept', () => '*/*');

    expect(headers, isNot(same(mapTileHeaders())));
    expect(headers['Accept'], '*/*');
  });
}
