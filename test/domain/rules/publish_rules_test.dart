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

  test('价格选填：空着合法，填了要合规，编辑时不能清空原价', () {
    expect(PublishRules.priceError(''), isNull);
    expect(PublishRules.priceError('18'), isNull);
    expect(PublishRules.priceError('12.55'), '请输入 0 到 999 的价格，最多一位小数');
    expect(PublishRules.priceError(' ', keep: true), '价格不能清空');
    expect(PublishRules.priceError('20', keep: true), isNull);
  });

  test('按缺的必填项写提示，价格不在其中', () {
    String? missing({
      bool photo = true,
      bool name = true,
      bool category = true,
    }) =>
        PublishRules.missingText(photo: photo, name: name, category: category);
    expect(missing(), isNull);
    expect(missing(photo: false), '请添加照片');
    expect(missing(category: false), '请填写分类');
    expect(missing(name: false, category: false), '请填写菜名和分类');
    expect(missing(photo: false, name: false), '请添加照片并填写菜名');
  });

  test('菜名查重忽略空白和大小写', () {
    expect(PublishRules.dishNameKey(' Coco 奶茶 '), 'coco奶茶');
    expect(PublishRules.dishNameKey('\t'), isEmpty);
  });
}
