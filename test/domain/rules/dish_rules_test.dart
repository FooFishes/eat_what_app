import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/rules/dish_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Dish _dish(
  int id, {
  StageColor stage = StageColor.broth,
  List<StageColor> alternates = const [],
  int likes = 0,
}) => Dish(
  id: id,
  name: '菜$id',
  shopId: 1,
  stage: stage,
  stageAlternates: alternates,
  likes: likes,
);

void main() {
  group('舞台菜名断行', () {
    test('四个字以内一行', () {
      expect(DishRules.stageLines('铁锅炖'), ['铁锅炖']);
      expect(DishRules.stageLines('红烧排骨'), ['红烧排骨']);
    });

    test('每行不超过四个字，尽量一样长', () {
      expect(DishRules.stageLines('黄焖鸡米饭'), ['黄焖鸡', '米饭']);
      final lines = DishRules.stageLines('秘制酱香鸡腿饭加蛋套餐');
      expect(lines, hasLength(3));
      expect(lines.every((l) => l.length <= 4), isTrue);
    });

    test('常见结尾词不拆开', () {
      expect(DishRules.stageLines('柳州螺蛳粉'), ['柳州', '螺蛳粉']);
      expect(DishRules.stageLines('玉米排骨汤'), ['玉米', '排骨汤']);
      expect(DishRules.stageLines('鲜虾蟹籽云吞'), ['鲜虾蟹', '籽云吞']);
    });
  });

  test('转盘上相邻撞色时后一道换成备选色，不改保存的值', () {
    final dishes = [
      _dish(1, stage: StageColor.soy),
      _dish(2, stage: StageColor.soy, alternates: [StageColor.redoil]),
      _dish(
        3,
        stage: StageColor.redoil,
        alternates: [StageColor.redoil, StageColor.chili],
      ),
      _dish(4, stage: StageColor.broth),
    ];
    expect(DishRules.turntableColors(dishes), [
      StageColor.soy,
      StageColor.redoil,
      StageColor.chili,
      StageColor.broth,
    ]);
    expect(dishes[1].stage, StageColor.soy);
  });

  test('价格：整数不写小数，最多一位小数', () {
    expect(DishRules.priceText(18), '¥18');
    expect(DishRules.priceText(18.5), '¥18.5');
    expect(DishRules.priceText(null), isNull);
  });

  test('获赞最多的三道', () {
    final dishes = [
      _dish(1, likes: 3),
      _dish(2, likes: 40),
      _dish(3, likes: 12),
      _dish(4, likes: 1),
    ];
    expect(DishRules.mostLiked(dishes).map((d) => d.id), [2, 3, 1]);
  });

  test('没保存舞台色时用分类的默认色，没有分类时用 broth', () {
    expect(DishRules.defaultStage(DishCategory.staple), StageColor.broth);
    expect(DishRules.defaultStage(DishCategory.dish), StageColor.soy);
    expect(DishRules.defaultStage(DishCategory.snack), StageColor.chili);
    expect(DishRules.defaultStage(DishCategory.soup), StageColor.bamboo);
    expect(DishRules.defaultStage(DishCategory.drinkDessert), StageColor.mango);
    expect(DishRules.defaultStage(DishCategory.special), StageColor.matcha);
    expect(DishRules.defaultStage(null), StageColor.broth);
  });

  test('分类按中文原值解析，不认识的值为 null', () {
    expect(DishCategory.fromApi('饮品甜品'), DishCategory.drinkDessert);
    expect(DishCategory.fromApi(' 菜 '), DishCategory.dish);
    expect(DishCategory.fromApi('staple'), isNull);
    expect(DishCategory.fromApi(null), isNull);
  });
}
