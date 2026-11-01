import 'package:eat/domain/rules/publish_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('价格 0–999，最多一位小数', () {
    expect(PublishRules.parsePrice('18'), 18);
    expect(PublishRules.parsePrice('12.5'), 12.5);
    expect(PublishRules.parsePrice('12.55'), isNull);
    expect(PublishRules.parsePrice('1000'), isNull);
    expect(PublishRules.parsePrice(''), isNull);
  });

  test('按缺的必填项写提示', () {
    String? missing({bool photo = true, bool price = true}) =>
        PublishRules.missingText(
          photo: photo,
          name: true,
          price: price,
          category: true,
          meal: true,
        );
    expect(missing(), isNull);
    expect(missing(photo: false), '请添加照片');
    expect(missing(price: false), '请填写价格');
    expect(missing(photo: false, price: false), '请添加照片并填写价格');
  });
}
