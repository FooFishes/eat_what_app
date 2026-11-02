import 'package:cached_network_image/cached_network_image.dart';
import 'package:eat/design/widgets/images.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const first =
      'https://oss.test/eat/foods/a1b2.jpg?X-Amz-Date=20261102T080000Z&X-Amz-Signature=aaa';
  const second =
      'https://oss.test/eat/foods/a1b2.jpg?X-Amz-Date=20261102T081000Z&X-Amz-Signature=bbb';

  test('缓存 key 去掉签名查询串', () {
    expect(imageCacheKey(first), 'https://oss.test/eat/foods/a1b2.jpg');
    expect(imageCacheKey('https://oss.test/a.png#x'), 'https://oss.test/a.png');
    expect(imageCacheKey('https://oss.test/a.png'), 'https://oss.test/a.png');
  });

  test('同一张图换了签名仍是同一个图片来源，能命中缓存', () {
    final a = networkImage(first)! as CachedNetworkImageProvider;
    final b = networkImage(second)! as CachedNetworkImageProvider;
    expect(a.url, first);
    expect(a.cacheKey, 'https://oss.test/eat/foods/a1b2.jpg');
    expect(a, b);
    expect(networkImage(first, width: 100), networkImage(second, width: 100));
    expect(
      networkImage(first),
      isNot(
        networkImage('https://oss.test/eat/foods/c3d4.jpg?X-Amz-Signature=aaa'),
      ),
    );
  });

  test('没有地址时没有图片来源', () {
    expect(networkImage(null), isNull);
    expect(networkImage(''), isNull);
    expect(networkImage(first, width: 100), isA<ResizeImage>());
  });
}
