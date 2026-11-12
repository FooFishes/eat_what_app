import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/geo.dart';
import 'package:eat/domain/models/place.dart';
import 'package:eat/domain/rules/shop_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Shop shop({
    ShopKind kind = ShopKind.food,
    List<ShopCategory> categories = const [],
    ShopStat dineIn = const ShopStat(),
    ShopStat delivery = const ShopStat(),
  }) => Shop(
    id: 1,
    name: '袁记云饺',
    point: const GcjPoint(36.6681, 117.1412),
    kind: kind,
    categories: categories,
    dineIn: dineIn,
    delivery: delivery,
  );

  test('舞台色按第一个品类映射；甜点饮品店用青花蓝；没有品类用汤色', () {
    expect(
      ShopRules.stageOf(
        shop(categories: [ShopCategory.hotPot, ShopCategory.rice]),
      ),
      StageColor.redoil,
    );
    expect(
      ShopRules.stageOf(shop(categories: [ShopCategory.rice])),
      StageColor.soy,
    );
    expect(
      ShopRules.stageOf(
        shop(kind: ShopKind.drink, categories: [ShopCategory.grill]),
      ),
      StageColor.porcelain,
    );
    expect(ShopRules.stageOf(shop()), StageColor.broth);
  });

  test('推荐率以堂食为主，满 3 条才显示，按整数百分比四舍五入', () {
    final rate = ShopRules.rateOf(
      shop(
        dineIn: const ShopStat(rate: 0.856, count: 32),
        delivery: const ShopStat(rate: 0.5, count: 10),
      ),
    );
    expect(rate, (scene: RatingScene.dineIn, percent: 86, count: 32));
    expect(ShopRules.rateText(rate!), '86% 推荐');
  });

  test('堂食不满 3 条、外卖满 3 条时显示外卖的推荐率', () {
    final rate = ShopRules.rateOf(
      shop(
        dineIn: const ShopStat(rate: 1, count: 2),
        delivery: const ShopStat(rate: 0.8, count: 3),
      ),
    );
    expect(rate, (scene: RatingScene.delivery, percent: 80, count: 3));
    expect(ShopRules.rateText(rate!), '外卖 80% 推荐');
  });

  test('两个场景都不满 3 条时不显示推荐率', () {
    expect(
      ShopRules.rateOf(
        shop(
          dineIn: const ShopStat(rate: 1, count: 2),
          delivery: const ShopStat(rate: 0, count: 2),
        ),
      ),
      isNull,
    );
    expect(ShopRules.rateOf(shop()), isNull);
  });

  test('新建店：100 m 内店名相同才挡住，更远或只差中间的空白只提示', () {
    const here = GcjPoint(36.6681, 117.1412);
    // 纬度每 0.0001 度约 11 m.
    const near = GcjPoint(36.6688, 117.1412);
    const far = GcjPoint(36.6694, 117.1412);
    final existing = shop();
    final at = Shop(
      id: 2,
      name: existing.name,
      point: near,
      kind: ShopKind.food,
    );
    expect(ShopRules.blocksNewShop(at, name: ' 袁记云饺 ', point: here), isTrue);
    expect(ShopRules.blocksNewShop(at, name: '袁记 云饺', point: here), isFalse);
    expect(
      ShopRules.blocksNewShop(
        Shop(id: 3, name: '袁记云饺', point: far, kind: ShopKind.food),
        name: '袁记云饺',
        point: here,
      ),
      isFalse,
    );
  });
}
